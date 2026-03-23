import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/fluent_ui.dart';

class ContractorsScreen extends ConsumerWidget {
  const ContractorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> contractors = [
      {
        'id': '1',
        'name': 'ABC Constructions',
        'contact_person': 'Ramesh Kumar',
        'phone': '+91 98765 43210',
        'specialty': 'Pipeline Repair & Laying',
        'rating': 4.8,
        'experience': '12 Years',
      },
      {
        'id': '2',
        'name': 'RK Electricals',
        'contact_person': 'Suresh Das',
        'phone': '+91 87654 32109',
        'specialty': 'HT/LT Electrical Works',
        'rating': 4.5,
        'experience': '8 Years',
      },
      {
        'id': '3',
        'name': 'Northeast Pumps & Motors',
        'contact_person': 'Pranab Saikia',
        'phone': '+91 76543 21098',
        'specialty': 'Pump & Motor Maintenance',
        'rating': 4.9,
        'experience': '15 Years',
      },
      {
        'id': '4',
        'name': 'Buildwell Infra',
        'contact_person': 'Anil Sarma',
        'phone': '+91 65432 10987',
        'specialty': 'Civil & Structural Works',
        'rating': 4.2,
        'experience': '10 Years',
      },
      {
        'id': '5',
        'name': 'Quality Repairs Ltd',
        'contact_person': 'Diganta Baruah',
        'phone': '+91 54321 09876',
        'specialty': 'Mechanical Overhauling',
        'rating': 4.7,
        'experience': '6 Years',
      },
    ];

    return Scaffold(
      body: FluentBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Modern Header ──
              const FluentHeader(
                title: 'Contractors',
              ),

              // ── List ──
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: contractors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) {
                    final c = contractors[i];
                    return _ContractorCard(c: c, isDarkMode: isDarkMode);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContractorCard extends StatelessWidget {
  final Map<String, dynamic> c;
  final bool isDarkMode;

  const _ContractorCard({required this.c, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return FluentCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.hardHat, size: 28, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDarkMode ? Colors.white : AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c['specialty'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRatingBadge(c['rating']),
              ],
            ),
          ),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.03) : const Color(0xFFF9FAFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.transparent),
            ),
            child: Column(
              children: [
                _buildInfoRow(LucideIcons.user, 'Liaison', c['contact_person']),
                const SizedBox(height: 10),
                _buildInfoRow(LucideIcons.phone, 'Hotline', c['phone']),
                const SizedBox(height: 10),
                _buildInfoRow(LucideIcons.award, 'Experience', c['experience']),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: const Center(
                        child: Text(
                          'View Profile',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.phoneCall, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.star, color: Color(0xFFF9A825), size: 14),
          const SizedBox(width: 4),
          Text(
            '$rating',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFFF9A825),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isDarkMode ? Colors.white38 : AppColors.textSecondary),
        const SizedBox(width: 10),
        Text('$label:', style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.white38 : AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
