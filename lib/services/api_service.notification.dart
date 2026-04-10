part of 'api_service.dart';

// ─── Notifications ──────────────────────────────────────────────────────────
mixin _NotificationMixin {
  SupabaseClient get _client;

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final userId = ApiService.sessionUser?.id ?? 
                   _client.auth.currentUser?.id ?? 
                   ApiService.demoUserId;
    try {
      final data = await _client
          .from('notifications_log')
          .select('*')
          .eq('sent_to', userId)
          .order('sent_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('NOTIFICATION ERROR: $e');
      return [];
    }
  }

  Future<void> markNotificationRead(String id) async {
    try {
      await _client
          .from('notifications_log')
          .update({'is_read': true, 'status': 'read'})
          .eq('id', id);
    } catch (e) {
      print('NOTIF UPDATE ERROR: $e');
    }
  }

  Future<void> markAllNotificationsRead() async {
    final userId = ApiService.sessionUser?.id ?? 
                   _client.auth.currentUser?.id ?? 
                   ApiService.demoUserId;
    try {
      await _client
          .from('notifications_log')
          .update({'is_read': true, 'status': 'read'})
          .eq('sent_to', userId);
    } catch (e) {
      print('NOTIF MARK ALL ERROR: $e');
    }
  }
}
