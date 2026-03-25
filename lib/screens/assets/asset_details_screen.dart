import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fluent_ui.dart';

class AssetDetailsScreen extends StatelessWidget {
  final String id;

  const AssetDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FluentBackground(
        child: SafeArea(
          child: Column(
            children: [
              const FluentHeader(title: 'Asset Details'),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // ── Main Header Card ──
                      FluentCard(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.box, size: 48, color: AppColors.primary),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              id,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'UNDER DEVELOPMENT',
                                style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      const FluentSectionHeader(title: 'Asset Specifications'),
                      const SizedBox(height: 16),

                      // ── Mock Specifications ──
                      FluentCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildSpecRow('TYPE', 'PRODUCTION ASSET', isDarkMode),
                            const Divider(height: 32),
                            _buildSpecRow('STATUS', 'ACTIVE', isDarkMode, color: AppColors.success),
                            const Divider(height: 32),
                            _buildSpecRow('LOCATION', 'DISPUR WSS AREA', isDarkMode),
                            const Divider(height: 32),
                            _buildSpecRow('INSTALLED', '12 OCT 2024', isDarkMode),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),
                      // ── Action Row ──
                      Text(
                        'This asset module is currently being integrated into the live monitoring system.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white24 : AppColors.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(LucideIcons.chevronLeft, size: 18),
                          label: const Text('BACK TO INVENTORY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            foregroundColor: isDarkMode ? Colors.white70 : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, bool isDarkMode, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white24 : AppColors.textSecondary, letterSpacing: 0.5)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color ?? (isDarkMode ? Colors.white : AppColors.textPrimary))),
      ],
    );
  }
}
