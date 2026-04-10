part of 'api_service.dart';

// ─── Media Upload ───────────────────────────────────────────────────────────
mixin _MediaMixin {
  SupabaseClient get _client;

  // ── Valid stage enum values in the DB ────────────────────────────────────
  static const _stageEnumMap = {
    'stage_1_site_inspection':  'damage_report',
    'stage_2_excavation':       'excavation',
    'stage_3_pipe_work':        'pipe_exposed',
    'stage_4_repair_work':      'repair_in_progress',
    'stage_5_testing':          'repair_in_progress',
    'stage_6_restoration':      'road_restoration',
    'stage_7_final_inspection': 'inspection',
  };

  // ── Legacy: kept for backward compatibility ───────────────────────────────
  Future<String> uploadMedia(File file, String breakdownId) async {
    try {
      final fileName =
          '${breakdownId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from('breakdown-media').upload(fileName, file);
      return _client.storage.from('breakdown-media').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('UPLOAD ERROR (using demo fallback): $e');
      return 'https://images.unsplash.com/photo-1581092160562-40aa08e78837?auto=format&fit=crop&q=80&w=800';
    }
  }

  // ── UUID validator ────────────────────────────────────────────────────────
  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', // Simpler check for now if needed, but standard is better
    caseSensitive: false,
  );
  // Re-corrected standard UUID regex
  static final _strictUuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  // ── Stage-aware upload → inserts rows into `repair_media` table ───────────
  Future<void> uploadStageMedia({
    required String breakdownId,
    required String stageLabel,
    required List<({Uint8List bytes, String name, String path})> files,
    required void Function(int current, int total) onProgress,
    required void Function(String error) onError,
    required void Function(List<String> urls) onComplete,
  }) async {
    final isMock = breakdownId.startsWith('mock-');
    final List<String> uploadedUrls = [];

    // Guard: mock incidents were never saved to Supabase → no real UUID
    // We allow them for storage upload (demo) but not for DB DB insert.
    if (!isMock && !_strictUuidRegex.hasMatch(breakdownId)) {
      onError(
        'This incident was created offline and has not been synced to the server yet. '
        'Please submit the incident report first before uploading media.',
      );
      return;
    }

    // Map the UI stage label to the database enum
    final stageSlug = stageLabel
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final stageEnum = _stageEnumMap[stageSlug] ?? 'damage_report';

    final safeId = breakdownId
        .replaceAll(RegExp(r'[^a-zA-Z0-9\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    final userId = _client.auth.currentUser?.id;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final ext = file.name.split('.').last.toLowerCase();
      final safeName = file.name
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(ext);

      try {
        onProgress(i, files.length);

        final storagePath =
            '$safeId/stages/$stageSlug/${DateTime.now().millisecondsSinceEpoch}_$safeName';

        await _client.storage.from('breakdown-media').uploadBinary(
              storagePath,
              file.bytes,
              fileOptions: FileOptions(
                contentType: _mimeType(ext),
                upsert: false,
              ),
            );

        final publicUrl =
            _client.storage.from('breakdown-media').getPublicUrl(storagePath);
        uploadedUrls.add(publicUrl);

        // Only insert into DB if it's a real incident
        if (!isMock) {
          await _client.from('repair_media').insert({
            'breakdown_id': breakdownId,
            'stage': stageEnum,
            'media_url': publicUrl,
            'media_type': isVideo ? 'video' : 'photo',
            'captured_at': DateTime.now().toIso8601String(),
            if (userId != null) 'uploaded_by': userId,
          });
        }
        
        onProgress(i + 1, files.length);
      } catch (e) {
        debugPrint('Stage upload error [$stageSlug] file=$safeName: $e');
        onError('Failed to upload $safeName: $e');
        return;
      }
    }

    onComplete(uploadedUrls);
  }

  // ── Profile photo upload ──────────────────────────────────────────────────
  Future<String> uploadProfilePhoto(String userId, Uint8List bytes) async {
    final path =
        '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage.from('img_profiles').uploadBinary(
          path,
          bytes,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    return _client.storage.from('img_profiles').getPublicUrl(path);
  }

  Future<void> deleteRepairMedia(String mediaId, String mediaUrl) async {
    try {
      // 1. Delete DB record
      await _client.from('repair_media').delete().match({'id': mediaId});

      // 2. Delete from storage
      final path = _extractStoragePath(mediaUrl);
      if (path != null) {
        await _client.storage.from('breakdown-media').remove([path]);
      }
    } catch (e) {
      debugPrint('Error deleting repair media: $e');
      throw e;
    }
  }

  Future<void> deleteMediaByUrl(String mediaUrl) async {
    try {
      final path = _extractStoragePath(mediaUrl);
      if (path != null) {
        await _client.storage.from('breakdown-media').remove([path]);
      }
    } catch (e) {
      debugPrint('Error deleting storage media by URL: $e');
    }
  }

  String? _extractStoragePath(String url) {
    if (!url.contains('breakdown-media/')) return null;
    return url.split('breakdown-media/').last.split('?').first;
  }

  Future<void> removeProfilePhoto(String userId) async {
    try {
      final List<FileObject> files =
          await _client.storage.from('img_profiles').list(path: userId);
      if (files.isNotEmpty) {
        final List<String> paths =
            files.map((file) => '$userId/${file.name}').toList();
        await _client.storage.from('img_profiles').remove(paths);
      }
    } catch (e) {
      debugPrint('Error removing profile photo: $e');
    }
  }

  String _mimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }
}
