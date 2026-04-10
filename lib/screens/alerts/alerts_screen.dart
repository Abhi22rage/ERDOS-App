import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fluent_ui.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FluentBackground(
        child: SafeArea(
          child: Column(
            children: [
              FluentHeader(
                title: 'Alerts & Notifications',
                actions: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      await ref.read(apiServiceProvider).markAllNotificationsRead();
                      ref.invalidate(notificationsProvider);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: notifAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (_, __) => Center(
                    child: Text(
                      'Failed to load notifications',
                      style: TextStyle(color: isDarkMode ? Colors.white38 : AppColors.textSecondary),
                    ),
                  ),
                  data: (notifications) {
                    if (notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.bellRing,
                                size: 64,
                                color: isDarkMode ? AppColors.primary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.1),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'ALL CLEAR',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: isDarkMode ? Colors.white24 : AppColors.textSecondary,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No new notifications yet',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.white38 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async => ref.invalidate(notificationsProvider),
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, i) {
                          final n = notifications[i];
                          final isRead = n['is_read'] == true;
                          final createdAt = n['created_at'] != null ? DateTime.tryParse(n['created_at']) : null;
                          
                          return GestureDetector(
                            onTap: () async {
                              await ref.read(apiServiceProvider).markNotificationRead(n['id'].toString());
                              ref.invalidate(notificationsProvider);
                            },
                            child: FluentCard(
                              padding: const EdgeInsets.all(18),
                              color: isRead 
                                  ? (isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white)
                                  : AppColors.primary.withOpacity(isDarkMode ? 0.1 : 0.06),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isRead
                                          ? (isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFF0F3F9))
                                          : AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _notifIcon(n['type']),
                                        size: 20,
                                        color: isRead 
                                            ? (isDarkMode ? Colors.white38 : AppColors.textSecondary)
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n['title'] ?? 'Notification',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                                                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (n['message'] != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            n['message'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              height: 1.4,
                                              color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
                                              fontWeight: isRead ? FontWeight.w400 : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                        if (createdAt != null) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            DateFormat('dd MMM, hh:mm a').format(createdAt),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
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

  IconData _notifIcon(String? type) {
    switch (type) {
      case 'breakdown':
        return LucideIcons.alertTriangle;
      case 'approval':
        return LucideIcons.checkCircle;
      case 'task':
        return LucideIcons.clipboardList;
      case 'system':
        return LucideIcons.settings;
      default:
        return LucideIcons.bell;
    }
  }
}
