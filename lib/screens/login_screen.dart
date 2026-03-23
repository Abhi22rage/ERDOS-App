import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/fluent_ui.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _mobileCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final mobile = _mobileCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (mobile.isEmpty || password.isEmpty) {
      _showError('Please enter mobile number and password.');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).login(mobile, password);
      if (mounted) context.go('/home');
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Login Failed',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ],
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
              const SizedBox(height: 40),
              // ── Header Section ──
              _buildModernHeader(isDarkMode),
              const SizedBox(height: 24),

              // ── Form Card ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      FluentCard(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your credentials to access the system',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode
                                    ? Colors.white38
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Mobile Input
                            _buildInputField(
                              label: 'MOBILE NUMBER',
                              controller: _mobileCtrl,
                              icon: LucideIcons.phone,
                              keyboardType: TextInputType.phone,
                              hint: '10-digit number',
                              maxLength: 10,
                              isDarkMode: isDarkMode,
                            ),

                            const SizedBox(height: 24),

                            // Password Input
                            _buildInputField(
                              label: 'PASSWORD',
                              controller: _passwordCtrl,
                              icon: LucideIcons.lock,
                              obscureText: !_showPassword,
                              hint: '••••••••',
                              isDarkMode: isDarkMode,
                              suffix: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? LucideIcons.eyeOff
                                      : LucideIcons.eye,
                                  color: isDarkMode
                                      ? Colors.white24
                                      : AppColors.textSecondary
                                          .withOpacity(0.5),
                                  size: 18,
                                ),
                                onPressed: () => setState(
                                    () => _showPassword = !_showPassword),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'SECURE LOGIN',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(LucideIcons.arrowRight,
                                              size: 16),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Sign up link
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white30
                                    : AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/signup'),
                              child: const Text(
                                'Create one now',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildModernHeader(bool isDarkMode) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.droplets,
              size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        const Text(
          'PHE Guwahati Div-II',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        Text(
          'Emergency Response System',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.white38 : AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    bool obscureText = false,
    int? maxLength,
    TextInputType? keyboardType,
    Widget? suffix,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white38 : AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF0F3F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.transparent),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            maxLength: maxLength,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
                  fontSize: 14),
              prefixIcon: Icon(icon,
                  size: 18,
                  color: isDarkMode
                      ? Colors.white38
                      : AppColors.primary.withOpacity(0.6)),
              suffixIcon: suffix,
              counterText: '',
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }
}
