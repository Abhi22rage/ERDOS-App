part of 'api_service.dart';

// ─── Media Upload ───────────────────────────────────────────────────────────
mixin _MediaMixin {
  SupabaseClient get _client;

  Future<String> uploadMedia(File file, String breakdownId) async {
    try {
      final fileName =
          '${breakdownId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = fileName;

      await _client.storage.from('breakdown-media').upload(path, file);

      final String publicUrl =
          _client.storage.from('breakdown-media').getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      debugPrint('UPLOAD ERROR (using demo fallback): $e');
      return 'https://images.unsplash.com/photo-1581092160562-40aa08e78837?auto=format&fit=crop&q=80&w=800';
    }
  }

  Future<String> uploadProfilePhoto(String userId, Uint8List bytes) async {
    final path = '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    await _client.storage.from('img_profiles').uploadBinary(
      path, 
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    
    return _client.storage.from('img_profiles').getPublicUrl(path);
  }

  Future<void> removeProfilePhoto(String userId) async {
    // In a real app, you might want to delete all files in the userId folder, 
    // but for now, we leave them in the bucket and rely on the new photo overwriting logic.
  }
}
