import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/widgets/error_banner.dart';
import '../provider/auth_provider.dart';
import '../widgets/grabbit_logo_mark.dart';

class OtpScreen extends ConsumerStatefulWidget {
  /// Phone (Supabase) or email (legacy). If null, uses profile from session.
  final String? recipientOverride;

  const OtpScreen({super.key, this.recipientOverride});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int _resendCooldownSeconds = 60;

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _resendCooldownTimer;
  int _resendSecondsLeft = _resendCooldownSeconds;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  void _startResendCooldown() {
    _resendCooldownTimer?.cancel();
    setState(() => _resendSecondsLeft = _resendCooldownSeconds);
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_resendSecondsLeft <= 1) {
        _resendCooldownTimer?.cancel();
        setState(() => _resendSecondsLeft = 0);
      } else {
        setState(() => _resendSecondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _resendCooldownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text.trim()).join();

  String _recipient() {
    final o = widget.recipientOverride;
    if (o != null && o.isNotEmpty) return o;
    final u = ref.read(authProvider).user;
    if (u == null) return '';
    if (Env.hasSupabase) return u.phone ?? '';
    return u.email;
  }

  Future<void> _onVerify() async {
    if (_otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the full 6-digit code')),
      );
      return;
    }
    final id = _recipient();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing phone/email. Go back and sign in.')),
      );
      return;
    }

    final success =
        await ref.read(authProvider.notifier).verifyOtp(id, _otpCode);
    if (!success || !mounted) return;

    if (Env.hasSupabase) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Verified! Sign in to continue.'),
          backgroundColor: AppTheme.primary,
        ),
      );
      context.go('/login');
    }
  }

  Future<void> _onResend() async {
    if (_resendSecondsLeft > 0) return;
    final id = _recipient();
    if (id.isEmpty) return;
    final success = await ref.read(authProvider.notifier).resendOtp(id);
    if (success && mounted) {
      _startResendCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Env.hasSupabase
                ? 'Code sent again by SMS.'
                : 'OTP resent.',
          ),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  void _onDigitChanged(String value, int index) {
    if (value.length > 1 && index == 0) {
      for (int i = 0; i < value.length && i < 6; i++) {
        _controllers[i].text = value[i];
      }
      _focusNodes[5].requestFocus();
      return;
    }
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final recipient = _recipient();
    final isPhone = Env.hasSupabase;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Center(child: GrabbitLogoSmall(size: 52)),
              const SizedBox(height: 24),
              Text(
                isPhone ? 'Verify your phone' : 'Verify your email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                isPhone
                    ? 'Enter the 6-digit code we sent by SMS to\n$recipient'
                    : 'Enter the code sent to\n$recipient',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textMedium,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 32),
              if (authState.error != null) ...[
                ErrorBanner(message: authState.error!),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 58,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.fieldBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: AppTheme.primary, width: 2),
                        ),
                      ),
                      onChanged: (val) => _onDigitChanged(val, index),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _onVerify,
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isPhone ? 'Verify & continue' : 'Verify'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: (authState.isLoading || _resendSecondsLeft > 0)
                      ? null
                      : _onResend,
                  child: Text(
                    _resendSecondsLeft > 0
                        ? (isPhone
                            ? 'Resend SMS in ${_resendSecondsLeft}s'
                            : 'Resend code in ${_resendSecondsLeft}s')
                        : (isPhone ? 'Resend SMS code' : 'Resend code'),
                    style: TextStyle(
                      color: (_resendSecondsLeft > 0 || authState.isLoading)
                          ? AppTheme.textLight
                          : AppTheme.primary,
                      fontWeight: FontWeight.w600,
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
}
