part of 'api_service.dart';

// ─── Tasks ──────────────────────────────────────────────────────────────────
mixin _TaskMixin {
  SupabaseClient get _client;

  Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final data = await _client
          .from('sopd_progress_logs')
          .select('''
            *,
            work:sopd_works(*)
          ''')
          .limit(10);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    await _client.from('tasks').update(data).eq('id', taskId);
  }
}
