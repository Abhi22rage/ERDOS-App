import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/breakdown_model.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gps_image_overlay.dart';

// ── Work stages mapped to the incident's 7-step pipeline ─────────────────────
const _workStages = [
  {'key': 'reported',         'label': 'Stage 1 – Site Inspection',  'desc': 'Initial site visit & damage assessment'},
  {'key': 'pending_approval', 'label': 'Stage 2 – Excavation',        'desc': 'Ground excavation & pipe exposure'},
  {'key': 'assigned',         'label': 'Stage 3 – Repair Work',       'desc': 'Structural repair & fixing'},
  {'key': 'in_progress',     'label': 'Stage 4 – Testing',            'desc': 'Pressure & quality testing'},
  {'key': 'completed',       'label': 'Stage 5 – Restoration',        'desc': 'Site restoration & cleanup'},
  {'key': 'closed',          'label': 'Stage 6 – Final Inspection',   'desc': 'Final sign-off & documentation'},
];

// ─────────────────────────────────────────────────────────────────────────────
class WorkProgressUploadScreen extends ConsumerStatefulWidget {
  final String incidentId;
  const WorkProgressUploadScreen({super.key, required this.incidentId});

  @override
  ConsumerState<WorkProgressUploadScreen> createState() =>
      _WorkProgressUploadScreenState();
}

class _WorkProgressUploadScreenState
    extends ConsumerState<WorkProgressUploadScreen> {
  // Per-stage upload state: stageKey → {uploading, done, total, urls, error}
  final Map<String, _StageState> _stageStates = {};

  _StageState _stateFor(String key) =>
      _stageStates.putIfAbsent(key, () => _StageState());

  Future<void> _pickAndUpload(String stageKey, String stageLabel,
      {required bool isCamera, required bool isVideo}) async {
    final picker = ImagePicker();
    List<XFile> picked = [];

    try {
      if (isVideo) {
        final v = await picker.pickVideo(
            source: isCamera ? ImageSource.camera : ImageSource.gallery);
        if (v != null) picked = [v];
      } else if (isCamera) {
        final p = await picker.pickImage(
            source: ImageSource.camera, imageQuality: 85);
        if (p != null) picked = [p];
      } else {
        picked = await picker.pickMultiImage(imageQuality: 85);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _stateFor(stageKey).error = 'Picker error: $e');
      }
      return;
    }

    if (picked.isEmpty) return;

    final files = <({String path, String name, Uint8List bytes})>[];
    for (final xf in picked) {
      files.add((path: xf.path, name: xf.name, bytes: await xf.readAsBytes()));
    }

    if (mounted) {
      setState(() {
        final s = _stateFor(stageKey);
        s.uploading = true;
        s.done = 0;
        s.total = files.length;
        s.error = null;
      });
    }

    await ref.read(apiServiceProvider).uploadStageMedia(
          breakdownId: widget.incidentId,
          stageLabel: stageLabel,
          files: files,
          onProgress: (done, total) {
            if (mounted) {
              setState(() {
                final s = _stateFor(stageKey);
                s.done = done;
                s.total = total;
              });
            }
          },
          onError: (err) {
            if (mounted) {
              setState(() {
                final s = _stateFor(stageKey);
                s.uploading = false;
                s.error = err;
              });
            }
          },
          onComplete: (urls) {
            if (mounted) {
              setState(() {
                final s = _stateFor(stageKey);
                s.uploading = false;
                s.done = 0;
                s.total = 0;
                // Add the REAL Supabase URLs to the local gallery so they show up immediately
                s.localUrls.addAll(urls);
              });
              // Invalidate so the parent detail screen also refreshes
              ref.invalidate(breakdownDetailProvider(widget.incidentId));
            }
          },
        );
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Future<void> _handleDeleteMedia({
    required String stageKey,
    required int stageIdx,
    required RepairMediaModel media,
  }) async {
    final breakdown = ref.read(breakdownDetailProvider(widget.incidentId)).value;
    if (breakdown == null) return;

    final currentIdx = breakdown.statusIndex;

    // If deleting from a PREVIOUS stage, show warning and revert progress
    if (stageIdx < currentIdx) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          title: const Text('Revert Progress?'),
          content: Text(
            'Deleting media from an earlier stage will revert the incident status back to "${_workStages[stageIdx]['label']}".\n\n'
            'WARNING: This will permanently delete ALL media uploaded in subsequent stages.',
            style: TextStyle(
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Revert & Delete'),
            ),
          ],
        ),
      );

      if (proceed != true) return;

      try {
        await ref.read(apiServiceProvider).revertIncidentToStage(
              breakdownId: breakdown.id,
              targetStatus: BreakdownModel.statusOrder[stageIdx],
              deletedMediaId: media.id,
              deletedMediaUrl: media.mediaUrl,
            );
        ref.invalidate(breakdownDetailProvider(widget.incidentId));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    } else {
      // Normal deletion for current or future stages
      try {
        await ref
            .read(apiServiceProvider)
            .deleteRepairMedia(media.id, media.mediaUrl);
        ref.invalidate(breakdownDetailProvider(widget.incidentId));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _handleDeleteLocalMedia(String stageKey, String url) async {
    final confirmed = await _showDeleteConfirm();
    if (!confirmed) return;

    // Delete from storage (it's a Supabase URL even if mock)
    await ref.read(apiServiceProvider).deleteMediaByUrl(url);

    if (mounted) {
      setState(() {
        final s = _stateFor(stageKey);
        s.localUrls.remove(url);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preview removed')),
      );
    }
  }

  void _showFullMedia(BuildContext context, String url, bool isVideo, BreakdownModel breakdown) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 120),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Media Container
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: isVideo 
                      ? Container(
                          width: double.infinity,
                          height: 300,
                          color: Colors.black26,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.playCircle, size: 80, color: Colors.white54),
                                SizedBox(height: 16),
                                Text('Video playback not implemented', style: TextStyle(color: Colors.white54)),
                              ],
                            ),
                          ),
                        )
                      : GPSImageOverlay(
                          imageUrl: url, 
                          breakdown: breakdown, 
                          isDarkMode: true,
                          fit: BoxFit.contain,
                        ),
                  ),
                ),
              ),

              // Close Button (Floating top-right)
              Positioned(
                top: -12,
                right: -12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.card,
                    ),
                    child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                  ),
                ),
              ),

              // Hint text inside the dialog
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Pinch to zoom',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _showDeleteConfirm() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Media?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(breakdownDetailProvider(widget.incidentId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF5F6FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(isDark),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (breakdown) => _buildBody(context, breakdown, isDark),
      ),
      bottomNavigationBar: async.whenData(
        (breakdown) => _buildBottomBar(context, breakdown, isDark),
      ).value,
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 22),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Work Progress Upload',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BreakdownModel breakdown, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Current Status Card ──────────────────────────────────────────
          _CurrentStatusCard(breakdown: breakdown, isDark: isDark),
          const SizedBox(height: 28),

          // ── Section Header ───────────────────────────────────────────────
          const Text(
            'Work Progress',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4),
          ),
          const SizedBox(height: 16),

          // ── Stage Cards ──────────────────────────────────────────────────
          ..._workStages.asMap().entries.map((entry) {
            final idx = entry.key;
            final stage = entry.value;
            final key = stage['key']!;
            final label = stage['label']!;
            final desc = stage['desc']!;
            final stageStatus = _resolveStageStatus(idx, breakdown.statusIndex);
            final state = _stateFor(key);

            // Filter remote media for this stage
            final stageEnum = _mapLabelToEnum(label);
            final remoteMedia = breakdown.repairMedia
                .where((m) => m.stage == stageEnum)
                .toList();

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
                child: _StageCard(
                  stageLabel: label,
                  stageDesc: desc,
                  stageStatus: stageStatus,
                  stateData: state,
                  remoteMedia: remoteMedia,
                  breakdown: breakdown,
                  isDark: isDark,
                  onUploadTap: () => _showUploadOptions(context, key, label),
                  onDeleteLocal: (url) => _handleDeleteLocalMedia(key, url),
                  onDeleteRemote: (m) => _handleDeleteMedia(
                    stageKey: key,
                    stageIdx: idx,
                    media: m,
                  ),
                  onMediaTap: (url, isVideo) => _showFullMedia(context, url, isVideo, breakdown),
                ),
            );
          }),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  /// Maps the UI label to the DB enum value for filtering repair_media
  String _mapLabelToEnum(String label) {
    final slug = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    const map = {
      'stage_1_site_inspection':  'damage_report',
      'stage_2_excavation':       'excavation',
      'stage_3_repair_work':      'repair_in_progress',
      'stage_4_testing':          'completion',
      'stage_5_restoration':      'road_restoration',
      'stage_6_final_inspection': 'inspection',
    };
    return map[slug] ?? 'damage_report';
  }

  /// Resolves display status for each stage card based on the current incident status
  String _resolveStageStatus(int stageIdx, int currentStatusIdx) {
    if (stageIdx < currentStatusIdx) return 'complete';
    if (stageIdx == currentStatusIdx) return 'in_progress';
    return 'pending';
  }

  void _showUploadOptions(BuildContext context, String stageKey, String stageLabel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _UploadOptionsSheet(
        isDark: isDark,
        onCamera: () {
          Navigator.pop(context);
          _pickAndUpload(stageKey, stageLabel, isCamera: true, isVideo: false);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickAndUpload(stageKey, stageLabel, isCamera: false, isVideo: false);
        },
        onVideo: () {
          Navigator.pop(context);
          _pickAndUpload(stageKey, stageLabel, isCamera: false, isVideo: true);
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, BreakdownModel breakdown, bool isDark) {
    final bgColor = isDark ? const Color(0xFF161625) : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final currentIdx = breakdown.statusIndex;
                  if (currentIdx == -1) return;

                  int targetIdx = currentIdx;

                  // Scan forward to see how many stages are completed based on media presence
                  for (int i = currentIdx; i < _workStages.length; i++) {
                    final stage = _workStages[i];
                    final key = stage['key']!;
                    final label = stage['label']!;
                    final stageEnum = _mapLabelToEnum(label);

                    // Check if media exists for this stage
                    final state = _stateFor(key);
                    final hasLocal = state.localUrls.isNotEmpty;
                    final hasRemote = breakdown.repairMedia.any((m) => m.stage == stageEnum);

                    if (hasLocal || hasRemote) {
                      targetIdx = i + 1; // Completed this stage, move target to next status
                    } else {
                      break; // Missing media, cannot progress further
                    }
                  }

                  if (targetIdx == currentIdx) {
                    final label = _workStages[currentIdx]['label']!;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please upload media for $label before saving.'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    return;
                  }

                  if (targetIdx < BreakdownModel.statusOrder.length) {
                    final nextStatus = BreakdownModel.statusOrder[targetIdx];
                    try {
                      await ref.read(apiServiceProvider).updateBreakdownStatus(breakdown.id, nextStatus);
                      ref.invalidate(breakdownDetailProvider(breakdown.id));
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Progress saved! Current Status: ${nextStatus.replaceAll('_', ' ').toUpperCase()}'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save progress: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  } else if (currentIdx >= _workStages.length) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All work stages are already completed.')),
                      );
                    }
                  }
                },
                icon: const Icon(LucideIcons.save, size: 20),
                label: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                  foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: breakdown.statusIndex == 6
                    ? () {
                        if (breakdown.status == 'certified') {
                          context.push('/certificate-report/${breakdown.id}');
                        } else {
                          context.push('/apply-certificate/${breakdown.id}');
                        }
                      }
                    : null,
                icon: Icon(breakdown.status == 'certified' ? LucideIcons.fileCheck : LucideIcons.fileSignature, size: 20),
                label: Text(
                  breakdown.status == 'certified' ? 'View Certificate' : 'Apply Certificate',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                  disabledForegroundColor:
                      isDark ? Colors.white24 : Colors.grey.shade400,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Current Status Card
// ──────────────────────────────────────────────────────────────────────────────
class _CurrentStatusCard extends StatelessWidget {
  final BreakdownModel breakdown;
  final bool isDark;
  const _CurrentStatusCard({required this.breakdown, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.statusColor(breakdown.status);
    final statusIdx = breakdown.statusIndex;
    final progress = statusIdx == -1 ? 0.0 : statusIdx / 6.0;
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      breakdown.displayId,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      breakdown.title,
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.w900, 
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(LucideIcons.clock, size: 12, color: isDark ? Colors.white38 : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMM yyyy · hh:mm a').format(breakdown.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white38 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  breakdown.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),

          if (breakdown.description != null && breakdown.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              breakdown.description!,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 16),

          // Progress bar
          Row(
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white38 : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}


// ──────────────────────────────────────────────────────────────────────────────
// Stage Card
// ──────────────────────────────────────────────────────────────────────────────
class _StageCard extends StatelessWidget {
  final String stageLabel;
  final String stageDesc;
  final String stageStatus; // 'complete' | 'in_progress' | 'pending'
  final _StageState stateData;
  final List<RepairMediaModel> remoteMedia;
  final BreakdownModel breakdown;
  final bool isDark;
  final VoidCallback onUploadTap;
  final Function(String) onDeleteLocal;
  final Function(RepairMediaModel) onDeleteRemote;
  final Function(String, bool) onMediaTap;

  const _StageCard({
    required this.stageLabel,
    required this.stageDesc,
    required this.stageStatus,
    required this.stateData,
    required this.remoteMedia,
    required this.breakdown,
    required this.isDark,
    required this.onUploadTap,
    required this.onDeleteLocal,
    required this.onDeleteRemote,
    required this.onMediaTap,
  });

  Color get _statusColor {
    switch (stageStatus) {
      case 'complete':   return const Color(0xFF2E7D32);
      case 'in_progress': return AppColors.primary;
      default:           return const Color(0xFFF57C00);
    }
  }

  String get _statusLabel {
    switch (stageStatus) {
      case 'complete':   return 'Complete';
      case 'in_progress': return 'In Progress';
      default:           return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stageLabel,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        stageDesc,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Media Preview Area ─────────────────────────────────────────────
          _MediaPreviewArea(
            localUrls: stateData.localUrls,
            remoteMedia: remoteMedia,
            breakdown: breakdown,
            isDark: isDark,
            onDeleteLocal: onDeleteLocal,
            onDeleteRemote: onDeleteRemote,
            onMediaTap: onMediaTap,
          ),

          // ── Upload Progress Bar (when uploading) ──────────────────────────
          if (stateData.uploading)
            _UploadingBar(done: stateData.done, total: stateData.total, isDark: isDark),

          // ── Error Message ─────────────────────────────────────────────────
          if (stateData.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                stateData.error!,
                style: const TextStyle(fontSize: 11, color: AppColors.error),
              ),
            ),

          // ── Upload Button ─────────────────────────────────────────────────
          _UploadButton(
            uploading: stateData.uploading,
            isDark: isDark,
            onTap: stateData.uploading ? null : onUploadTap,
          ),
        ],
      ),
    );
  }
}

// ─── Media Preview Area ───────────────────────────────────────────────────────
class _MediaPreviewArea extends StatelessWidget {
  final List<String> localUrls;
  final List<RepairMediaModel> remoteMedia;
  final BreakdownModel breakdown;
  final bool isDark;
  final Function(String) onDeleteLocal;
  final Function(RepairMediaModel) onDeleteRemote;
  final Function(String, bool) onMediaTap;

  const _MediaPreviewArea({
    required this.localUrls,
    required this.remoteMedia,
    required this.breakdown,
    required this.isDark,
    required this.onDeleteLocal,
    required this.onDeleteRemote,
    required this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100;

    final remoteUrls = remoteMedia.map((m) => m.mediaUrl).toSet();
    final List<({String url, RepairMediaModel? model, bool isLocal, String status})> items = [
      ...localUrls
          .where((u) => !remoteUrls.contains(u))
          .map((u) => (url: u, model: null as RepairMediaModel?, isLocal: true, status: 'pending')),
      ...remoteMedia.map((m) => (url: m.mediaUrl, model: m as RepairMediaModel?, isLocal: false, status: m.status)),
    ];

    if (items.isEmpty) {
      // Empty placeholder
      return Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.imageOff,
                size: 32,
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
              const SizedBox(height: 8),
              Text(
                'No media uploaded yet',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Horizontal scrollable thumbnails
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: items.length,
        itemBuilder: (_, idx) {
          final item = items[idx];
          final url = item.url;
          final isNetwork = url.startsWith('http') || url.startsWith('blob');
          final isVideo = url.toLowerCase().contains('.mp4') || url.toLowerCase().contains('.mov');
          
          return GestureDetector(
            onTap: () => onMediaTap(url, isVideo),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  isNetwork
                      ? Image.network(
                          url,
                          width: 240,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 240, height: 160, color: bgColor,
                            child: const Icon(LucideIcons.image, color: Colors.white24, size: 30),
                          ),
                        )
                      : Image.network(
                          url,
                          width: 240,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 240, height: 160, color: bgColor,
                            child: const Icon(LucideIcons.image, color: AppColors.primary, size: 30),
                          ),
                        ),
                
                // Play overlay for videos
                if (isVideo)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(LucideIcons.playCircle, color: Colors.white, size: 40),
                      ),
                    ),
                  ),

                // DELETE BUTTON
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      if (item.isLocal) {
                        onDeleteLocal(item.url);
                      } else if (item.model != null) {
                        onDeleteRemote(item.model!);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(LucideIcons.trash2, color: Colors.white, size: 14),
                    ),
                  ),
                ),

                // STATUS BADGE
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.status == 'approved' 
                          ? Colors.green.withValues(alpha: 0.8) 
                          : item.status == 'rejected' 
                              ? Colors.red.withValues(alpha: 0.8) 
                              : Colors.orange.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.status == 'approved' 
                              ? LucideIcons.checkCircle2 
                              : item.status == 'rejected' 
                                  ? LucideIcons.xCircle 
                                  : LucideIcons.clock,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        },
      ),
    );
  }
}

// ─── Uploading Bar ────────────────────────────────────────────────────────────
class _UploadingBar extends StatelessWidget {
  final int done;
  final int total;
  final bool isDark;
  const _UploadingBar({required this.done, required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? done / total : 0.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Uploading $done / $total files',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upload Button ────────────────────────────────────────────────────────────
class _UploadButton extends StatelessWidget {
  final bool uploading;
  final bool isDark;
  final VoidCallback? onTap;
  const _UploadButton({required this.uploading, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: uploading
                ? AppColors.primary.withValues(alpha: 0.06)
                : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: uploading
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                uploading ? LucideIcons.loader : LucideIcons.uploadCloud,
                size: 18,
                color: uploading
                    ? AppColors.primary
                    : (isDark ? Colors.white60 : AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Text(
                uploading ? 'Uploading…' : 'Upload Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: uploading
                      ? AppColors.primary
                      : (isDark ? Colors.white60 : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Upload Options Bottom Sheet
// ──────────────────────────────────────────────────────────────────────────────
class _UploadOptionsSheet extends StatelessWidget {
  final bool isDark;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onVideo;

  const _UploadOptionsSheet({
    required this.isDark,
    required this.onCamera,
    required this.onGallery,
    required this.onVideo,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Select Source', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _SheetOption(icon: LucideIcons.camera,      label: 'Camera',  sublabel: 'Take photo', isDark: isDark, onTap: onCamera)),
              const SizedBox(width: 12),
              Expanded(child: _SheetOption(icon: LucideIcons.image,       label: 'Gallery', sublabel: 'Multi-select', isDark: isDark, isPrimary: true, onTap: onGallery)),
              const SizedBox(width: 12),
              Expanded(child: _SheetOption(icon: LucideIcons.video,       label: 'Video',   sublabel: 'Pick video', isDark: isDark, onTap: onVideo)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool isDark;
  final bool isPrimary;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.isDark,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0055BB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrimary ? null : (isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
          boxShadow: isPrimary ? AppShadows.button : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: isPrimary ? Colors.white : (isDark ? Colors.white60 : AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isPrimary ? Colors.white : (isDark ? Colors.white : AppColors.textPrimary))),
            const SizedBox(height: 2),
            Text(sublabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isPrimary ? Colors.white70 : (isDark ? Colors.white38 : AppColors.textSecondary))),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// State holder per stage
// ──────────────────────────────────────────────────────────────────────────────
class _StageState {
  bool uploading = false;
  int done = 0;
  int total = 0;
  String? error;
  List<String> localUrls = [];
}
