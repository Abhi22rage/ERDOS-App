import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/fluent_ui.dart';

class ApprovalDashboardScreen extends ConsumerWidget {
  const ApprovalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(pendingApprovalsProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FluentBackground(
        child: SafeArea(
          child: Column(
            children: [
              FluentHeader(
                title: 'Management Approvals',
                actions: [
                  IconButton(
                    icon: Icon(LucideIcons.refreshCw, size: 18, color: isDarkMode ? Colors.white70 : AppColors.primary),
                    onPressed: () => ref.invalidate(pendingApprovalsProvider),
                  ),
                ],
              ),
              Expanded(
                child: approvalsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => _buildErrorState(e.toString()),
                  data: (approvals) {
                    if (approvals.isEmpty) {
                      return _buildEmptyState(isDarkMode);
                    }
                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async => ref.invalidate(pendingApprovalsProvider),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                        itemCount: approvals.length,
                        itemBuilder: (_, i) {
                          return _ApprovalCard(approval: approvals[i], isDarkMode: isDarkMode);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.checkCircle2, size: 64, color: isDarkMode ? Colors.white10 : Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            'NO PENDING APPROVALS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white24 : AppColors.textSecondary, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            'All incident requests are current.',
            style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white24 : AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text('Error loading approvals: $error', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ApprovalCard extends ConsumerWidget {
  final Map<String, dynamic> approval;
  final bool isDarkMode;

  const _ApprovalCard({required this.approval, required this.isDarkMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = approval['breakdown'] as Map<String, dynamic>?;
    final reporter = breakdown?['reporter'] as Map<String, dynamic>?;
    final severityColor = AppColors.severityColor(breakdown?['severity']);
    final createdAt = breakdown?['created_at'] != null ? DateTime.tryParse(breakdown!['created_at']) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FluentCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    breakdown?['title'] ?? 'Untitled Request',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (breakdown?['severity'] ?? 'LOW').toString().toUpperCase(),
                    style: TextStyle(fontSize: 10, color: severityColor, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (reporter != null) 
              _infoRow(LucideIcons.user, '${reporter['name'] ?? 'Staff'} • ${reporter['role']?.toString().toUpperCase() ?? 'MEMBER'}'),
            if (createdAt != null) 
              _infoRow(LucideIcons.calendar, DateFormat('dd MMM yyyy • hh:mm a').format(createdAt)),
            
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(context, ref, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text('APPROVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(context, ref, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withOpacity(0.35)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('REJECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isDarkMode ? Colors.white24 : AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white38 : AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, bool isApprove) async {
    final api = ref.read(apiServiceProvider);
    try {
      if (isApprove) {
        await api.approveBreakdown(approval['id'].toString());
      } else {
        await api.rejectBreakdown(approval['id'].toString());
      }
      
      ref.invalidate(pendingApprovalsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApprove ? 'Request Approved' : 'Request Rejected'),
            backgroundColor: isApprove ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }
}
