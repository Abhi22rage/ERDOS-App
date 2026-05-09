import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/breakdown_model.dart';
import 'core_providers.dart';

// ─── Summary / Report ─────────────────────────────────────────────────────────
final summaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(apiServiceProvider).getSummary();
});

// ─── Breakdowns ───────────────────────────────────────────────────────────────
final myBreakdownsProvider =
    FutureProvider.autoDispose<List<BreakdownModel>>((ref) async {
  return ref.read(apiServiceProvider).getMyBreakdowns();
});

final allBreakdownsProvider =
    FutureProvider.autoDispose<List<BreakdownModel>>((ref) async {
  return ref.read(apiServiceProvider).getBreakdowns();
});

final breakdownDetailProvider =
    FutureProvider.family.autoDispose<BreakdownModel, String>((ref, id) async {
  return ref.read(apiServiceProvider).getBreakdownById(id);
});
