import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fluent_ui.dart';

class ContractorProfileScreen extends StatelessWidget {
  final Map<String, dynamic> contractor;

  const ContractorProfileScreen({super.key, required this.contractor});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FluentBackground(
        child: SafeArea(
          child: Column(
            children: [
              FluentHeader(
                title: 'Contractor Profile',
                showBackButton: true,
                actions: [
                  IconButton(
                    icon: Icon(LucideIcons.moreVertical, size: 20, color: isDarkMode ? Colors.white : AppColors.primary),
                    onPressed: () {},
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Profile Identity ──
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.1),
                                border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                              ),
                              child: const Center(child: Icon(LucideIcons.hardHat, size: 40, color: AppColors.primary)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              contractor['name'] ?? 'Unknown',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              contractor['specialty'] ?? 'General',
                              style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Key Metrics ──
                      Row(
                        children: [
                          _buildMetric(LucideIcons.star, 'Rating', '${contractor['rating'] ?? 0.0}', isDarkMode, const Color(0xFFF9A825)),
                          const SizedBox(width: 16),
                          _buildMetric(LucideIcons.award, 'Experience', contractor['experience'] ?? 'N/A', isDarkMode, AppColors.primary),
                          const SizedBox(width: 16),
                          _buildMetric(LucideIcons.checkCircle, 'Jobs Done', '142', isDarkMode, AppColors.success),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Contact Details ──
                      const FluentSectionHeader(title: 'Contact Details'),
                      const SizedBox(height: 16),
                      FluentCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildContactRow(LucideIcons.user, 'Liaison', contractor['contact_person'] ?? 'N/A', isDarkMode),
                            const Divider(height: 24),
                            _buildContactRow(LucideIcons.phone, 'Hotline', contractor['phone'] ?? 'N/A', isDarkMode),
                            const Divider(height: 24),
                            _buildContactRow(LucideIcons.mail, 'Email', 'contact@${(contractor['name'] ?? "").replaceAll(' ', '').toLowerCase()}.com', isDarkMode),
                            const Divider(height: 24),
                            _buildContactRow(LucideIcons.mapPin, 'Office', 'Guwahati, Assam, 781005', isDarkMode),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Services & Competencies ──
                      const FluentSectionHeader(title: 'Service Areas'),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: [
                          _buildChip('Pipeline Maintenance', isDarkMode),
                          _buildChip('Pumpset Repair', isDarkMode),
                          _buildChip('Electrical Works', isDarkMode),
                          _buildChip('Civil Structuring', isDarkMode),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Actions ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          icon: const Icon(LucideIcons.briefcase, size: 18, color: Colors.white),
                          label: const Text('ASSIGN TASK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              icon: const Icon(LucideIcons.phone, size: 16),
                              label: const Text('CALL', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              icon: const Icon(LucideIcons.messageSquare, size: 16),
                              label: const Text('MESSAGE', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
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

  Widget _buildMetric(IconData icon, String label, String value, bool isDarkMode, Color color) {
    return Expanded(
      child: FluentCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white38 : AppColors.textSecondary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value, bool isDarkMode) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFF9FAFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white38 : AppColors.textSecondary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildChip(String label, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? Colors.white70 : AppColors.textPrimary,
        ),
      ),
    );
  }
}
