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
}
