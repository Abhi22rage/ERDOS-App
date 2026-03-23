import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:phe_app/services/api_service.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize with dummy values for testing
  await Supabase.initialize(
    url: 'https://test.supabase.co',
    anonKey: 'fake_anon_key',
  );

  group('ApiService Flow Tests', () {
    test('createBreakdown adds to local incidents and maintains reportedBy', () async {
      final service = ApiService();
      
      final data = {
        'title': 'Test Incident',
        'severity': 'high',
        'asset_name': 'Test Asset',
      };
      
      final breakdown = await service.createBreakdown(data);
      
      expect(breakdown.title, 'Test Incident');
      expect(breakdown.reportedBy, isNotNull);
      
      final myBreakdowns = await service.getMyBreakdowns();
      expect(myBreakdowns.any((b) => b.id == breakdown.id), isTrue);
    });

    test('getMyBreakdowns returns mocks when empty', () async {
      final service = ApiService();
      final myBreakdowns = await service.getMyBreakdowns();
      expect(myBreakdowns, isNotEmpty);
    });
  });
}
