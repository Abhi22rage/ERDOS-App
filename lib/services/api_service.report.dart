part of 'api_service.dart';

// ─── Reports / Summary / Schemes / Contractors ──────────────────────────────
mixin _ReportMixin {
  SupabaseClient get _client;

  Future<Map<String, dynamic>> getSummary() async {
    try {
      final breakdowns =
          await _client.from('breakdown_reports').select('status');
      final approvals = await _client
          .from('approvals')
          .select('id')
          .eq('status', 'pending');

      int active = 0, pending = approvals.length, completed = 0;

      final List<String> allStatuses = [
        ...breakdowns.map((b) => b['status'] as String? ?? ''),
        ...ApiService.localIncidents.map((i) => i.status),
      ];

      for (final status in allStatuses) {
        if (['reported', 'assigned', 'in_progress'].contains(status)) {
          active++;
        } else if (status == 'pending_approval' || status == 'approved') {
          pending++;
        } else if (['completed', 'closed'].contains(status)) {
          completed++;
        }
      }

      return {
        'activeBreakdowns': active,
        'pendingApprovals': pending,
        'completedBreakdowns': completed,
        'totalTasks': active + pending + completed,
      };
    } catch (e) {
      int active = ApiService.localIncidents
          .where((i) =>
              ['reported', 'assigned', 'in_progress'].contains(i.status))
          .length;
      int pending = ApiService.localIncidents
          .where(
              (i) => i.status == 'pending_approval' || i.status == 'approved')
          .length;
      int completed = ApiService.localIncidents
          .where((i) => ['completed', 'closed'].contains(i.status))
          .length;
      return {
        'activeBreakdowns': active,
        'pendingApprovals': pending,
        'completedBreakdowns': completed,
        'totalTasks': active + pending + completed,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getSchemes() async {
    try {
      final data = await _client
          .from('sopd_works')
          .select('*, milestones:sopd_progress_logs(*)')
          .order('created_at', ascending: false);

      return data.map((d) => {
        ...d,
        'title': d['work_name'] ?? 'Untitled work',
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getContractors() async {
    final data = await _client
        .from('contractors')
        .select('*, user:users(name, phone)')
        .order('company_name');
    return List<Map<String, dynamic>>.from(data);
  }
}
