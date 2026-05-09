import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_providers.dart';

// ─── Tasks ────────────────────────────────────────────────────────────────────
final tasksProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(apiServiceProvider).getTasks();
});

// ─── Notifications ────────────────────────────────────────────────────────────
final notificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(apiServiceProvider).getNotifications();
});

// ─── Pending Approvals ────────────────────────────────────────────────────────
final pendingApprovalsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(apiServiceProvider).getPendingApprovals();
});

// ─── Schemes ──────────────────────────────────────────────────────────────────
final schemesProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(apiServiceProvider).getSchemes();
});

// ─── Assets ───────────────────────────────────────────────────────────────────
final assetsProvider =
    FutureProvider.family.autoDispose((ref, String? type) async {
  return ref.read(apiServiceProvider).getAssets(type: type);
});

// ─── Contractors ──────────────────────────────────────────────────────────────
final contractorsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(apiServiceProvider).getContractors();
});
