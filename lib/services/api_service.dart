import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/breakdown_model.dart';

class ApiService {
  final SupabaseClient _client = Supabase.instance.client;

  // For demonstration: persist newly created incidents in-memory
  // so they show up even if the Supabase insert fails or auth is bypassed.
  static final List<BreakdownModel> _localIncidents = [];
  static UserModel? _sessionUser;

  static const String _demoUserId = '22222222-2222-2222-2222-222222222222';

  // ─── Auth ─────────────────────────────────────────────────────────────────
  Future<UserModel?> getCurrentUser() async {
    // Return early if we have an in-memory session (from demo login)
    if (_sessionUser != null) return _sessionUser;

    final currentUser = _client.auth.currentUser;
    if (currentUser == null) return null;
    final userId = currentUser.id;
    final data =
        await _client.from('users').select().eq('id', userId).maybeSingle();
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  Future<Map<String, dynamic>> login(String mobile, String password) async {
    try {
      // 1. Attempt real authentication if user exists
      final userData = await _client
          .from('users')
          .select('email')
          .eq('phone', mobile.trim())
          .maybeSingle();

      if (userData != null && userData['email'] != null) {
        final email = userData['email'] as String;
        await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        // Just a demo bypass - doesn't actually sign in to GoTrue
        // but lets the app proceed with a mock user
        debugPrint('Bypassing real auth for unknown user: $mobile');
      }
    } catch (e) {
      // Fallback for demo: if password is wrong or auth fails, ignore and proceed
      debugPrint('Auth error: $e. Proceeding in Demo Mode.');
    }

    // Always return a user to ensure "any credentials work"
    // We'll try to get the specified mobile user, or fall back to a default
    try {
      final finalUserData = await _client
          .from('users')
          .select()
          .eq('phone', mobile.trim())
          .maybeSingle();

      if (finalUserData != null) {
        _sessionUser = UserModel.fromJson(finalUserData);
        return {'user': _sessionUser};
      }

      // Absolute fallback: Return the primary field staff user
      final defaultData = await _client
          .from('users')
          .select()
          .eq('phone', '4444444444')
          .single();
      _sessionUser = UserModel.fromJson(defaultData);
      return {'user': _sessionUser};
    } catch (e) {
      debugPrint('DB Fallback failed: $e. Using hardcoded mock.');
      // Absolute failsafe: Return a mock user if even the DB fallback fails
      _sessionUser = UserModel(
        id: 'demo-staff-999',
        name: 'Emergency Staff',
        mobile: mobile.isNotEmpty ? mobile : '4444444444',
        role: 'khalasi',
        isVerified: true,
      );
      return {'user': _sessionUser};
    }
  }


  Future<Map<String, dynamic>> signup(Map<String, dynamic> userData) async {
    final mobile = userData['mobile']?.toString().trim() ?? '';
    final password = userData['password'] as String;
    final name = userData['name'] as String?;
    final role = userData['role'] ?? 'khalasi';

    // Create a unique email from mobile (Supabase requires email)
    final email = '${mobile}@phe.app';

    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Sign up failed. Please try again.');
    }

    // Create user record in our users table
    await _client.from('users').insert({
      'id': response.user!.id,
      'name': name,
      'email': email,
      'phone': mobile,
      'role': role,
      'is_verified': false,
    });

    final user = await getCurrentUser();
    return {
      'user': user,
      'session': response.session,
    };
  }

  Future<void> logout() async {
    _sessionUser = null;
    await _client.auth.signOut();
  }

  Future<void> updateBreakdownStatus(String id, String newStatus) async {
    try {
      // Update local mock incidents first
      final localIdx = _localIncidents.indexWhere((i) => i.id == id);
      if (localIdx != -1) {
        final current = _localIncidents[localIdx];
        _localIncidents[localIdx] = BreakdownModel(
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
    final userId = _client.auth.currentUser?.id ?? _demoUserId;

    try {
      final data = await _client.from('breakdown_reports').select('''
            *,
            asset:assets(id, name, component_type),
            work_stages:sopd_progress_logs(*),
            approvals:audit_log(*)
          ''').eq('reported_by', userId).order('created_at', ascending: false);

      final dbItems = data.map((j) => BreakdownModel.fromJson(j)).toList();

      // Merge with local items (filter to avoid duplicates if DB worked)
      final existingIds = dbItems.map((e) => e.id).toSet();
      final merged = [
        ..._localIncidents.where((item) => !existingIds.contains(item.id)),
        ...dbItems,
      ];

      if (merged.isEmpty) return _getGenericMocks();
      return merged;
    } catch (e) {
      return _localIncidents.isNotEmpty ? _localIncidents : _getGenericMocks();
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
    // Check locally persisted incidents first (for instant demo feedback)
    final local = _localIncidents.where((i) => i.id == id).firstOrNull;
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
      // Return mock for demo if not found
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
    final user = _sessionUser ?? (await getCurrentUser());
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
      _localIncidents.insert(0, model);
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
      _localIncidents.insert(0, mock);
      return mock;
    }
  }

  // ─── Approvals ────────────────────────────────────────────────────────────
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

  // ─── Tasks ────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      // Use sopd_progress_logs as tasks for development
      final data = await _client
          .from('sopd_progress_logs')
          .select('''
            *,
            work:sopd_works(*)
          ''')
          .limit(10);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('TASKS ERROR: $e');
      return [];
    }
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    await _client.from('tasks').update(data).eq('id', taskId);
  }

  // ─── Notifications ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final userId = _client.auth.currentUser?.id ?? _demoUserId;
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
          .update({'status': 'sent'}) // notifications_log has 'status' enum
          .eq('id', id);
    } catch (e) {
      print('NOTIF UPDATE ERROR: $e');
    }
  }

  Future<void> markAllNotificationsRead() async {
    final userId = _client.auth.currentUser?.id ?? _demoUserId;
    try {
      await _client
          .from('notifications_log')
          .update({'status': 'sent'}).eq('sent_to', userId);
    } catch (e) {
      print('NOTIF MARK ALL ERROR: $e');
    }
  }

  // ─── Schemes ──────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSchemes() async {
    try {
      final data = await _client
          .from('sopd_works')
          .select('*, milestones:sopd_progress_logs(*)')
          .order('created_at', ascending: false);

      // Map 'work_name' to 'title' to match project's Scheme model expectation
      return data.map((d) => {
        ...d,
        'title': d['work_name'] ?? 'Untitled work',
      }).toList();
    } catch (e) {
      print('SCHEMES ERROR: $e');
      return [];
    }
  }

  // ─── Contractors ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getContractors() async {
    final data = await _client
        .from('contractors')
        .select('*, user:users(name, phone)')
        .order('company_name');
    return List<Map<String, dynamic>>.from(data);
  }

  // ─── Reports / Summary ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSummary() async {
    try {
      final breakdowns =
          await _client.from('breakdown_reports').select('status');
      final approvals = await _client
          .from('approvals')
          .select('id')
          .eq('status', 'pending');

      int active = 0, pending = approvals.length, completed = 0;

      // Combine DB with local
      final List<String> allStatuses = [
        ...breakdowns.map((b) => b['status'] as String? ?? ''),
        ..._localIncidents.map((i) => i.status),
      ];

      for (final status in allStatuses) {
        if (['reported', 'assigned', 'in_progress']
            .contains(status)) {
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
      // Fallback if DB fails: use ONLY local incidents
      int active = _localIncidents
          .where((i) => ['reported', 'assigned', 'in_progress']
              .contains(i.status))
          .length;
      int pending = _localIncidents
          .where((i) => i.status == 'pending_approval' || i.status == 'approved')
          .length;
      int completed = _localIncidents
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

  // ─── Media Upload ─────────────────────────────────────────────────────────
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
      // Return a professional industry-standard mock image for the demo
      return 'https://images.unsplash.com/photo-1581092160562-40aa08e78837?auto=format&fit=crop&q=80&w=800';
    }
  }
}
