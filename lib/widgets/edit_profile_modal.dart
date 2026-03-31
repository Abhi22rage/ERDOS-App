import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui' as ui;

import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';
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
              const SizedBox(height: 24),

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
