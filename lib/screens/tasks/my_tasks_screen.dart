import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/providers.dart';
import '../../models/breakdown_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fluent_ui.dart';

class MyTasksScreen extends ConsumerStatefulWidget {
  const MyTasksScreen({super.key});

  @override
  ConsumerState<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends ConsumerState<MyTasksScreen> {
  String _statusFilter = '';

  static const _filters = [
    {'value': '', 'label': 'All'},
    {'value': 'reported', 'label': 'Reported'},
    {'value': 'pending_approval', 'label': 'Pending'},
    {'value': 'in_progress', 'label': 'In Progress'},
    {'value': 'completed', 'label': 'Completed'},
  ];

  @override
  Widget build(BuildContext context) {
    final breakdownsAsync = ref.watch(myBreakdownsProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FluentBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Modern Header ──
              FluentHeader(
                title: 'My Tasks',
                actions: [
                  _buildHeaderActions(isDarkMode),
                ],
              ),

              // ── Filter Bar ──
              _buildFilterBar(isDarkMode),

              // ── Scrollable List ──
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.invalidate(myBreakdownsProvider),
                  child: breakdownsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (e, _) => _buildErrorState(e.toString(), isDarkMode),
                    data: (breakdowns) {
                      final filtered = _statusFilter.isEmpty
                          ? breakdowns
                          : breakdowns
                              .where((b) =>
                                  b.normalizedStatus == _statusFilter ||
                                  b.status == _statusFilter)
                              .toList();

                      if (filtered.isEmpty) return _buildEmptyState(isDarkMode);

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (_, i) => _IncidentCard(breakdown: filtered[i]),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActions(bool isDarkMode) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => ref.invalidate(myBreakdownsProvider),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(LucideIcons.refreshCw, size: 18, color: isDarkMode ? Colors.white70 : AppColors.primary),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Consumer(builder: (_, ref, __) {
            final count = ref.watch(myBreakdownsProvider).asData?.value.length ?? 0;
            return Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFilterBar(bool isDarkMode) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final isActive = _statusFilter == f['value'];
          return GestureDetector(
            onTap: () => setState(() => _statusFilter = f['value']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isActive 
                    ? LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])
                    : null,
                color: !isActive ? (isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white) : null,
                borderRadius: BorderRadius.circular(22),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                f['label']!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                  color: isActive ? Colors.white : (isDarkMode ? Colors.white38 : AppColors.textSecondary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.clipboardCheck, size: 64, color: isDarkMode ? Colors.white10 : AppColors.primary.withValues(alpha: 0.1)),
          ),
          const SizedBox(height: 24),
          const Text(
            'NO TASKS FOUND',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing the filters above',
            style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white38 : AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.cloudOff, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Connection error',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDarkMode ? Colors.white38 : AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => ref.invalidate(myBreakdownsProvider),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry Connection', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final BreakdownModel breakdown;
  const _IncidentCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.statusColor(breakdown.status);
    final dateStr = DateFormat('dd MMM, hh:mm a').format(breakdown.createdAt);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/incident/${breakdown.id}'),
      child: FluentCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                border: Border(bottom: BorderSide(color: statusColor.withValues(alpha: 0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: statusColor.withValues(alpha: 0.3), blurRadius: 4, spreadRadius: 1),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        breakdown.status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    breakdown.reportNumber ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white38 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    breakdown.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoIcon(LucideIcons.mapPin, isDarkMode),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          breakdown.assetName ?? 'Unknown Location',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildInfoIcon(LucideIcons.clock, isDarkMode),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white38 : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Icon(LucideIcons.chevronRight, size: 18, color: isDarkMode ? Colors.white10 : Colors.grey.shade300),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 12, color: isDarkMode ? Colors.white38 : AppColors.primary.withValues(alpha: 0.6)),
    );
  }
}
