import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui' as ui;

import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'success_popup.dart';

void showEditProfileModal(BuildContext context, WidgetRef ref, UserModel user) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _EditProfileSheet(user: user),
  );
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserModel user;

  const _EditProfileSheet({required this.user});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _addressLineController;
  late TextEditingController _areaLocalityController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _districtController;
  late TextEditingController _countryController;
  late TextEditingController _postalCodeController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _mobileController = TextEditingController(text: widget.user.mobile);
    _addressLineController = TextEditingController(text: widget.user.addressLine ?? '');
    _areaLocalityController = TextEditingController(text: widget.user.areaLocality ?? '');
    _cityController = TextEditingController(text: widget.user.city ?? '');
    _stateController = TextEditingController(text: widget.user.state ?? '');
    _districtController = TextEditingController(text: widget.user.district ?? '');
    _countryController = TextEditingController(text: widget.user.country ?? '');
    _postalCodeController = TextEditingController(text: widget.user.postalCode?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressLineController.dispose();
    _areaLocalityController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
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

    if (mounted) {
      Navigator.pop(context); // Close sheet after cropper interaction
    }

    if (croppedFile == null) return;

    final bytes = await croppedFile.readAsBytes();
    await ref.read(authProvider.notifier).uploadProfilePhoto(bytes);
  }

  void _showPhotoOptions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16).copyWith(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(32),
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
              icon: LucideIcons.camera,
              title: 'Take a Photo',
              subtitle: 'Capture using camera',
              onTap: () => _pickImage(ImageSource.camera),
              color: AppColors.primary,
              isDarkMode: isDarkMode,
            ),
            _photoOptionTile(
              icon: LucideIcons.image,
              title: 'Choose from Gallery',
              subtitle: 'Select from your photos',
              onTap: () => _pickImage(ImageSource.gallery),
              color: Colors.blue,
              isDarkMode: isDarkMode,
            ),
            if (widget.user.photoUrl != null)
              _photoOptionTile(
                icon: LucideIcons.trash2,
                title: 'Remove Photo',
                subtitle: 'Delete current photo',
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).removeProfilePhoto();
                },
                color: Colors.red,
                isDarkMode: isDarkMode,
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _photoOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    required bool isDarkMode,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white38 : AppColors.textSecondary)),
      trailing: Icon(LucideIcons.chevronRight, size: 18, color: isDarkMode ? Colors.white12 : Colors.grey.shade300),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedData = {
        'name': _nameController.text.trim(),
        'phone': _mobileController.text.trim(),
        'address_line': _addressLineController.text.trim(),
        'area_locality': _areaLocalityController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'district': _districtController.text.trim(),
        'country': _countryController.text.trim(),
        'postal_code': int.tryParse(_postalCodeController.text.trim()),
      };

      await ref.read(authProvider.notifier).updateProfile(updatedData);

      if (mounted) {
        Navigator.pop(context);
        SuccessPopup.show(
          context,
          message: 'Profile Updated Successfully',
          icon: LucideIcons.userCheck,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        margin: const EdgeInsets.all(16).copyWith(
          bottom: bottomInset > 0 ? bottomInset + 16 : bottomPadding + 16,
        ),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? const Color(0xFF1E1E2E).withValues(alpha: 0.9) 
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDarkMode ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.edit2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      LucideIcons.x,
                      color: isDarkMode ? Colors.white54 : AppColors.textSecondary,
                    ),
                    splashRadius: 24,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Profile Image Selector
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDarkMode ? Colors.white10 : Colors.grey.shade100,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: widget.user.photoUrl != null
                            ? CachedNetworkImage(
                                imageUrl: widget.user.photoUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : Icon(
                                LucideIcons.user,
                                size: 40,
                                color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showPhotoOptions,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            LucideIcons.camera,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form fields
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                icon: LucideIcons.user,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _mobileController,
                label: 'Mobile Number',
                icon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressLineController,
                label: 'Address Line',
                icon: LucideIcons.mapPin,
                maxLines: 2,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _areaLocalityController,
                label: 'Area/Locality',
                icon: LucideIcons.map,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      icon: LucideIcons.building,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _districtController,
                      label: 'District',
                      icon: LucideIcons.map,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _stateController,
                      label: 'State',
                      icon: LucideIcons.mapPin,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _countryController,
                      label: 'Country',
                      icon: LucideIcons.globe,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _postalCodeController,
                label: 'Postal Code',
                icon: LucideIcons.hash,
                keyboardType: TextInputType.number,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDarkMode,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.white : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.white54 : AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: isDarkMode ? Colors.white54 : AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: isDarkMode ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
