import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/fluent_ui.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(summaryProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FluentBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Modern Header ──
              FluentHeader(
                title: 'Analytics & Reports',
                actions: [
                  GestureDetector(
                    onTap: () => ref.invalidate(summaryProvider),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(LucideIcons.refreshCw, size: 18, color: isDarkMode ? Colors.white70 : AppColors.primary),
                    ),
                  ),
                ],
              ),

              // ── Scrollable Dashboard ──
              Expanded(
                child: summaryAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => _buildErrorState(e.toString(), isDarkMode),
                  data: (summary) => SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FluentSectionHeader(title: 'Overview'),
                        const SizedBox(height: 16),
                        
                        // Main Stats Grid
                        Row(
                          children: [
                            _buildFluentStatCard(
                              context,
                              '${summary['totalBreakdowns'] ?? 0}',
                              'Total Issues',
                              AppColors.primary,
                              LucideIcons.alertTriangle,
                              isDarkMode,
                            ),
                            const SizedBox(width: 16),
                            _buildFluentStatCard(
                              context,
                              '${summary['completedBreakdowns'] ?? 0}',
                              'Resolved',
                              AppColors.success,
                              LucideIcons.checkCircle,
                              isDarkMode,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildFluentStatCard(
                              context,
                              '${summary['activeBreakdowns'] ?? 0}',
                              'In Progress',
                              const Color(0xFF1E88E5),
                              LucideIcons.wrench,
                              isDarkMode,
                            ),
                            const SizedBox(width: 16),
                            _buildFluentStatCard(
                              context,
                              '${summary['pendingApprovals'] ?? 0}',
                              'Pending Auth',
                              AppColors.warning,
                              LucideIcons.shieldAlert,
                              isDarkMode,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        const FluentSectionHeader(title: 'System Health'),
                        const SizedBox(height: 16),

                        // Completion rate glass card
                        _buildCompletionRateCard(summary, isDarkMode),
                        
                        const SizedBox(height: 32),
                        const FluentSectionHeader(title: 'Available Reports'),
                        const SizedBox(height: 16),

                        // Certificate Link
                        _buildReportLink(
                          context,
                          'Work Completion Certificate',
                          'Download PDF summary of resolved tasks',
                          LucideIcons.fileText,
                          isDarkMode,
                          onTap: () => context.push('/certificate-report'),
                        ),
                        const SizedBox(height: 12),
                        _buildReportLink(
                          context,
                          'Monthly Operational Summary',
                          'Last generated: 2 hours ago',
                          LucideIcons.barChart,
                          isDarkMode,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFluentStatCard(BuildContext context, String value, String label, Color color, IconData icon, bool isDarkMode) {
    return Expanded(
      child: FluentCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isDarkMode ? Colors.white24 : AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionRateCard(Map<String, dynamic> summary, bool isDarkMode) {
    final total = (summary['totalBreakdowns'] as int?) ?? 0;
    final done = (summary['completedBreakdowns'] as int?) ?? 0;
    final pct = total > 0 ? done / total : 0.0;

    return FluentCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COMPLETION RATE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isDarkMode ? Colors.white24 : AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFF0F3F9),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Currently resolving $done out of $total reported incidents across all production centers.',
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportLink(BuildContext context, String title, String subtitle, IconData icon, bool isDarkMode, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: FluentCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white24 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: isDarkMode ? Colors.white10 : Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.cloudOff, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          const Text('ANALYTICS UNAVAILABLE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(error, style: TextStyle(color: isDarkMode ? Colors.white38 : AppColors.textSecondary)),
        ],
      ),
    );
  }
}
