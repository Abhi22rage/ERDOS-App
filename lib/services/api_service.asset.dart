part of 'api_service.dart';

// ─── Assets ─────────────────────────────────────────────────────────────────
mixin _AssetMixin {
  SupabaseClient get _client;

  Future<List<Map<String, dynamic>>> getAssets({String? type}) async {
    try {
      var query = _client.from('assets').select('*');
      if (type != null) {
        query = query.eq('type', type) as dynamic;
      }
      final data = await query.order('name');
      final items = List<Map<String, dynamic>>.from(data);

      if (items.isEmpty) return _getAssetMocks(type);
      return items;
    } catch (e) {
      return _getAssetMocks(type);
    }
  }

  List<Map<String, dynamic>> _getAssetMocks(String? type) {
    final all = [
      {'id': 'bs-1', 'name': 'Basistha Boosting Station', 'type': 'boosting_station', 'location': 'Basistha Chariali'},
      {'id': 'bs-2', 'name': 'Khanapara Reserviour Station', 'type': 'boosting_station', 'location': 'Khanapara near S.P. Office'},
      {'id': 'pl-1', 'name': 'Main Rising Main 600mm', 'type': 'pipeline', 'location': 'Zoo Road to Ganeshguri'},
      {'id': 'pl-2', 'name': 'Distribution Line 150mm', 'type': 'pipeline', 'location': 'Dispur Last Gate Area'},
    ];

    if (type == null) return all;
    return all.where((a) => a['type'] == type).toList();
  }

  Future<Map<String, dynamic>> getAssetById(String id) async {
    final data = await _client
        .from('assets')
        .select('*, components:asset_components(*)')
        .eq('id', id)
        .single();
    return data;
  }
}
