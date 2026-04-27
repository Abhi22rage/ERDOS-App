import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/breakdown_model.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';

class ApplyCertificateScreen extends ConsumerStatefulWidget {
  final String incidentId;
  const ApplyCertificateScreen({super.key, required this.incidentId});

  @override
  ConsumerState<ApplyCertificateScreen> createState() => _ApplyCertificateScreenState();
}

class _ApplyCertificateScreenState extends ConsumerState<ApplyCertificateScreen> {
  final _budgetController = TextEditingController();
  bool _isApplying = false;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _applyCertificate(BreakdownModel breakdown) async {
    if (_budgetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the total budget'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isApplying = true);

    try {
      await ref.read(apiServiceProvider).updateBreakdownStatus(breakdown.id, 'certified');
      ref.invalidate(breakdownDetailProvider(breakdown.id));
      
      if (mounted) {
        final budget = _budgetController.text.trim();
        // Replace current screen with the certificate view, passing the budget
        context.pushReplacement('/certificate-report/${breakdown.id}?budget=$budget');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
        setState(() => _isApplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncBreakdown = ref.watch(breakdownDetailProvider(widget.incidentId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 22),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Apply Certificate',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: asyncBreakdown.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (breakdown) {
          // Try to find contractor info from approvals
          final contractorApproval = breakdown.approvals.cast<ApprovalModel?>().firstWhere(
            (a) => a?.approverRole?.toLowerCase() == 'contractor',
            orElse: () => null,
          );
          final contractorName = contractorApproval?.approverName ?? 'ABC CONSTRUCTIONS (Assigned)';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Incident Details', isDark),
                _buildInfoCard(
                  isDark: isDark,
                  children: [
                    _buildInfoRow('ID', breakdown.displayId, isDark),
                    _buildInfoRow('Title', breakdown.title, isDark),
                    _buildInfoRow('Date Reported', DateFormat('dd MMM yyyy').format(breakdown.createdAt), isDark),
                    _buildInfoRow('Location', breakdown.locationAddress ?? 'Unknown location', isDark),
                  ],
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Contractor Details', isDark),
                _buildInfoCard(
                  isDark: isDark,
                  children: [
                    _buildInfoRow('Contractor', contractorName, isDark),
                    _buildInfoRow('Status', 'Work Completed', isDark, valueColor: AppColors.success),
                  ],
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Financial Information', isDark),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Budget (₹)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _budgetController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. 124500.00',
                          hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400),
                          prefixIcon: Icon(LucideIcons.indianRupee, size: 18, color: isDark ? Colors.white54 : AppColors.textSecondary),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isApplying ? null : () => _applyCertificate(breakdown),
                    icon: _isApplying 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(LucideIcons.fileSignature, size: 20),
                    label: Text(
                      _isApplying ? 'Processing...' : 'Submit & Generate Certificate',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : AppColors.textPrimary,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: valueColor ?? (isDark ? Colors.white : AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
