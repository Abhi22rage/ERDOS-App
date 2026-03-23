import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/providers.dart';
import '../models/breakdown_model.dart';
import '../theme/app_theme.dart';
import '../widgets/fluent_ui.dart';
import '../widgets/gps_image_overlay.dart';

const _progressSteps = [
  {'key': 'reported', 'label': 'Reported', 'icon': LucideIcons.fileText, 'desc': 'Incident submitted'},
  {'key': 'pending_approval', 'label': 'Pending Approval', 'icon': LucideIcons.clock, 'desc': 'Awaiting engineer approval'},
  {'key': 'approved', 'label': 'Approved', 'icon': LucideIcons.checkCircle, 'desc': 'Approved by engineer'},
  {'key': 'assigned', 'label': 'Assigned', 'icon': LucideIcons.userPlus, 'desc': 'Team assigned to task'},
  {'key': 'in_progress', 'label': 'In Progress', 'icon': LucideIcons.wrench, 'desc': 'Repair work ongoing'},
  {'key': 'completed', 'label': 'Completed', 'icon': LucideIcons.flag, 'desc': 'Repair completed'},
  {'key': 'closed', 'label': 'Closed', 'icon': LucideIcons.lock, 'desc': 'Case officially closed'},
];

class IncidentDetailScreen extends ConsumerWidget {
  final String id;
  const IncidentDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(breakdownDetailProvider(id));
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FluentBackground(
        child: SafeArea(
          child: Column(
            children: [
              FluentHeader(
                title: 'Incident Details',
                actions: [
                  IconButton(
                    icon: Icon(LucideIcons.refreshCw, size: 18, color: isDarkMode ? Colors.white70 : AppColors.primary),
                    onPressed: () => ref.invalidate(breakdownDetailProvider(id)),
                  ),
                ],
              ),
              Expanded(
                child: async.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => _buildErrorState(context, e.toString()),
                  data: (breakdown) => _buildBody(context, ref, breakdown, isDarkMode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, BreakdownModel breakdown, bool isDarkMode) {
    final statusColor = AppColors.statusColor(breakdown.status);
    final severityColor = AppColors.severityColor(breakdown.severity);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(breakdownDetailProvider(id)),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status Banner ──
            FluentCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.info, size: 14, color: statusColor),
                        const SizedBox(width: 8),
                        Text(
                          breakdown.status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    breakdown.displayId,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'REPORTED ON ${DateFormat('dd MMMM yyyy').format(breakdown.createdAt).toUpperCase()}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDarkMode ? Colors.white24 : AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const FluentSectionHeader(title: 'Overview'),
            const SizedBox(height: 16),

            // ── Grid Info ──
            Row(
              children: [
                _buildInfoTile('SEVERITY', breakdown.severity.toUpperCase(), severityColor, isDarkMode),
                const SizedBox(width: 16),
                _buildInfoTile('STATUS', breakdown.status.replaceAll('_', ' ').toUpperCase(), statusColor, isDarkMode),
              ],
            ),
            const SizedBox(height: 16),
            
            // ── Evidence Button ──
            if (breakdown.mediaUrls.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _viewFullImage(context, breakdown.mediaUrls.first, breakdown),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.08),
                    shadowColor: Colors.transparent,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(LucideIcons.camera, size: 18),
                  label: const Text('VIEW PHOTO EVIDENCE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 16),
            ],

            FluentCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _infoRow('Asset ID', breakdown.reportNumber ?? 'N/A', isDarkMode),
                  const Divider(height: 24),
                  _infoRow('Asset Name', breakdown.assetName ?? 'N/A', isDarkMode),
                  const Divider(height: 24),
                  _infoRow('Category', breakdown.componentCategory ?? 'N/A', isDarkMode),
                  const Divider(height: 24),
                  _infoRow('Component', breakdown.componentType ?? 'N/A', isDarkMode),
                  if (breakdown.componentUnit != null) ...[
                    const Divider(height: 24),
                    _infoRow('Specific Unit', breakdown.componentUnit!, isDarkMode, highlight: true),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),
            const FluentSectionHeader(title: 'Description'),
            const SizedBox(height: 16),
            FluentCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(breakdown.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text(
                    breakdown.description ?? 'No detailed description provided.',
                    style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white60 : AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const FluentSectionHeader(title: 'Progress Timeline'),
            const SizedBox(height: 16),
            FluentCard(
              padding: const EdgeInsets.all(24),
              child: _buildTimeline(breakdown.statusIndex, isDarkMode),
            ),

            if (breakdown.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 32),
              const FluentSectionHeader(title: 'Media Evidence'),
              const SizedBox(height: 16),
              _buildMediaGallery(context, breakdown, isDarkMode),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, Color color, bool isDarkMode) {
    return Expanded(
      child: FluentCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white24 : AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDarkMode, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white38 : AppColors.textSecondary, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: highlight ? AppColors.primary : (isDarkMode ? Colors.white : AppColors.textPrimary))),
      ],
    );
  }

  Widget _buildTimeline(int currentIdx, bool isDarkMode) {
    return Column(
      children: List.generate(_progressSteps.length, (i) {
        final step = _progressSteps[i];
        final isDone = i <= currentIdx;
        final isActive = i == currentIdx;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.primary : (isDone ? AppColors.primary.withValues(alpha: 0.3) : (isDarkMode ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade200)),
                      border: isActive ? Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 4) : null,
                    ),
                  ),
                  if (i < _progressSteps.length - 1)
                    Container(width: 2, height: 40, color: isDone ? AppColors.primary.withValues(alpha: 0.3) : (isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                      color: isActive ? AppColors.primary : (isDone ? (isDarkMode ? Colors.white70 : AppColors.textPrimary) : (isDarkMode ? Colors.white24 : AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step['desc'] as String,
                    style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.white24 : AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMediaGallery(BuildContext context, BreakdownModel breakdown, bool isDarkMode) {
    final urls = breakdown.mediaUrls;
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _viewFullImage(context, urls[index], breakdown),
            child: Hero(
              tag: urls[index],
              child: FluentCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GPSImageOverlay(
                    imageUrl: urls[index],
                    breakdown: breakdown,
                    isDarkMode: isDarkMode,
                    width: 280,
                    height: 200,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _viewFullImage(BuildContext context, String url, BreakdownModel breakdown) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: InteractiveViewer(
                child: GPSImageOverlay(
                  imageUrl: url,
                  breakdown: breakdown,
                  isDarkMode: true,
                  fit: BoxFit.contain, // Use contain for full view
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          const Text('INCIDENT NOT FOUND', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 8),
          TextButton(onPressed: () => context.pop(), child: const Text('GO BACK')),
        ],
      ),
    );
  }
}
