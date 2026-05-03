import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/widgets/error_banner.dart';
import '../provider/auth_provider.dart';
import '../widgets/grabbit_logo_mark.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).login(
          _emailOrPhoneController.text.trim(),
          _passwordController.text,
        );
    if (!success || !mounted) return;
    final user = ref.read(authProvider).user;
    if (user != null && !user.isVerified) {
      context.push('/otp', extra: Env.hasSupabase ? user.phone : user.email);
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    const GrabbitLogoSmall(size: 48),
                    const Spacer(),
                    Text(
                      'v1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textLight,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Text(
                  'Sign In',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back — find your next deal.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                ),
                const SizedBox(height: 32),
                if (authState.error != null) ...[
                  ErrorBanner(message: authState.error!),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailOrPhoneController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: Env.hasSupabase ? 'Email or phone' : 'Email',
                    hintText: Env.hasSupabase ? 'you@email.com or +251…' : null,
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        color: AppTheme.textLight),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return Env.hasSupabase
                          ? 'Email or phone is required'
                          : 'Email is required';
                    }
                    if (!Env.hasSupabase &&
                        !val.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppTheme.textLight),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textLight,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password reset is not set up yet.'),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _onLogin,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppTheme.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'Or',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLight,
                            ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppTheme.divider)),
                  ],
                ),
                const SizedBox(height: 20),
                _SocialPillButton(
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Continue with Google',
                  onTap: () => _comingSoon(context),
                ),
                const SizedBox(height: 12),
                _SocialPillButton(
                  icon: Icons.facebook_rounded,
                  label: 'Continue with Facebook',
                  onTap: () => _comingSoon(context),
                ),
                const SizedBox(height: 28),
                Center(
                  child: GestureDetector(
                    onTap: () => context.push('/register'),
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMedium,
                            ),
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          TextSpan(
                            text: 'Sign up',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    '© ${DateTime.now().year} Grabbit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textLight,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon.')),
    );
  }
}

class _SocialPillButton extends StatelessWidget {
  const _SocialPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.fieldBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.textDark, size: 26),
              const SizedBox(width: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
