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

  // Fetch all active contractors for assignment
  Future<List<Map<String, dynamic>>> getContractors() async {
    try {
      final data = await _client
          .from('contractor')
          .select('id, user_id, category, license_number, users!contractor_user_id_fkey(full_name, phone_number, is_active)')
          .isFilter('deleted_at', null)
          .eq('status', 'active');
          
      // Filter out deleted/inactive users manually if nested filtering isn't perfectly supported
      final activeContractors = data.where((c) {
        final user = c['users'] as Map<String, dynamic>?;
        return user != null && user['is_active'] == true;
      }).toList();
      
      return List<Map<String, dynamic>>.from(activeContractors);
    } catch (e) {
      debugPrint('Error fetching contractors: $e');
      return [];
    }
  }

  // Allot work to a contractor
  Future<void> allotWork({
    required String breakdownId,
    required String contractorId,
    required String assignedByUserId,
  }) async {
    // We do an insert into work_orders
    await _client.from('work_orders').insert({
      'breakdown_id': breakdownId,
      'contractor_id': contractorId,
      'assigned_by': assignedByUserId,
      'status': 'pending',
    });
    
    // Log approval flow as ASSIGNED
    await _client.from('approval_flow').insert({
      'breakdown_id': breakdownId,
      'action': 'ASSIGNED',
      'acted_by': assignedByUserId,
      'remarks': 'Work allotted to contractor',
    });
    
    // Retrieve the status_id for 'assigned'
    final statusResp = await _client
        .from('breakdown_statuses')
        .select('id')
        .eq('name', 'assigned')
        .single();
        
    // Update the breakdown status
    await _client.from('breakdowns').update({
      'status_id': statusResp['id'],
    }).eq('id', breakdownId);
  }

  Future<void> updateWorkOrderExcavation(String workOrderId, bool required) async {
    await _client.from('work_orders').update({
      'excavation_required': required,
    }).eq('id', workOrderId);
  }

  Future<void> startWork(String breakdownId, String workOrderId, String userId) async {
    // 1. Update work_order status
    await _client.from('work_orders').update({
      'status': 'in_progress',
    }).eq('id', workOrderId);

    // 2. Insert initial stage into execution_stages
    try {
      await _client.from('execution_stages').insert({
        'breakdown_id': breakdownId,
        'stage_name': 'initial_inspection',
        'uploaded_by': userId,
        'remarks': 'Work commenced',
      });
    } catch (e) {
      debugPrint('Warning: initial_inspection stage might already exist or failed to insert: $e');
    }

    // 3. Update breakdown status
    final statusResp = await _client
        .from('breakdown_statuses')
        .select('id')
        .eq('name', 'in_progress')
        .single();

    await _client.from('breakdowns').update({
      'status_id': statusResp['id'],
    }).eq('id', breakdownId);
  }
}
