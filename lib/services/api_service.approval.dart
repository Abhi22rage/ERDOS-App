part of 'api_service.dart';

// ─── Approvals ──────────────────────────────────────────────────────────────
mixin _ApprovalMixin {
  SupabaseClient get _client;

  Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    final data = await _client.from('approvals').select('''
          *,
          breakdown:breakdown_reports(
            id, title, status, severity, report_number, created_at,
            reporter:users(name, role),
            asset:assets(name)
          ),
          approver:users(name, role)
        ''').eq('status', 'pending').order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> approveBreakdown(String approvalId, {String? comments}) async {
    await _client.from('approvals').update({
      'status': 'approved',
      'comments': comments,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', approvalId);
  }

  Future<void> rejectBreakdown(String approvalId, {String? comments}) async {
    await _client.from('approvals').update({
      'status': 'rejected',
      'comments': comments,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', approvalId);
  }
}
