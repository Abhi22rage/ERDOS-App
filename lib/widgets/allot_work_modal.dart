import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'fluent_ui.dart';

class AllotWorkModal extends ConsumerStatefulWidget {
  final String breakdownId;

  const AllotWorkModal({super.key, required this.breakdownId});

  @override
  ConsumerState<AllotWorkModal> createState() => _AllotWorkModalState();
}

class _AllotWorkModalState extends ConsumerState<AllotWorkModal> {
  List<Map<String, dynamic>> _contractors = [];
  bool _isLoading = true;
  String? _selectedContractorId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchContractors();
  }

  Future<void> _fetchContractors() async {
    final contractors = await ref.read(apiServiceProvider).getContractors();
    if (mounted) {
      setState(() {
        _contractors = contractors;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAllotment() async {
    if (_selectedContractorId == null) return;
    
    setState(() => _isSubmitting = true);
    try {
      final user = ApiService.sessionUser;
      if (user == null) throw Exception("No authenticated user session.");

      await ref.read(apiServiceProvider).allotWork(
        breakdownId: widget.breakdownId,
        contractorId: _selectedContractorId!,
        assignedByUserId: user.id, // Replace with actual current user ID from state if available
      );

      // Refresh breakdown detail and lists
      ref.invalidate(breakdownDetailProvider(widget.breakdownId));
      ref.invalidate(myBreakdownsProvider);
      ref.invalidate(allBreakdownsProvider);
      
      if (mounted) {
        Navigator.pop(context, true); // True indicates success
      }
    } catch (e) {
      debugPrint('Error allotting work: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to allot work: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF161625) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Allot Contractor',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppColors.primary),
            ))
          else if (_contractors.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No active contractors found.', style: TextStyle(color: AppColors.error)),
            )
          else ...[
            Text('Select Contractor', style: TextStyle(fontWeight: FontWeight.w700, color: isDarkMode ? Colors.white70 : AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: isDarkMode ? Colors.white12 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedContractorId,
                  isExpanded: true,
                  hint: const Text('Choose an eligible contractor'),
                  items: _contractors.map((c) {
                    final user = c['users'] as Map<String, dynamic>?;
                    final name = user?['full_name'] ?? 'Unknown Contractor';
                    return DropdownMenuItem<String>(
                      value: c['id'],
                      child: Text('$name (${c['category']})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedContractorId = val),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _selectedContractorId == null || _isSubmitting ? null : _submitAllotment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ASSIGN WORK', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
