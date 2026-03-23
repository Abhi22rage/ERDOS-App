import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/fluent_ui.dart';

const _roles = [
  {'label': 'Khalasi', 'value': 'khalasi'},
  {'label': 'Junior Engineer (JE)', 'value': 'je'},
  {'label': 'Asst. Engineer (AE)', 'value': 'ae'},
  {'label': 'Asst. Exec. Engineer (AEE)', 'value': 'aee'},
  {'label': 'Executive Engineer (EE)', 'value': 'ee'},
  {'label': 'Supdt. Engineer (SE)', 'value': 'se'},
  {'label': 'Contractor', 'value': 'contractor'},
];

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedRole = 'khalasi';
  bool _showPassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final name = _nameCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (name.isEmpty || mobile.isEmpty || password.isEmpty) {
      _showError('Error', 'Please fill all fields.');
      return;
    }
    if (mobile.length != 10) {
      _showError('Error', 'Enter a valid 10-digit mobile number.');
      return;
    }
    if (password.length < 6) {
      _showError('Error', 'Password must be at least 6 characters.');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).signup({
        'name': name,
        'mobile': mobile,
        'password': password,
        'role': _selectedRole,
      });
      if (mounted) context.go('/home');
    } catch (e) {
      _showError('Sign Up Failed', e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
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
              const SizedBox(height: 20),
              // ── Header Section ──
              _buildModernHeader(isDarkMode),

              const SizedBox(height: 24),

              // ── Tab Switcher ──
              _buildTabSwitcher(isDarkMode),

              // ── Form ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: FluentCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: isDarkMode
                                ? Colors.white
                                : AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join the Emergency Response team',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.white38
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Name Input
                        _buildInputField(
                          label: 'Full Name',
                          controller: _nameCtrl,
                          icon: LucideIcons.user,
                          hint: 'Enter your name',
                          isDarkMode: isDarkMode,
                        ),

                        const SizedBox(height: 20),

                        // Mobile Input
                        _buildInputField(
                          label: 'Mobile Number',
                          controller: _mobileCtrl,
                          icon: LucideIcons.phone,
                          keyboardType: TextInputType.phone,
                          hint: '10-digit number',
                          maxLength: 10,
                          isDarkMode: isDarkMode,
                        ),

                        const SizedBox(height: 20),

                        // Role Dropdown
                        _buildDropdownField(isDarkMode),

                        const SizedBox(height: 20),

                        // Password Input
                        _buildInputField(
                          label: 'Password',
                          controller: _passwordCtrl,
                          icon: LucideIcons.lock,
                          obscureText: !_showPassword,
                          hint: 'Min. 6 characters',
                          isDarkMode: isDarkMode,
                          suffix: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                              color: isDarkMode
                                  ? Colors.white38
                                  : AppColors.textSecondary,
                              size: 18,
                            ),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Signup Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleSignup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 8,
                              shadowColor: AppColors.primary.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
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
                                : const Text(
                                    'Register Account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Login link
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white38
                                      : AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: const Text(
                                  'Log in',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
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

  Widget _buildModernHeader(bool isDarkMode) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.droplets,
              size: 32, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        const Text(
          'PHE Assam',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSwitcher(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.go('/login'),
              child: Container(
                color: Colors.transparent,
                child: Text(
                  'Sign In',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        isDarkMode ? Colors.white38 : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13),
              ),
            ),
          ),
        ],
      ),
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
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white38 : AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
                  fontSize: 13),
              prefixIcon: Icon(icon,
                  size: 16,
                  color: isDarkMode
                      ? Colors.white38
                      : AppColors.primary.withOpacity(0.6)),
              suffixIcon: suffix,
              counterText: '',
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Official Role',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white38 : AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
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
          child: DropdownButtonFormField<String>(
            value: _selectedRole,
            dropdownColor: isDarkMode ? const Color(0xFF1A1F26) : Colors.white,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(LucideIcons.briefcase,
                  size: 16,
                  color: isDarkMode
                      ? Colors.white38
                      : AppColors.primary.withOpacity(0.6)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _roles
                .map((r) => DropdownMenuItem(
                      value: r['value'],
                      child: Text(r['label']!),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedRole = v ?? 'khalasi'),
          ),
        ),
      ],
    );
  }
}
