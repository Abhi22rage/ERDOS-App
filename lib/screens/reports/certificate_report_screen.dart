import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fluent_ui.dart';

class CertificateReportScreen extends StatelessWidget {
  const CertificateReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FluentBackground(
        child: SafeArea(
          child: Column(
            children: [
              FluentHeader(
                title: 'Completion Certificate',
                actions: [
                  IconButton(
                    icon: Icon(LucideIcons.share2, size: 18, color: isDarkMode ? Colors.white70 : AppColors.primary),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.download, size: 18, color: isDarkMode ? Colors.white70 : AppColors.primary),
                    onPressed: () {},
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: FluentCard(
                        padding: EdgeInsets.zero,
                        child: Stack(
                          children: [
                            // Decorative Border
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 0.5),
                                  ),
                                ),
                              ),
                            ),

                            // Certificate Content
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Header
                                  Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Government_of_India_logo.svg/1200px-Government_of_India_logo.svg.png',
                                    height: 70,
                                    color: isDarkMode ? Colors.white70 : null,
                                    errorBuilder: (context, error, stackTrace) => Icon(LucideIcons.landmark, size: 60, color: isDarkMode ? Colors.white10 : AppColors.primary.withOpacity(0.2)),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'PUBLIC HEALTH ENGINEERING DEPARTMENT',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'GOVERNMENT OF ASSAM',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDarkMode ? Colors.white38 : AppColors.textSecondary,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 48),
                                  
                                  // Title
                                  const Text(
                                    'WORK COMPLETION',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 4, color: AppColors.primary),
                                  ),
                                  const Text(
                                    'CERTIFICATE',
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
                                  ),
                                  
                                  const SizedBox(height: 48),

                                  // Body
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDarkMode ? Colors.white70 : AppColors.textPrimary,
                                        height: 1.8,
                                        fontFamily: 'Inter',
                                      ),
                                      children: [
                                        const TextSpan(text: 'This is to officially certify that the emergency repair work of '),
                                        TextSpan(
                                          text: 'Main Distribution Line (Leakage at Chainage 2.4km)',
                                          style: TextStyle(fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : AppColors.textPrimary),
                                        ),
                                        const TextSpan(text: ' at '),
                                        TextSpan(
                                          text: 'Guwahati Zone-I Scheme',
                                          style: TextStyle(fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : AppColors.textPrimary),
                                        ),
                                        const TextSpan(text: ' has been successfully executed and completed by '),
                                        const TextSpan(
                                          text: 'ABC CONSTRUCTIONS',
                                          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
                                        ),
                                        const TextSpan(text: ' under the direct supervision of the assigned Executive Engineer.'),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 40),
                                  
                                  _buildDetailRow('INCIDENT ID', 'INC-2026-0034', isDarkMode),
                                  _buildDetailRow('COMMENCEMENT', '10 MAR 2026', isDarkMode),
                                  _buildDetailRow('COMPLETION', '15 MAR 2026', isDarkMode),
                                  _buildDetailRow('TOTAL BUDGET', '₹ 1,24,500.00', isDarkMode, highlight: true),
                                  _buildDetailRow('QUALITY RATING', '4.9 / 5.0', isDarkMode, color: AppColors.success),

                                  const SizedBox(height: 64),

                                  // Signatures
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildSignature('Ramesh Kumar', 'Contractor Rep.', isDarkMode),
                                      _buildSignature('Dr. A.K. Sarma', 'Executive Engineer', isDarkMode),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Footer
                                  Text(
                                    'VERIFIED DOCUMENT • ID: PHE-CERT-9901 • ${DateTime.now().year}',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isDarkMode ? Colors.white12 : AppColors.textSecondary.withOpacity(0.5), letterSpacing: 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode, {bool highlight = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white24 : AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color ?? (highlight ? AppColors.primary : (isDarkMode ? Colors.white70 : AppColors.textPrimary)))),
        ],
      ),
    );
  }

  Widget _buildSignature(String name, String role, bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 1,
          color: isDarkMode ? Colors.white12 : AppColors.textPrimary.withOpacity(0.1),
        ),
        const SizedBox(height: 12),
        Text(
          name.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.2),
        ),
        Text(
          role.toUpperCase(),
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: isDarkMode ? Colors.white24 : AppColors.textSecondary, letterSpacing: 0.5),
        ),
      ],
    );
  }
}
