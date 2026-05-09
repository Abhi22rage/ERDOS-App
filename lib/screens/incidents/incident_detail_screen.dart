import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/providers.dart';
import '../../models/breakdown_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fluent_ui.dart';
import '../../widgets/gps_image_overlay.dart';
import '../../widgets/allot_work_modal.dart';
import '../../services/api_service.dart';
import 'work_progress_upload_screen.dart';

// ─── Progress Step Definitions ───────────────────────────────────────────────
const _progressSteps = [
  {'key': 'reported',         'label': 'Reported',            'icon': LucideIcons.fileText,    'desc': 'Incident submitted'},
  {'key': 'pending_approval', 'label': 'Pending Approval',    'icon': LucideIcons.clock,       'desc': 'Awaiting engineer approval'},
  {'key': 'approved',         'label': 'Approved',            'icon': LucideIcons.checkCircle, 'desc': 'Work has been approved'},
  {'key': 'assigned',         'label': 'Contractor Assigned', 'icon': LucideIcons.userPlus,    'desc': 'Team assigned to task'},
  {'key': 'in_progress',      'label': 'In Progress',         'icon': LucideIcons.wrench,      'desc': 'Repair work ongoing'},
  {'key': 'completed',        'label': 'Completed',           'icon': LucideIcons.flag,        'desc': 'Repair completed'},
  {'key': 'closed',           'label': 'Closed',              'icon': LucideIcons.lock,        'desc': 'Case officially closed'},
];

// ─── Main Screen ──────────────────────────────────────────────────────────────
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
                    icon: Icon(LucideIcons.refreshCw, size: 18,
                        color: isDarkMode ? Colors.white70 : AppColors.primary),
                    onPressed: () => ref.invalidate(breakdownDetailProvider(id)),
                  ),
                ],
              ),
              Expanded(
                child: async.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error:   (e, _) => _buildErrorState(context, e.toString()),
                  data:    (breakdown) => _buildBody(context, ref, breakdown, isDarkMode),
                ),
              ),
            ],
          ),
        ),
      ),
      // ── Conditional Bottom Actions ──────────────────────────────────────────
      bottomNavigationBar: async.whenOrNull(
        data: (breakdown) {
          final user = ApiService.sessionUser;
          if (user?.role == 'ee' && breakdown.status == 'approved') {
            return _AllotContractorButton(incidentId: id);
          } else if (user?.role == 'contractor' && breakdown.status == 'assigned') {
            return _StartWorkButton(breakdown: breakdown);
          } else if (breakdown.statusIndex >= 3) {
            // Assume any authenticated user involved can upload progress if assigned or later
            // (In reality, restrict to assigned contractor or supervising JE)
            return _UploadProgressButton(incidentId: id);
          }
          return const SizedBox.shrink();
        },
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref,
      BreakdownModel breakdown, bool isDarkMode) {
    final statusColor   = AppColors.statusColor(breakdown.status);
    final severityColor = AppColors.severityColor(breakdown.severity);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(breakdownDetailProvider(id)),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status Banner ──────────────────────────────────────────────
            FluentCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              breakdown.displayId,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'REPORTED ON ${DateFormat('dd MMMM yyyy').format(breakdown.createdAt).toUpperCase()}',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                  color: isDarkMode ? Colors.white24 : AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (breakdown.statusIndex < 2) ...[
                        const SizedBox(width: 16),
                        _AutoApprovalTimer(createdAt: breakdown.createdAt, isDarkMode: isDarkMode),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const FluentSectionHeader(title: 'Overview'),
            const SizedBox(height: 16),

            // ── Grid Info ─────────────────────────────────────────────────
            Row(
              children: [
                _buildInfoTile('SEVERITY', breakdown.severity.toUpperCase(), severityColor, isDarkMode),
                const SizedBox(width: 16),
                _buildInfoTile('STATUS', breakdown.status.replaceAll('_', ' ').toUpperCase(), statusColor, isDarkMode),
              ],
            ),
            const SizedBox(height: 16),

            FluentCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _infoRow('Asset ID',   breakdown.reportNumber ?? 'N/A', isDarkMode),
                  const Divider(height: 24),
                  _infoRow('Asset Name', breakdown.assetName ?? 'N/A', isDarkMode),
                  const Divider(height: 24),
                  _infoRow('Category',   breakdown.componentCategory ?? 'N/A', isDarkMode),
                  const Divider(height: 24),
                  _infoRow('Component',  breakdown.componentType ?? 'N/A', isDarkMode),
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
                    style: TextStyle(fontSize: 14,
                        color: isDarkMode ? Colors.white60 : AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),

            if (ApiService.sessionUser?.role == 'contractor' && breakdown.statusIndex >= 3 && breakdown.workOrder != null) ...[
              const SizedBox(height: 32),
              _ExcavationRequirementSection(breakdown: breakdown, isDarkMode: isDarkMode),
            ],

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const FluentSectionHeader(title: 'Progress Timeline'),
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton.icon(
                    onPressed: () async {
                      final nextIndex = (breakdown.statusIndex + 1) % BreakdownModel.statusOrder.length;
                      final nextStatus = BreakdownModel.statusOrder[nextIndex];
                      await ref.read(apiServiceProvider).updateBreakdownStatus(breakdown.id, nextStatus);
                      ref.invalidate(breakdownDetailProvider(breakdown.id));
                      ref.invalidate(myBreakdownsProvider);
                      ref.invalidate(allBreakdownsProvider);
                      ref.invalidate(summaryProvider);
                    },
                    icon: const Icon(LucideIcons.fastForward, size: 14, color: AppColors.primary),
                    label: const Text(
                      'CYCLE STATUS (TEST)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 0.5),
                    ),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                  ),
                ),
              ],
            ),
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

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildInfoTile(String label, String value, Color color, bool isDarkMode) {
    return Expanded(
      child: FluentCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                color: isDarkMode ? Colors.white24 : AppColors.textSecondary, letterSpacing: 0.5)),
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
        Text(label, style: TextStyle(fontSize: 13,
            color: isDarkMode ? Colors.white38 : AppColors.textSecondary, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
            color: highlight ? AppColors.primary : (isDarkMode ? Colors.white : AppColors.textPrimary))),
      ],
    );
  }

  Widget _buildTimeline(int currentIdx, bool isDarkMode) {
    return Column(
      children: List.generate(_progressSteps.length, (i) {
        final step    = _progressSteps[i];
        final isDone   = i <= currentIdx;
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
                      color: isActive
                          ? AppColors.primary
                          : (isDone
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : (isDarkMode ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade200)),
                      border: isActive ? Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 4) : null,
                    ),
                  ),
                  if (i < _progressSteps.length - 1)
                    Container(
                      width: 2, height: 40,
                      color: isDone
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : (isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
                    ),
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
                      color: isActive
                          ? AppColors.primary
                          : (isDone
                              ? (isDarkMode ? Colors.white70 : AppColors.textPrimary)
                              : (isDarkMode ? Colors.white24 : AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(step['desc'] as String,
                      style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.white24 : AppColors.textSecondary)),
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
            onTap: () => _viewFullImage(context, index, breakdown),
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

  void _viewFullImage(BuildContext context, int initialIndex, BreakdownModel breakdown) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: _FullScreenGallery(initialIndex: initialIndex, breakdown: breakdown),
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

// ──────────────────────────────────────────────────────────────────────────────
// UPLOAD PROGRESS BUTTON — static single CTA at the bottom
// ──────────────────────────────────────────────────────────────────────────────
class _UploadProgressButton extends StatelessWidget {
  final String incidentId;
  const _UploadProgressButton({required this.incidentId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161625) : Colors.white;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: isDark ? 0.88 : 0.94),
            border: Border(
              top: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20, 14, 20,
            MediaQuery.of(context).padding.bottom + 14,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WorkProgressUploadScreen(incidentId: incidentId),
                ),
              ),
              icon: const Icon(LucideIcons.uploadCloud, size: 20),
              label: const Text(
                'Upload Progress',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ).copyWith(
                overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// AUTO-APPROVAL TIMER
// ──────────────────────────────────────────────────────────────────────────────
class _AutoApprovalTimer extends StatefulWidget {
  final DateTime createdAt;
  final bool isDarkMode;
  const _AutoApprovalTimer({required this.createdAt, required this.isDarkMode});

  @override
  State<_AutoApprovalTimer> createState() => _AutoApprovalTimerState();
}

class _AutoApprovalTimerState extends State<_AutoApprovalTimer> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    final autoApproveTime = widget.createdAt.add(const Duration(hours: 2));
    final now = DateTime.now();
    _timeLeft = autoApproveTime.isAfter(now) ? autoApproveTime.difference(now) : Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculate());
  }

  void _calculate() {
    final at  = widget.createdAt.add(const Duration(hours: 2));
    final now = DateTime.now();
    final nl  = at.isAfter(now) ? at.difference(now) : Duration.zero;
    if (_timeLeft.inSeconds != nl.inSeconds && mounted) {
      setState(() => _timeLeft = nl);
    }
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.inSeconds == 0) return const SizedBox.shrink();

    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(_timeLeft.inHours);
    final m = two(_timeLeft.inMinutes.remainder(60));
    final s = two(_timeLeft.inSeconds.remainder(60));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.timer, size: 24, color: AppColors.warning),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AUTO-APPROVAL IN',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                      color: widget.isDarkMode ? Colors.white54 : AppColors.textSecondary, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text('$h:$m:$s',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                      color: AppColors.warning,
                      fontFeatures: [FontFeature.tabularFigures()], letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// FULL-SCREEN GALLERY
// ──────────────────────────────────────────────────────────────────────────────
class _FullScreenGallery extends StatefulWidget {
  final int initialIndex;
  final BreakdownModel breakdown;
  const _FullScreenGallery({required this.initialIndex, required this.breakdown});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  void _nextPage() {
    if (_currentIndex < widget.breakdown.mediaUrls.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.breakdown.mediaUrls;
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemCount: urls.length,
          itemBuilder: (_, index) => InteractiveViewer(
            child: Hero(
              tag: urls[index],
              child: GPSImageOverlay(
                imageUrl: urls[index],
                breakdown: widget.breakdown,
                isDarkMode: true,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        if (_currentIndex > 0)
          Positioned(
            left: 20,
            top: MediaQuery.of(context).size.height / 2 - 24,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(icon: const Icon(LucideIcons.chevronLeft, color: Colors.white), onPressed: _previousPage),
            ),
          ),
        if (_currentIndex < urls.length - 1)
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height / 2 - 24,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(icon: const Icon(LucideIcons.chevronRight, color: Colors.white), onPressed: _nextPage),
            ),
          ),
        Positioned(
          top: 40, right: 20,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(icon: const Icon(LucideIcons.x, color: Colors.white, size: 24), onPressed: () => Navigator.pop(context)),
          ),
        ),
        Positioned(
          bottom: 40, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
              child: Text(
                '${_currentIndex + 1} / ${urls.length}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// ALLOT CONTRACTOR BUTTON (For EE Role)
// ──────────────────────────────────────────────────────────────────────────────
class _AllotContractorButton extends StatelessWidget {
  final String incidentId;
  const _AllotContractorButton({required this.incidentId});

  void _showAllotModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AllotWorkModal(breakdownId: incidentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161625) : Colors.white;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: isDark ? 0.88 : 0.94),
            border: Border(
              top: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20, 14, 20,
            MediaQuery.of(context).padding.bottom + 14,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _showAllotModal(context),
              icon: const Icon(LucideIcons.userPlus, size: 20),
              label: const Text(
                'Allot Contractor',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ).copyWith(
                overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// EXCAVATION REQUIREMENT SECTION
// ──────────────────────────────────────────────────────────────────────────────
class _ExcavationRequirementSection extends ConsumerStatefulWidget {
  final BreakdownModel breakdown;
  final bool isDarkMode;

  const _ExcavationRequirementSection({required this.breakdown, required this.isDarkMode});

  @override
  ConsumerState<_ExcavationRequirementSection> createState() => _ExcavationRequirementSectionState();
}

class _ExcavationRequirementSectionState extends ConsumerState<_ExcavationRequirementSection> {
  bool _isExcavationRequired = false;
  bool _isUpdating = false;
  bool _isUploadingCert = false;
  String? _certUrl;

  @override
  void initState() {
    super.initState();
    _isExcavationRequired = widget.breakdown.workOrder?['excavation_required'] ?? false;
    _certUrl = widget.breakdown.workOrder?['path_sammanay_cert_url'];
  }

  Future<void> _toggleRequirement(bool value) async {
    final workOrderId = widget.breakdown.workOrder?['id'];
    if (workOrderId == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await ref.read(apiServiceProvider).updateWorkOrderExcavation(workOrderId, value);
      setState(() {
        _isExcavationRequired = value;
      });
      // Refresh the breakdown to get latest data
      ref.invalidate(breakdownDetailProvider(widget.breakdown.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _uploadCertificate() async {
    final workOrderId = widget.breakdown.workOrder?['id'];
    if (workOrderId == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    setState(() {
      _isUploadingCert = true;
    });

    try {
      final url = await ref.read(apiServiceProvider).uploadPathSammanayCertificate(File(image.path), workOrderId);
      setState(() {
        _certUrl = url;
      });
      ref.invalidate(breakdownDetailProvider(widget.breakdown.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate uploaded successfully'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() {
        _isUploadingCert = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FluentSectionHeader(title: 'Work Requirements'),
        const SizedBox(height: 16),
        FluentCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Excavation Required?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  _isUpdating
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Switch(
                          value: _isExcavationRequired,
                          onChanged: _toggleRequirement,
                          activeColor: AppColors.primary,
                        ),
                ],
              ),
              if (_isExcavationRequired) ...[
                const Divider(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.alertTriangle, color: AppColors.warning, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Path Sammanay Required',
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Apply for repair approval in the Path Sammanay portal and upload the certificate to proceed with the work.',
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.white70 : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse('https://pwd.assam.gov.in/portlet-innerpage/path-sammanay');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not launch Path Sammanay Portal')),
                                );
                              }
                            }
                          },
                          icon: const Icon(LucideIcons.externalLink, size: 16),
                          label: const Text('Open Path Sammanay Portal'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_certUrl != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Certificate Uploaded',
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _isUploadingCert ? null : _uploadCertificate,
                                child: const Text('Update'),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isUploadingCert ? null : _uploadCertificate,
                            icon: _isUploadingCert 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(LucideIcons.uploadCloud, size: 16),
                            label: Text(_isUploadingCert ? 'Uploading...' : 'Upload Certificate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StartWorkButton extends ConsumerStatefulWidget {
  final BreakdownModel breakdown;

  const _StartWorkButton({required this.breakdown});

  @override
  ConsumerState<_StartWorkButton> createState() => _StartWorkButtonState();
}

class _StartWorkButtonState extends ConsumerState<_StartWorkButton> {
  bool _isLoading = false;

  Future<void> _handleStartWork() async {
    final workOrder = widget.breakdown.workOrder;
    if (workOrder == null) return;

    final excavationRequired = workOrder['excavation_required'] == true;
    final certUrl = workOrder['path_sammanay_cert_url'] as String?;

    if (excavationRequired && (certUrl == null || certUrl.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload the Path Sammanay Certificate before starting work.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ApiService.sessionUser;
      if (user == null) throw Exception('User not authenticated');

      await ref.read(apiServiceProvider).startWork(
            widget.breakdown.id,
            workOrder['id'],
            user.id,
          );
          
      ref.invalidate(breakdownDetailProvider(widget.breakdown.id));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work started successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start work: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF161625) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleStartWork,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(LucideIcons.playCircle, size: 20),
            label: Text(
              _isLoading ? 'Starting...' : 'Start Work',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
