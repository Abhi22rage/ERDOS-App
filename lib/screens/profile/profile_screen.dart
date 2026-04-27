import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fluent_ui.dart';
import '../../widgets/edit_profile_modal.dart';
import '../../widgets/success_popup.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.asData?.value;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: FluentBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── Modern App Bar / Header ───
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient Background with rounded bottom
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.8),
                            AppColors.primaryDark,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                    ),
                    // Profile Content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        // Avatar with ring
                        _buildAvatar(context, ref, authState, user, isDarkMode),
                        const SizedBox(height: 16),
                        Text(
                          user?.displayName ?? (authState.isLoading ? 'Updating...' : 'Loading Profile...'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildRoleBadge(user),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── Profile Content ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Account Section ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const FluentSectionHeader(
                            title: 'ACCOUNT INFORMATION',
                            icon: LucideIcons.user),
                        if (user != null)
                          TextButton.icon(
                            onPressed: () =>
                                showEditProfileModal(context, ref, user),
                            icon: const Icon(LucideIcons.edit2, size: 14),
                            label: const Text('EDIT',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FluentCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _settingsTile(
                            icon: LucideIcons.user,
                            title: 'Full Name',
                            value: user?.name ?? 'Not provided',
                            color: Colors.blue,
                            isDarkMode: isDarkMode,
                          ),
                          _settingsTile(
                            icon: LucideIcons.phone,
                            title: 'Mobile Number',
                            value: user?.mobile ?? '—',
                            color: Colors.green,
                            isDarkMode: isDarkMode,
                          ),
                          Builder(
                            builder: (context) {
                              final parts = [
                                user?.addressLine,
                                user?.areaLocality,
                                user?.city,
                                user?.district,
                                user?.state,
                                user?.country,
                                user?.postalCode?.toString(),
                              ]
                                  .where(
                                      (p) => p != null && p.trim().isNotEmpty)
                                  .toList();

                              final fullAddress = parts.isNotEmpty
                                  ? parts.join(', ')
                                  : (user?.address != null &&
                                          user!.address!.isNotEmpty
                                      ? user.address!
                                      : 'Not provided');

                              return _settingsTile(
                                icon: LucideIcons.mapPin,
                                title: 'Address',
                                value: fullAddress,
                                color: Colors.orange,
                                isLast: true,
                                isDarkMode: isDarkMode,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── App Settings ──
                    const FluentSectionHeader(
                        title: 'APPLICATION', icon: LucideIcons.settings),
                    const SizedBox(height: 12),
                    FluentCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _actionTile(
                            icon: LucideIcons.clipboardList,
                            title: 'My Report History',
                            subtitle: 'Status of your raised issues',
                            onTap: () => context.push('/my-tasks'),
                            color: Colors.indigo,
                            isDarkMode: isDarkMode,
                          ),
                          _actionTile(
                            icon: LucideIcons.bell,
                            title: 'Notifications',
                            subtitle: 'Alerts and official updates',
                            onTap: () => context.go('/alerts'),
                            color: Colors.purple,
                            isDarkMode: isDarkMode,
                          ),
                          _actionTile(
                            icon: LucideIcons.shield,
                            title: 'Privacy & Security',
                            subtitle: 'Data handling and permissions',
                            onTap: () {},
                            color: Colors.teal,
                            isLast: true,
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Support ──
                    const FluentSectionHeader(
                        title: 'SUPPORT', icon: LucideIcons.helpCircle),
                    const SizedBox(height: 12),
                    FluentCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _actionTile(
                            icon: LucideIcons.helpCircle,
                            title: 'Help Center',
                            subtitle: 'FAQs and user guides',
                            onTap: () {},
                            color: Colors.blueGrey,
                            isDarkMode: isDarkMode,
                          ),
                          _actionTile(
                            icon: LucideIcons.info,
                            title: 'About the App',
                            subtitle: 'Version 1.2.4 (Build 42)',
                            onTap: () {},
                            color: Colors.blue,
                            isLast: true,
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Logout ──
                    _buildLogoutButton(context, ref, isDarkMode),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Component Builders ───

  Widget _buildAvatar(BuildContext context, WidgetRef ref,
      AsyncValue<UserModel?> authState, dynamic user, bool isDarkMode) {
    final bool isUploading = authState.isLoading && authState.hasValue;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipOval(
                    child: user?.photoUrl != null
                        ? GestureDetector(
                            onTap: () => FluentImageViewer.show(context,
                                imageUrl: user!.photoUrl!,
                                title: '${user.displayName}\'s Profile Photo'),
                            child: CachedNetworkImage(
                              imageUrl: user!.photoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(
                                  _getRoleIcon(user?.role),
                                  color: Colors.white,
                                  size: 42,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              _getRoleIcon(user?.role),
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                  ),
                  if (isUploading)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: isUploading ? null : () => _showPhotoOptions(context, ref, user),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isUploading ? Colors.grey : AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isUploading ? LucideIcons.loader2 : LucideIcons.camera,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPhotoOptions(BuildContext context, WidgetRef ref, dynamic user) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16).copyWith(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
              color: isDarkMode ? Colors.white12 : Colors.grey.shade100),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _photoOptionTile(
              context,
              icon: LucideIcons.camera,
              title: 'Take a Photo',
              subtitle: 'Capture using camera',
              color: AppColors.primary,
              onTap: () => _processItem(context, ref, ImageSource.camera),
              isDarkMode: isDarkMode,
            ),
            _photoOptionTile(
              context,
              icon: LucideIcons.image,
              title: 'Choose from Gallery',
              subtitle: 'Select from your photos',
              color: Colors.blue,
              onTap: () => _processItem(context, ref, ImageSource.gallery),
              isDarkMode: isDarkMode,
            ),
            if (user?.photoUrl != null)
              _photoOptionTile(
                context,
                icon: LucideIcons.trash2,
                title: 'Remove Photo',
                subtitle: 'Revert to default icon',
                color: Colors.red,
                isLast: true,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).removeProfilePhoto();
                  if (context.mounted) {
                    SuccessPopup.show(context,
                        message: 'Photo Removed Successfully',
                        icon: LucideIcons.trash2);
                  }
                },
                isDarkMode: isDarkMode,
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _photoOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(32))
            : BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode
                            ? Colors.white38
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  size: 18,
                  color: isDarkMode ? Colors.white12 : Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processItem(
      BuildContext context, WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 90,
      maxWidth: 512,
      maxHeight: 512,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit Profile Photo',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Edit Profile Photo',
          aspectRatioLockEnabled: true,
        ),
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
          size: const CropperSize(width: 400, height: 400),
          customDialogBuilder: (cropper, initCropper, crop, rotate, scale) {
            double zoomValue = 1.0;
            return StatefulBuilder(
              builder: (context, setState) {
                // Initialize cropper on first build
                initCropper();
                
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  child: Container(
                    width: 460,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Crop Image',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(LucideIcons.x, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: SizedBox(width: 400, height: 400, child: cropper),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Zoom Control Section
                        Column(
                          children: [
                            const Text(
                              'Zoom',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.rotateCcw, size: 20),
                                  onPressed: () => rotate(RotationAngle.counterClockwise90),
                                  tooltip: 'Rotate Left',
                                ),
                                const Text('-', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: AppColors.primary,
                                      thumbColor: AppColors.primary,
                                      overlayColor: AppColors.primary.withValues(alpha: 0.1),
                                    ),
                                    child: Slider(
                                      value: zoomValue,
                                      min: 1.0,
                                      max: 3.0,
                                      onChanged: (value) {
                                        setState(() => zoomValue = value);
                                        scale(value);
                                      },
                                    ),
                                  ),
                                ),
                                const Text('+', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                                IconButton(
                                  icon: const Icon(LucideIcons.rotateCw, size: 20),
                                  onPressed: () => rotate(RotationAngle.clockwise90),
                                  tooltip: 'Rotate Right',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                final result = await crop();
                                if (context.mounted) Navigator.pop(context, result);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('CROP', style: TextStyle(fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );

    if (context.mounted) {
      Navigator.pop(context); // Close selection menu after cropper
    }

    if (croppedFile == null) return;

    final bytes = await croppedFile.readAsBytes();
    await ref.read(authProvider.notifier).uploadProfilePhoto(bytes);

    if (context.mounted) {
      SuccessPopup.show(
        context,
        message: 'Profile Photo Updated!',
        icon: LucideIcons.image,
      );
    }
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

  Widget _buildRoleBadge(dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            user?.isVerified == true
                ? LucideIcons.shieldCheck
                : LucideIcons.shieldAlert,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            user?.roleDisplay.toUpperCase() ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDarkMode,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color:
                        isDarkMode ? Colors.white38 : AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    required bool isDarkMode,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color:
                            isDarkMode ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode
                            ? Colors.white38
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: isDarkMode
                    ? Colors.white24
                    : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(
      BuildContext context, WidgetRef ref, bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _confirmLogout(context, ref, isDarkMode),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.red.shade50,
          foregroundColor: Colors.red,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.red.withValues(alpha: 0.2)),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.logOut, size: 20),
            SizedBox(width: 12),
            Text('LOGOUT FROM SESSION',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (_) => FluentDialog(
        title: 'Confirm Logout',
        content:
            'Are you sure you want to end your active session and exit for now?',
        confirmLabel: 'LOGOUT',
        cancelLabel: 'STAY',
        onConfirm: () async {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        },
      ),
    );
  }
}
