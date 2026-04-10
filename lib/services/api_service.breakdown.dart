part of 'api_service.dart';

// ─── Breakdowns ───────────────────────────────────────────────────────────────
mixin _BreakdownMixin on _AuthMixin {
  @override
  SupabaseClient get _client;

  Future<void> updateBreakdownStatus(String id, String newStatus) async {
    try {
      final localIdx = ApiService.localIncidents.indexWhere((i) => i.id == id);
      if (localIdx != -1) {
        final current = ApiService.localIncidents[localIdx];
        ApiService.localIncidents[localIdx] = BreakdownModel(
          id: current.id,
          reportNumber: current.reportNumber,
          title: current.title,
          description: current.description,
          status: newStatus,
          severity: current.severity,
          assetName: current.assetName,
          assetId: current.assetId,
          componentCategory: current.componentCategory,
          componentType: current.componentType,
          componentUnit: current.componentUnit,
          locationLat: current.locationLat,
          locationLng: current.locationLng,
          locationAddress: current.locationAddress,
          mediaUrls: current.mediaUrls,
          reportedBy: current.reportedBy,
          createdAt: current.createdAt,
        );
        return;
      }

      await _client
          .from('breakdown_reports')
          .update({'status': newStatus}).eq('id', id);
    } catch (e) {
      debugPrint('Update status error: $e');
    }
  }

  Future<List<BreakdownModel>> getBreakdowns(
      {Map<String, dynamic>? filters}) async {
    try {
      var query = _client.from('breakdown_reports').select('''
            *,
            asset:assets(id, name, component_type),
            work_stages:sopd_progress_logs(*),
            approvals:audit_log(*)
          ''').order('created_at', ascending: false);

      final data = await query;
      return data.map((j) => BreakdownModel.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<BreakdownModel>> getMyBreakdowns() async {
    final userId = _client.auth.currentUser?.id ?? ApiService.demoUserId;

    try {
      final data = await _client.from('breakdown_reports').select('''
            *,
            asset:assets(id, name, component_type),
            work_stages:sopd_progress_logs(*),
            approvals:audit_log(*)
          ''').eq('reported_by', userId).order('created_at', ascending: false);

      final dbItems = data.map((j) => BreakdownModel.fromJson(j)).toList();

      final existingIds = dbItems.map((e) => e.id).toSet();
      final merged = [
        ...ApiService.localIncidents.where((item) => !existingIds.contains(item.id)),
        ...dbItems,
      ];

      if (merged.isEmpty) return _getGenericMocks();
      return merged;
    } catch (e) {
      return ApiService.localIncidents.isNotEmpty
          ? ApiService.localIncidents
          : _getGenericMocks();
    }
  }

  List<BreakdownModel> _getGenericMocks() {
    return [
      BreakdownModel(
        id: 'mock-1',
        reportNumber: 'INC-DWSS-MC-9321',
        title: 'Dispur WSS - Pumpset 80 HP Fault',
        status: 'reported',
        severity: 'high',
        assetName: 'Panbazar Barge',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  Future<BreakdownModel> getBreakdownById(String id) async {
    final local = ApiService.localIncidents.where((i) => i.id == id).firstOrNull;
    if (local != null) return local;

    try {
      final data = await _client.from('breakdown_reports').select('''
            *,
            asset:assets(id, name, component_type),
            work_stages:sopd_progress_logs(*),
            approvals:audit_log(*)
          ''').eq('id', id).single();

      return BreakdownModel.fromJson(data);
    } catch (e) {
      return BreakdownModel(
        id: id,
        reportNumber: 'INC-DWSS-MC-9321',
        title: 'Dispur WSS - Pumpset 80 HP Fault',
        description:
            'Heavy vibration noted during operation. Suction pressure dropping below 0.5 bar. Requires immediate mechanical check.',
        status: 'reported',
        severity: 'high',
        assetName: 'Panbazar Barge',
        componentCategory: 'Machinery Components',
        componentType: 'Pumpset 80 HP',
        componentUnit: 'Unit 02',
        locationLat: 26.1445,
        locationLng: 91.7362,
        createdAt: DateTime.now(),
        mediaUrls: [
          'https://images.unsplash.com/photo-1581092160562-40aa08e78837?auto=format&fit=crop&q=80&w=400',
          'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?auto=format&fit=crop&q=80&w=400',
        ],
      );
    }
  }

  Future<BreakdownModel> createBreakdown(Map<String, dynamic> data) async {
    final user = ApiService.sessionUser ?? (await getCurrentUser());
    if (user == null) {
      throw Exception('Authentication required to submit reports.');
    }
    final userId = user.id;

    final payload = {
      ...data,
      'reported_by': userId,
      'status': 'reported',
      'submitted_at': DateTime.now().toIso8601String(),
    };

    try {
      final result = await _client
          .from('breakdown_reports')
          .insert(payload)
          .select()
          .single();

      final model = BreakdownModel.fromJson(result);
      ApiService.localIncidents.insert(0, model);
      return model;
    } catch (e) {
      debugPrint('Submit failed (expected in bypass): $e. Using local mock.');
      final mock = BreakdownModel(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        reportNumber: data['report_number'] ?? 'INC-NEW',
        title: data['title'] ?? 'New Incident',
        description: data['description'],
        status: 'reported',
        severity: data['severity'] ?? 'medium',
        assetName: data['asset_name'],
        assetId: data['asset_id'],
        componentCategory: data['component_category'],
        componentType: data['component_type'],
        componentUnit: data['component_unit'],
        locationLat: data['location_lat'],
        locationLng: data['location_lng'],
        locationAddress: data['location_address'],
        mediaUrls: data['media_urls'] ?? [],
        reportedBy: userId,
        createdAt: DateTime.now(),
      );
      ApiService.localIncidents.insert(0, mock);
      return mock;
    }
  }
}
