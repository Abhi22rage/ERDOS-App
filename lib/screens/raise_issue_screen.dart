import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/constants/component_codes.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../core/constants/dispur_wss_components.dart';
import '../widgets/fluent_ui.dart';

class RaiseIssueScreen extends ConsumerStatefulWidget {
  const RaiseIssueScreen({super.key});

  @override
  ConsumerState<RaiseIssueScreen> createState() => _RaiseIssueScreenState();
}

class _RaiseIssueScreenState extends ConsumerState<RaiseIssueScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final locationController = TextEditingController();

  String? _selectedScheme;
  String? _selectedAsset;
  String? _selectedComponentCategory;
  String? _selectedComponentType;
  String? _selectedComponentUnit;
  File? _photo;
  bool _isTitleEditedByUser = false;
  String _currentLat = 'Detecting...';
  String _currentLng = 'Detecting...';
  String _currentTimestamp = '';
  String? _currentAddress = 'Fetching...';
  Position? _currentPosition;
  final String _selectedSeverity = 'Medium';
  Position? _photoPosition;
  bool _isGeoTagging = false;
  late final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentTimestamp =
        DateFormat('MMMM dd, yyyy  HH:mm a').format(DateTime.now());
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) _showLocationServiceDialog();
        setState(() => _currentAddress = 'Location services disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _currentAddress = 'Permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _currentAddress = 'Permission permanently denied');
        return;
      }

      // Try for current position with a fallback
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (_) {
        // Fallback to last known position if timeout
        position = await Geolocator.getLastKnownPosition();
      }

      final pos = position;
      if (pos != null && mounted) {
        setState(() {
          _currentPosition = pos;
          _currentLat = '${pos.latitude.toStringAsFixed(4)}° N';
          _currentLng = '${pos.longitude.toStringAsFixed(4)}° E';
        });
        _getAddressFromLatLng(pos.latitude, pos.longitude);
      } else {
        setState(() => _currentAddress = 'Unable to detect location');
      }
    } catch (e) {
      if (mounted) setState(() => _currentAddress = 'Error: $e');
    }
  }

  void _updateAutoTitle() {
    //Auto ticket title generation
    if (_isTitleEditedByUser && _titleCtrl.text.isNotEmpty) return;
    List<String> parts = [];
    if (_selectedScheme != null) parts.add(_selectedScheme!);
    if (_selectedAsset != null) parts.add(_selectedAsset!);
    if (_selectedComponentUnit != null && _selectedComponentUnit!.isNotEmpty) {
      parts.add(_selectedComponentUnit!);
    } else if (_selectedComponentType != null) {
      parts.add(_selectedComponentType!);
    }
    if (parts.isNotEmpty) {
      parts.add('Fault');
      _titleCtrl.text = parts.join(' ');
      _isTitleEditedByUser = false;
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final List<String> segments = [
          if (place.street != null && place.street!.isNotEmpty) place.street!,
          if (place.subLocality != null && place.subLocality!.isNotEmpty)
            place.subLocality!,
          if (place.locality != null && place.locality!.isNotEmpty)
            place.locality!,
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty)
            place.administrativeArea!,
          if (place.postalCode != null && place.postalCode!.isNotEmpty)
            place.postalCode!,
        ];

        setState(() {
          _currentAddress = segments.join(', ');
        });
      }
    } catch (_) {}
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.mapPin, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Enable GPS',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Device location is turned off. For precise GPS reporting, please enable it in your system settings.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL',
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('OPEN SETTINGS',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _capturePhoto() async {
    setState(() => _isGeoTagging = true);
    try {
      final picked =
          await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (picked != null) {
        Position? pos;
        try {
          pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5),
          );
        } catch (_) {
          pos = await Geolocator.getLastKnownPosition();
        }

        setState(() {
          _photo = File(picked.path);
          if (pos != null) {
            _photoPosition = pos;
            _currentPosition = pos;
            _currentLat = '${pos.latitude.toStringAsFixed(4)}° N';
            _currentLng = '${pos.longitude.toStringAsFixed(4)}° E';
            _getAddressFromLatLng(pos.latitude, pos.longitude);
          }
        });
      }
    } catch (e) {
      debugPrint('Photo capture error: $e');
    } finally {
      if (mounted) setState(() => _isGeoTagging = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedScheme == null ||
        _selectedComponentType == null ||
        _titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill mandatory fields')));
      return;
    }

    _showReviewDialog();
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Review Report',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewRow('Center', _selectedScheme),
              _buildReviewRow('Asset', _selectedAsset),
              _buildReviewRow('Category', _selectedComponentCategory),
              _buildReviewRow('Type', _selectedComponentType),
              _buildReviewRow('Unit', _selectedComponentUnit),
              _buildReviewRow('Title', _titleCtrl.text),
              _buildReviewRow('Description',
                  _descCtrl.text.isEmpty ? 'N/A' : _descCtrl.text),
              _buildReviewRow('Location', _currentAddress),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('EDIT',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performSubmit();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('DONE',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _performSubmit() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final reportNumber = ComponentCodes.generateIncidentId(
        scheme: _selectedScheme,
        category: _selectedComponentCategory,
        type: _selectedComponentType,
        unit: _selectedComponentUnit,
      );

      List<String> mediaUrls = [];
      if (_photo != null) {
        final url = await ref
            .read(apiServiceProvider)
            .uploadMedia(_photo!, reportNumber);
        mediaUrls.add(url);
      }

      final newBreakdown = await ref.read(apiServiceProvider).createBreakdown({
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'report_number': reportNumber,
        'severity': _selectedSeverity.toLowerCase(),
        'asset_name': _selectedAsset,
        'component_category': _selectedComponentCategory,
        'component_type': _selectedComponentType,
        'component_unit': _selectedComponentUnit,
        'location_lat': _photoPosition?.latitude ?? _currentPosition?.latitude,
        'location_lng':
            _photoPosition?.longitude ?? _currentPosition?.longitude,
        'location_address': _currentAddress,
        'media_urls': mediaUrls,
      });

      ref.invalidate(myBreakdownsProvider);
      ref.invalidate(summaryProvider);
      if (!mounted) return;
      context.pop(); // Remove loading
      _showSuccessDialog(newBreakdown.id, reportNumber, _titleCtrl.text);
    } catch (e) {
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
    }
  }

  void _showSuccessDialog(String id, String reportId, String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: FluentCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(LucideIcons.checkCircle2,
                    color: AppColors.success, size: 36),
              ),
              const SizedBox(height: 20),
              const Text('Report Submitted',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2)),
              const SizedBox(height: 4),
              Text(reportId,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        context.pop();
                        context.go('/home');
                      },
                      child: const Text('Done',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.pop();
                        context.push('/incident/$id');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('View Ticket',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FluentBackground(
        child: SafeArea(
          child: Column(
            children: [
              const FluentHeader(title: 'Raise Issue'),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Equipment Details
                      _buildFormSection(
                          isDarkMode, 'Equipment Context', LucideIcons.layers, [
                        _buildFluentDropdown(
                            'Production Center',
                            'Select Center',
                            _selectedScheme,
                            ['Dispur WSS', 'GU & AEC WSS', 'Sarusajai WSS'],
                            (v) {
                          setState(() {
                            _selectedScheme = v;
                            _selectedAsset = null;
                            _selectedComponentCategory = null;
                            _selectedComponentType = null;
                            _selectedComponentUnit = null;
                            _updateAutoTitle();
                          });
                        }, isDarkMode),
                        if (_selectedScheme != null)
                          _buildFluentDropdown(
                              'Asset / Facility',
                              'Select Asset',
                              _selectedAsset,
                              _getAssets(), (v) {
                            setState(() {
                              _selectedAsset = v;
                              _selectedComponentCategory = null;
                              _selectedComponentType = null;
                              _selectedComponentUnit = null;
                              _updateAutoTitle();
                            });
                          }, isDarkMode),
                        if (_selectedAsset != null)
                          _buildFluentDropdown(
                              'Component Category',
                              'Select Category',
                              _selectedComponentCategory,
                              _getCategories(), (v) {
                            setState(() {
                              _selectedComponentCategory = v;
                              _selectedComponentType = null;
                              _selectedComponentUnit = null;
                              _updateAutoTitle();
                            });
                          }, isDarkMode),
                        if (_selectedComponentCategory != null)
                          _buildFluentDropdown('Component Type', 'Select Type',
                              _selectedComponentType, _getTypes(), (v) {
                            setState(() {
                              _selectedComponentType = v;
                              _selectedComponentUnit = null;
                              _updateAutoTitle();
                            });
                          }, isDarkMode),
                        if (_selectedComponentType != null && _getUnits().isNotEmpty)
                          _buildFluentDropdown('Component Unit', 'Select Unit',
                              _selectedComponentUnit, _getUnits(), (v) {
                            setState(() {
                              _selectedComponentUnit = v;
                              _updateAutoTitle();
                            });
                          }, isDarkMode),
                      ]),

                      const SizedBox(height: 24),
                      // Section 2: Fault Description
                      _buildFormSection(
                          isDarkMode, 'Fault Details', LucideIcons.fileEdit, [
                        _buildFluentTextField('TICKET TITLE',
                            'Enter a concise title', _titleCtrl, isDarkMode,
                            onChanged: (v) => _isTitleEditedByUser = true),
                        const SizedBox(height: 16),
                        _buildFluentTextField('DETAILED DESCRIPTION',
                            'Describe the issue...', _descCtrl, isDarkMode,
                            maxLines: 4),
                      ]),

                      const SizedBox(height: 24),
                      // Section 3: Media & Location
                      _buildFormSection(
                          isDarkMode, 'Evidence & GPS', LucideIcons.camera, [
                        _buildPhotoCapture(isDarkMode),
                        const SizedBox(height: 20),
                        _buildLocationInfo(isDarkMode),
                      ]),

                      const SizedBox(height: 32),
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(LucideIcons.send,
                              size: 18, color: Colors.white),
                          label: const Text('SUBMIT BREAKDOWN REPORT',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  fontSize: 13,
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            elevation: 8,
                            shadowColor: AppColors.primary.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
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

  Widget _buildFormSection(
      bool isDarkMode, String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 1.5)),
          ],
        ),
        const SizedBox(height: 16),
        FluentCard(
          padding: const EdgeInsets.all(20),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildFluentDropdown(String label, String hint, String? value,
      List<String> items, ValueChanged<String?> onChanged, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white38 : AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF9FAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.transparent),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.contains(value) ? value : null,
              hint: Text(hint,
                  style: TextStyle(
                      color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
                      fontSize: 13)),
              icon: Icon(LucideIcons.chevronDown,
                  size: 16,
                  color: isDarkMode ? Colors.white38 : AppColors.textSecondary),
              items: items
                  .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFluentTextField(
      String label, String hint, TextEditingController ctrl, bool isDarkMode,
      {int maxLines = 1, ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white38 : AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
            filled: true,
            fillColor: isDarkMode
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF9FAFF),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoCapture(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CAPTURE GPS TAGGED PHOTO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white38 : AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        if (_photo == null)
          InkWell(
            onTap: _capturePhoto,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.03)
                    : AppColors.primary.withOpacity(0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _isGeoTagging
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : Icon(LucideIcons.camera,
                          size: 32, color: AppColors.primary.withOpacity(0.6)),
                  const SizedBox(height: 12),
                  Text(
                    _isGeoTagging
                        ? 'Acquiring GPS...'
                        : 'Tap to add photos/videos',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary.withOpacity(0.6),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(isDarkMode ? 0.08 : 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CAPTURED GPS IMAGE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isDarkMode
                            ? Colors.white38
                            : AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _photo = null;
                        _photoPosition = null;
                      }),
                      child: const Icon(LucideIcons.trash2,
                          color: Colors.red, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _photo!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedScheme ?? 'No Center Selected',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (locationController.text.isNotEmpty) ...[
                                Text(
                                  "📍 ${locationController.text}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                "📍 ${_currentAddress ?? 'Detecting address...'}",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "🌐 ${_currentLat} , ${_currentLng}",
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "🕒 $_currentTimestamp",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(10),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              InteractiveViewer(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(_photo!),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.zoomIn, size: 16),
                    label: const Text(
                      "VIEW FULL IMAGE",
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLocationInfo(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.03)
              : const Color(0xFFF0F3F9),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(LucideIcons.mapPin,
              size: 16, color: AppColors.primary.withOpacity(0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AUTO-DETECTED LOCATION',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: isDarkMode
                            ? Colors.white24
                            : AppColors.textSecondary,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                const SizedBox(height: 2),
                Text(_currentAddress ?? 'Detecting...',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                if (_currentPosition != null) ...[
                  const SizedBox(height: 4),
                  Text('$_currentLat  |  $_currentLng',
                      style: TextStyle(
                          fontSize: 9,
                          color: isDarkMode
                              ? Colors.white24
                              : AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          Text(_currentTimestamp,
              style: TextStyle(
                  fontSize: 10,
                  color:
                      isDarkMode ? Colors.white24 : AppColors.textSecondary)),
        ],
      ),
    );
  }

  // Data helpers
  List<String> _getAssets() => _selectedScheme == 'Dispur WSS'
      ? [
          'Intake (Barge)',
          'Water Treatment Plant',
          'Boosting Stations',
          'Pipelines'
        ]
      : ['Boosting Stations', 'Pipelines'];
  List<String> _getCategories() => _selectedScheme == 'Dispur WSS'
      ? wtpComponentCategories
      : ['Electrical', 'Mechanical', 'Civil', 'Consumables'];
  List<String> _getTypes() {
    if (_selectedComponentCategory == null) return [];
    if (_selectedScheme == 'Dispur WSS') {
      return groupedWtpComponents[_selectedComponentCategory]!
          .map((c) => c.name)
          .toSet()
          .toList();
    }
    return ['Pump', 'Motor', 'Valve', 'Panel'];
  }

  List<String> _getUnits() {
    if (_selectedComponentType == null) return [];
    if (_selectedScheme == 'Dispur WSS' &&
        (_selectedAsset == 'Intake (Barge)' ||
            _selectedAsset == 'Water Treatment Plant')) {
      final matches = wtpComponents.where((c) {
        if (c.category != _selectedComponentCategory) return false;
        return c.name == _selectedComponentType;
      }).toList();
      if (matches.isEmpty) return [];
      final comp = matches.first;
      int quantity = int.tryParse(comp.quantity) ?? 0;
      if (quantity <= 1) return [];
      return List.generate(
          quantity,
          (i) =>
              '${_selectedComponentType} ${(i + 1).toString().padLeft(2, '0')}');
    }
    return ['Unit 01', 'Unit 02', 'Unit 03'];
  }
}
