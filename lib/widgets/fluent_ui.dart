import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// ─── Fluent Background ───
/// Provides the signature decorative blobs and theme-aware surface.
class FluentBackground extends StatelessWidget {
  final Widget child;
  const FluentBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: isDarkMode ? const Color(0xFF0F1419) : const Color(0xFFF6F8FF),
          ),
        ),
        Positioned(
          top: -100,
          right: -80,
          child: _decorativeCircle(280, AppColors.primary.withValues(alpha: isDarkMode ? 0.12 : 0.08)),
        ),
        Positioned(
          bottom: 200,
          left: -100,
          child: _decorativeCircle(320, AppColors.primaryLight.withValues(alpha: isDarkMode ? 0.08 : 0.05)),
        ),
        Positioned.fill(child: child),
      ],
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
}

/// ─── Fluent Card ───
/// A glassmorphism / elevated card with standard blur and radius.
class FluentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;

  const FluentCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: color ?? (isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.white),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// ─── Fluent Header ───
/// Premium title bar with modern back button.
class FluentHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;

  const FluentHeader({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          if (showBackButton && (context.canPop() || onBack != null)) ...[
            GestureDetector(
              onTap: onBack ?? () => context.pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.chevronLeft,
                  size: 20,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

/// ─── Fluent Section Header ───
class FluentSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  const FluentSectionHeader({super.key, required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: isDarkMode ? Colors.white38 : AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white38 : AppColors.textSecondary.withValues(alpha: 0.5),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

/// ─── Fluent Dialog ───
class FluentDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const FluentDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(content, style: TextStyle(color: isDarkMode ? Colors.white70 : AppColors.textSecondary, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: onCancel ?? () => Navigator.pop(context),
            child: Text(cancelLabel, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

/// ─── Fluent Image Viewer ───
class FluentImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? title;

  const FluentImageViewer({super.key, required this.imageUrl, this.title});

  static void show(BuildContext context, {required String imageUrl, String? title}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return FadeTransition(
          opacity: anim1,
          child: FluentImageViewer(imageUrl: imageUrl, title: title),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Tap to dismiss barrier
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: size.width,
                height: size.height,
                color: Colors.transparent,
              ),
            ),
            
            // The Image Card
            Container(
              width: size.width * 0.85,
              height: size.width * 0.85, // Square card
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  color: Theme.of(context).cardColor,
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.0,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        LucideIcons.imageOff,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Close Button Overlay
            Positioned(
              top: (size.height - size.width * 0.85) / 2 - 60,
              right: (size.width - size.width * 0.85) / 2,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.x, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
