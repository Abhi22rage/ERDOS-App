import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/fluent_ui.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.8, curve: Curves.easeIn));
    _scale = CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack));
    _tryNavigate();
  }

  Future<void> _tryNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final user = await ref.read(authProvider.future);
    if (!mounted) return;
    if (user != null) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FluentBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Premium Logo Circle
              ScaleTransition(
                scale: _scale,
                child: FadeTransition(
                  opacity: _fade,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 32,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('⚡', style: TextStyle(fontSize: 60)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Animated Text
              FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    const Text(
                      'PHE EMERGENCY',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Repair Management System',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 80),
              
              // Minimal Loader
              FadeTransition(
                opacity: _fade,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
