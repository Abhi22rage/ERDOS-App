import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/breakdown_model.dart';

part 'api_service.auth.dart';
part 'api_service.breakdown.dart';
part 'api_service.approval.dart';
part 'api_service.asset.dart';
part 'api_service.task.dart';
part 'api_service.notification.dart';
part 'api_service.report.dart';
part 'api_service.media.dart';

/// Core API service — shared Supabase client and state.
/// Methods are organized in part files by domain.
class ApiService
    with
        _AuthMixin,
        _BreakdownMixin,
        _ApprovalMixin,
        _AssetMixin,
        _TaskMixin,
        _NotificationMixin,
        _ReportMixin,
        _MediaMixin {
  final SupabaseClient _client = Supabase.instance.client;

  // Shared in-memory state for demo/mock behavior
  static final List<BreakdownModel> localIncidents = [];
  static UserModel? sessionUser;

  static const String demoUserId = '22222222-2222-2222-2222-222222222222';
}
