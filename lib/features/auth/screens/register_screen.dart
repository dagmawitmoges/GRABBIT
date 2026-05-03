import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/widgets/error_banner.dart';
import '../model/location_model.dart';
import '../provider/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  Location? _selectedLocation;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your area / location')),
      );
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Privacy Policy'),
        ),
      );
      return;
    }

    final otpId = await ref.read(authProvider.notifier).register(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          emailOptional: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          locationId: _selectedLocation!.id,
          agreedToTerms: _agreedToTerms,
        );

    if (otpId != null && mounted) {
      context.push('/otp', extra: otpId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final locationsAsync = ref.watch(locationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join Grabbit and start saving today',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                ),
                const SizedBox(height: 28),
                if (authState.error != null) ...[
                  ErrorBanner(message: authState.error!),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First name',
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: AppTheme.textLight),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last name',
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: AppTheme.textLight),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '+2519…',
                    prefixIcon: Icon(Icons.phone_outlined,
                        color: AppTheme.textLight),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Phone is required for SMS verification';
                    }
                    if (val.replaceAll(RegExp(r'\D'), '').length < 9) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: Env.hasSupabase
                        ? 'Email (optional)'
                        : 'Email',
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: AppTheme.textLight),
                  ),
                  validator: (val) {
                    if (!Env.hasSupabase &&
                        (val == null || val.isEmpty)) {
                      return 'Email is required';
                    }
                    if (val != null &&
                        val.isNotEmpty &&
                        !val.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                if (Env.hasSupabase) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: AppTheme.primary.withValues(alpha: 0.9)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'We’ll send a 6-digit code by SMS. Email is optional and used for account recovery.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textMedium,
                                height: 1.35,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                locationsAsync.when(
                  data: (locations) {
                    if (locations.isEmpty) {
                      return Text(
                        'No locations to choose from. Seed `locations` in Supabase and '
                        'allow public SELECT (migration 20260521100000_locations_public_read.sql).',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      );
                    }
                    return DropdownButtonFormField<Location>(
                      value: _selectedLocation,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(Icons.location_on_outlined,
                            color: AppTheme.textLight),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      items: locations
                          .map((loc) => DropdownMenuItem(
                                value: loc,
                                child: Text(loc.label),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedLocation = val),
                      validator: (_) => _selectedLocation == null
                          ? 'Select your location'
                          : null,
                    );
                  },
                  loading: () => const LinearProgressIndicator(
                    color: AppTheme.primary,
                    minHeight: 3,
                  ),
                  error: (err, _) => Text(
                    'Failed to load locations: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 14),
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
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (val.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppTheme.textLight),
                    suffixIcon: Icon(
                      _passwordController.text.isNotEmpty &&
                              _confirmPasswordController.text ==
                                  _passwordController.text
                          ? Icons.check_circle_rounded
                          : null,
                      color: AppTheme.primary,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (val) {
                    if (val != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (v) =>
                          setState(() => _agreedToTerms = v ?? false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'I agree to the Terms & Conditions and Privacy Policy.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textMedium,
                                    height: 1.35,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _onRegister,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMedium,
                            ),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign In',
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
