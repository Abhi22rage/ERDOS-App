import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fluent_ui.dart';

class AssetsScreen extends ConsumerWidget {
  final String? type;
  const AssetsScreen({super.key, this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetsProvider(type));
    final typeLabel = _typeLabel(type);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FluentBackground(
        child: SafeArea(
          child: Column(
            children: [
              FluentHeader(title: '$typeLabel Assets'),
              Expanded(
                child: assetsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => _buildErrorState(e.toString()),
                  data: (assets) {
                    if (assets.isEmpty) {
                      return _buildEmptyState(isDarkMode, typeLabel);
                    }
                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async => ref.invalidate(assetsProvider(type)),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                        itemCount: assets.length,
                        itemBuilder: (_, i) {
                          final a = assets[i];
                          return _AssetCard(asset: a, isDarkMode: isDarkMode);
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

  Widget _buildEmptyState(bool isDarkMode, String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(isDarkMode ? 0.08 : 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.boxSelect,
              size: 64,
              color: isDarkMode ? AppColors.primary.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'DATA NOT FOUND',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white24 : AppColors.textSecondary,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No recorded records for $label',
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text('Error loading assets: $error', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'wtp': return 'WTP';
      case 'boosting_station': return 'Boosting Station';
      case 'pipeline': return 'Pipeline';
      default: return 'All';
    }
  }
}

class _AssetCard extends StatelessWidget {
  final Map<String, dynamic> asset;
  final bool isDarkMode;

  const _AssetCard({required this.asset, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final type = asset['type'] as String?;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => context.push('/assets/${asset['id']}'),
        child: FluentCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(_typeIcon(type), size: 24, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset['name'] ?? 'Unknown Asset',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                    ),
                    if (asset['location'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 12, color: isDarkMode ? Colors.white38 : AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              asset['location'],
                              style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white38 : AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 16, color: isDarkMode ? Colors.white10 : Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'wtp': return LucideIcons.droplets;
      case 'boosting_station': return LucideIcons.wrench;
      case 'pipeline': return LucideIcons.activity;
      default: return LucideIcons.box;
    }
  }
}
