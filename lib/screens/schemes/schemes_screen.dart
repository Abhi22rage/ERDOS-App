import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../core/constants/dispur_pwss_components.dart';
import '../../widgets/fluent_ui.dart';

class SchemesScreen extends ConsumerStatefulWidget {
  final String? initialCenter;
  final String? initialAsset;

  const SchemesScreen({
    super.key,
    this.initialCenter,
    this.initialAsset,
  });

  @override
  ConsumerState<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends ConsumerState<SchemesScreen> {
  late int _currentLevel;
  String? _selectedCenter;
  String? _selectedAsset;
  String? _selectedCategory;
  String? _selectedType;
  String? _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedCenter = widget.initialCenter;
    _selectedAsset = widget.initialAsset;

    if (_selectedAsset != null) {
      _currentLevel = 2;
    } else if (_selectedCenter != null) {
      _currentLevel = 1;
    } else {
      _currentLevel = 0;
    }
  }

  // Hierarchical Data Logic (Unchanged)
  final List<String> _centers = [
    'Dispur PWSS',
    'GU & AEC PWSS',
    'Sarusajai PWSS'
  ];
  List<String> get _assets => _selectedCenter == 'Dispur PWSS'
      ? [
          'Intake (Barge)',
          'Water Treatment Plant',
          'Boosting Stations',
          'Pipelines'
        ]
      : ['Boosting Stations', 'Pipelines'];

  List<String> get _categories => (_selectedCenter == 'Dispur PWSS' &&
          (_selectedAsset == 'Intake (Barge)' ||
              _selectedAsset == 'Water Treatment Plant'))
      ? wtpComponentCategories
      : ['Electrical', 'Mechanical', 'Civil', 'Consumables'];

  List<String> get _types {
    if (_selectedCategory == null) return [];
    if (_selectedCenter == 'Dispur PWSS' &&
        (_selectedAsset == 'Intake (Barge)' ||
            _selectedAsset == 'Water Treatment Plant')) {
      final Set<String> uniqueNames = {};
      for (var comp in groupedWtpComponents[_selectedCategory]!) {
        bool matchesLoc = true;
        if (_selectedAsset == 'Intake (Barge)' &&
            !comp.locationUsage.toLowerCase().contains('barge')) {
          matchesLoc = false;
        } else if (_selectedAsset == 'Water Treatment Plant' &&
            !comp.locationUsage.toLowerCase().contains('treatment plant')) {
          matchesLoc = false;
        }
        if (matchesLoc || comp.locationUsage.isEmpty) {
          uniqueNames.add(comp.name);
        }
      }
      return uniqueNames.toList()..sort();
    }
    return ['Pump', 'Motor', 'Valve', 'Panel', 'Cable', 'Transformer'];
  }

  List<String> get _units {
    if (_selectedType == null) return [];
    if (_selectedCenter == 'Dispur PWSS' &&
        (_selectedAsset == 'Intake (Barge)' ||
            _selectedAsset == 'Water Treatment Plant')) {
      final matches = wtpComponents.where((c) {
        if (c.category != _selectedCategory) return false;
        return c.name == _selectedType;
      }).toList();
      if (matches.isEmpty) return [];
      final comp = matches.first;
      int quantity = int.tryParse(comp.quantity) ?? 0;
      if (quantity <= 1) return [];
      return List.generate(quantity,
          (i) => '$_selectedType ${(i + 1).toString().padLeft(2, '0')}');
    }
    return ['Unit 01', 'Unit 02', 'Unit 03'];
  }

  WtpComponent? get _selectedComponentDetails {
    if (_selectedCenter == 'Dispur PWSS' &&
        (_selectedAsset == 'Intake (Barge)' ||
            _selectedAsset == 'Water Treatment Plant')) {
      final matches = wtpComponents.where((c) {
        if (c.category != _selectedCategory) return false;
        return c.name == _selectedType;
      }).toList();
      return matches.isNotEmpty ? matches.first : null;
    }
    return null;
  }

  void _onBack() {
    if (_currentLevel > 0) {
      setState(() {
        if (_currentLevel == 5 && _units.isEmpty) {
          // If level 4 was skipped (no units), jump back to level 3 (Types)
          _currentLevel = 3;
          _selectedType = null;
          _selectedUnit = null;
        } else {
          _currentLevel--;
          if (_currentLevel == 0) {
            _selectedCenter = null;
          }
          if (_currentLevel == 1) {
            _selectedAsset = null;
          }
          if (_currentLevel == 2) {
            _selectedCategory = null;
          }
          if (_currentLevel == 3) {
            _selectedType = null;
          }
          if (_currentLevel == 4) {
            _selectedUnit = null;
          }
        }
      });
    } else {
      context.pop();
    }
  }

  String get _title {
    switch (_currentLevel) {
      case 0:
        return 'Production Centers';
      case 1:
        return 'Assets';
      case 2:
        return 'Categories';
      case 3:
        return 'Component Types';
      case 4:
        return 'Component Units';
      case 5:
        return 'Component Details';
      default:
        return 'Schemes';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FluentBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Modern Header ──
              FluentHeader(
                title: _title,
                onBack: _onBack,
              ),

              // ── Breadcrumbs ──
              if (_currentLevel > 0) _buildBreadcrumbs(isDarkMode),

              // ── List / Content ──
              Expanded(
                child: _buildLevelContent(isDarkMode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(bool isDarkMode) {
    final breadcrumbs = [
      _selectedCenter,
      _selectedAsset,
      _selectedCategory,
      _selectedType,
      _selectedUnit
    ].where((e) => e != null).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.transparent),
      ),
      child: Text(
        breadcrumbs.join('  ›  '),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isDarkMode ? Colors.white24 : AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLevelContent(bool isDarkMode) {
    List<String> items = [];
    switch (_currentLevel) {
      case 0:
        items = _centers;
        break;
      case 1:
        items = _assets;
        break;
      case 2:
        items = _categories;
        break;
      case 3:
        items = _types;
        break;
      case 4:
        items = _units;
        break;
      case 5:
        return _buildDetailsView(isDarkMode);
    }

    if (items.isEmpty && _currentLevel == 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentLevel = 5);
      });
      return const SizedBox.shrink();
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        return _buildSelectableCard(items[i], isDarkMode, () {
          setState(() {
            switch (_currentLevel) {
              case 0:
                _selectedCenter = items[i];
                break;
              case 1:
                _selectedAsset = items[i];
                break;
              case 2:
                _selectedCategory = items[i];
                break;
              case 3:
                _selectedType = items[i];
                break;
              case 4:
                _selectedUnit = items[i];
                break;
            }
            _currentLevel++;
          });
        });
      },
    );
  }

  Widget _buildSelectableCard(
      String label, bool isDarkMode, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: FluentCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _currentLevel == 0 ? LucideIcons.building2 : LucideIcons.layers,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(LucideIcons.chevronRight,
                color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
                size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsView(bool isDarkMode) {
    final comp = _selectedComponentDetails;
    if (comp == null) return _buildErrorState(isDarkMode);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
              isDarkMode,
              'Component Profile',
              {
                'Name': comp.name,
                'Category': comp.category,
                'Sl. No.': comp.slNo,
                'Quantity': comp.quantity,
              },
              LucideIcons.info),
          const SizedBox(height: 16),
          _buildInfoCard(
              isDarkMode,
              'Operational Data',
              {
                'Primary Location': comp.locationUsage,
                'Main Purpose': comp.maintenancePurpose,
              },
              LucideIcons.activity),
          const SizedBox(height: 32),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/raise-issue'),
              icon: const Icon(LucideIcons.alertTriangle,
                  size: 18, color: Colors.white),
              label: const Text('RAISE BREAKDOWN TICKET',
                  style:
                      TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                elevation: 8,
                shadowColor: Colors.red.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDarkMode, String title,
      Map<String, String> details, IconData icon) {
    return FluentCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...details.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(e.key,
                          style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? Colors.white38
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: Text(e.value.isEmpty ? '—' : e.value,
                          style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX,
              size: 64,
              color: isDarkMode ? Colors.white10 : Colors.grey.shade200),
          const SizedBox(height: 24),
          const Text('Data not available',
              style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          TextButton(
              onPressed: () => setState(() => _currentLevel = 0),
              child: const Text('Reset Navigation')),
        ],
      ),
    );
  }
}
