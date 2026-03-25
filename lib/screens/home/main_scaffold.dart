import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  final _tabs = [
    _NavTab(label: 'Home', icon: LucideIcons.home, path: '/home'),
    _NavTab(label: 'Tasks', icon: LucideIcons.clipboardList, path: '/my-tasks'),
    _NavTab(label: 'Alerts', icon: LucideIcons.bell, path: '/alerts'),
    _NavTab(label: 'Profile', icon: LucideIcons.user, path: '/profile'),
  ];

  int _getSelectedIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/my-tasks')) return 1;
    if (location.startsWith('/alerts')) return 2;
    if (location.startsWith('/profile')) return 3;
    if (location.startsWith('/schemes')) return 0;
    return 0;
  }

  void _onTap(int index) {
    if (_tabs[index].path == GoRouterState.of(context).uri.path) return;
    context.go(_tabs[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final int selectedIndex = _getSelectedIndex(location);
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      extendBody: true, // Allows child to scroll behind the glass bar
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.85),
          border: Border(top: BorderSide(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), width: 0.5)),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: SafeArea(
              child: SizedBox(
                height: 65,
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final isActive = selectedIndex == i;
                    final activeColor = isDarkMode ? Colors.white : AppColors.primary;
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onTap(i),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _tabs[i].icon,
                                size: 20,
                                color: isActive ? activeColor : (isDarkMode ? Colors.white24 : AppColors.tabInactive),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _tabs[i].label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                                color: isActive ? activeColor : (isDarkMode ? Colors.white24 : AppColors.tabInactive),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final String label;
  final IconData icon;
  final String path;
  const _NavTab({required this.label, required this.icon, required this.path});
}
