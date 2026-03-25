import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final authState = ref.watch(authProvider);
    final summaryAsync = ref.watch(summaryProvider);
    final user = authState.asData?.value;
    final isDarkMode = theme.brightness == Brightness.dark;

    final quickNavigation = [
      _MenuCard('My Tasks', LucideIcons.clipboardList, AppColors.primary,
          '/my-tasks'),
      _MenuCard('Schemes', LucideIcons.layout, Colors.deepPurple, '/schemes'),
      _MenuCard(
          'Contractors', LucideIcons.users, Colors.orange, '/contractors'),
      _MenuCard('Reports', LucideIcons.barChart3, Colors.green, '/reports'),
    ];

    final infrastructure = [
      _QuickItem('Water Treatment Plants', LucideIcons.droplets,
          '/schemes?center=Dispur WSS&asset=Water Treatment Plant'),
      _QuickItem('Boosting Stations', LucideIcons.wrench,
          '/assets?type=boosting_station'),
      _QuickItem('Pipe Lines', LucideIcons.activity, '/assets?type=pipeline'),
    ];

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F1419) : const Color(0xFFF6F8FF),
      body: Stack(
        children: [
          // ─── Fluent Background Blobs ───
          Positioned(
            top: -100,
            right: -80,
            child: _decorativeCircle(
                280, AppColors.primary.withOpacity(isDarkMode ? 0.12 : 0.08)),
          ),
          Positioned(
            bottom: 200,
            left: -100,
            child: _decorativeCircle(320,
                AppColors.primaryLight.withOpacity(isDarkMode ? 0.08 : 0.05)),
          ),

          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(summaryProvider),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ─── Stylish Top Bar ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      child: Row(
                        children: [
                          _buildProfileBadge(user, isDarkMode),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, Commander',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Mr. ${user?.name ?? 'User'}',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildCircleAction(
                            icon:
                                isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                            onTap: () =>
                                ref.read(themeProvider.notifier).toggle(),
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(width: 10),
                          _buildCircleAction(
                            icon: LucideIcons.bell,
                            onTap: () => context.push('/alerts'),
                            isDarkMode: isDarkMode,
                            hasNotification: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Hero Section: Raise Issue ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildHeroCTA(context),
                    ),
                  ),

                  // ─── Real-time Stats (Interactive Pannel)───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
                      child: summaryAsync.when(
                        data: (s) => Row(
                          children: [
                            _StatCard(
                                count: s['activeBreakdowns'] ?? 0,
                                label: 'Active',
                                icon: LucideIcons.activity,
                                color: AppColors.primary),
                            const SizedBox(width: 12),
                            _StatCard(
                                count: s['pendingApprovals'] ?? 0,
                                label: 'Pending',
                                icon: LucideIcons.clock,
                                color: Colors.orange),
                            const SizedBox(width: 12),
                            _StatCard(
                                count: s['completedBreakdowns'] ?? 0,
                                label: 'Resolved',
                                icon: LucideIcons.checkCircle,
                                color: Colors.green),
                          ],
                        ),
                        loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                        error: (e, _) => SizedBox(
                          height: 80,
                          child: Center(
                            child: Text(
                              'Stats currently unavailable',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.white24 : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ─── Main Navigation Actions ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child:
                          _buildSectionHeader('Operations Center', isDarkMode),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.3,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final card = quickNavigation[index];
                          return _buildMenuCard(context, card, isDarkMode);
                        },
                        childCount: quickNavigation.length,
                      ),
                    ),
                  ),

                  // ─── Infrastructure Section ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                      child: _buildSectionHeader(
                          'Infrastructure Assets', isDarkMode),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = infrastructure[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildInfrastructureItem(
                                context, item, isDarkMode),
                          );
                        },
                        childCount: infrastructure.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── UI Component Builders ───

  Widget _buildProfileBadge(user, bool isDarkMode) {
    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: Stack(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Icon(
                _getRoleIcon(user?.role),
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool hasNotification = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: isDarkMode ? Colors.white70 : AppColors.textPrimary),
            if (hasNotification)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isDarkMode ? Colors.black : Colors.white,
                        width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCTA(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/raise-issue'),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFC62828)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(LucideIcons.zap,
                    size: 140, color: Colors.white.withOpacity(0.1)),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'EMERGENCY RESPONSE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'RAISE AN ISSUE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Report infrastructure breakdown instantly',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        Icon(LucideIcons.arrowRight,
            size: 18, color: isDarkMode ? Colors.white30 : Colors.black26),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, _MenuCard card, bool isDarkMode) {
    return GestureDetector(
      onTap: () => context.push(card.route),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: card.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(card.icon, size: 28, color: card.color),
            ),
            const SizedBox(height: 12),
            Text(
              card.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.9)
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfrastructureItem(
      BuildContext context, _QuickItem item, bool isDarkMode) {
    return GestureDetector(
      onTap: () => context.push(item.route),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, size: 24, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.9)
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 18,
                color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _decorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  IconData _getRoleIcon(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return LucideIcons.shieldCheck;
      case 'ee':
      case 'se':
      case 'ce':
      case 'addl_ce':
      case 'ae':
      case 'aee':
      case 'je':
        return LucideIcons.hardHat;
      case 'khalasi':
      case 'jalmitra':
        return LucideIcons.droplets;
      case 'contractor':
        return LucideIcons.briefcase;
      case 'finance':
        return LucideIcons.banknote;
      default:
        return LucideIcons.user;
    }
  }
}

class _StatCard extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isDarkMode ? Colors.white38 : AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  const _MenuCard(this.title, this.icon, this.color, this.route);
}

class _QuickItem {
  final String label;
  final IconData icon;
  final String route;
  const _QuickItem(this.label, this.icon, this.route);
}
