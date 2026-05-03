import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import '../../../core/config/env.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../model/auth_models.dart';
import '../model/location_model.dart';
import '../service/auth_service.dart';
import '../utils/auth_identifiers.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final locationsProvider = FutureProvider<List<Location>>((ref) async {
  return ref.read(authServiceProvider).getLocations();
});

class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  /// Home / protected tabs require a verified account (SMS OTP completed for Supabase).
  bool get isFullyAuthenticated => user != null && user!.isVerified;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AuthUser? user,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _restoreSession();
  }

  Future<AuthUser?> _loadProfileRow(String userId) async {
    final row = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return AuthUser.fromProfile(Map<String, dynamic>.from(row));
  }

  AuthUser _fallbackUserFromSignup({
    required User sbUser,
    required String email,
    required String phoneNorm,
    required String firstName,
    required String lastName,
  }) {
    final name = '${firstName.trim()} ${lastName.trim()}'.trim();
    return AuthUser(
      id: sbUser.id,
      fullName: name.isEmpty ? 'User' : name,
      email: sbUser.email ?? email,
      phone: phoneNorm,
      role: 'CUSTOMER',
      isVerified: false,
    );
  }

  Future<void> _restoreSession() async {
    if (Env.hasSupabase) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        state = state.copyWith(isInitialized: true);
        return;
      }
      try {
        final user = await _loadProfileRow(session.user.id);
        state = state.copyWith(user: user, isInitialized: true);
      } catch (_) {
        state = state.copyWith(isInitialized: true);
      }
      return;
    }

    final token = await SecureStorage.getAccessToken();
    if (token == null) {
      state = state.copyWith(isInitialized: true);
      return;
    }
    try {
      final response = await DioClient.instance.get(ApiConstants.me);
      final user = AuthUser.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(user: user, isInitialized: true);
    } on DioException catch (_) {
      await SecureStorage.clearTokens();
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<bool> login(String emailOrPhone, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (Env.hasSupabase) {
        final email = loginEmailFromInput(emailOrPhone);
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final uid = Supabase.instance.client.auth.currentUser!.id;
        final user = await _loadProfileRow(uid);
        state = state.copyWith(user: user, isLoading: false, isInitialized: true);
        return true;
      }

      final response = await _authService.login(
        LoginRequest(email: emailOrPhone.trim(), password: password),
      );
      await SecureStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      state = state.copyWith(
        user: response.user,
        isLoading: false,
        isInitialized: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Returns [phone] for OTP screen (Supabase) or [email] (legacy API).
  Future<String?> register({
    required String firstName,
    required String lastName,
    required String? emailOptional,
    required String phone,
    required String password,
    required String locationId,
    required bool agreedToTerms,
  }) async {
    if (!agreedToTerms) {
      state = state.copyWith(error: 'Please accept the Terms & Privacy Policy.');
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (Env.hasSupabase) {
        final phoneNorm = normalizePhoneForStorage(phone);
        if (phoneNorm.length < 10) {
          state = state.copyWith(
            isLoading: false,
            error: 'Enter a valid phone number (e.g. +2519…).',
          );
          return null;
        }

        final email = (emailOptional != null && emailOptional.trim().isNotEmpty)
            ? emailOptional.trim()
            : syntheticEmailFromPhone(phoneNorm);

        late final AuthResponse res;
        try {
          res = await Supabase.instance.client.auth.signUp(
            email: email,
            password: password,
            data: {
              'first_name': firstName.trim(),
              'last_name': lastName.trim(),
              'phone': phoneNorm,
              'location_id': locationId,
            },
          );
        } on AuthException catch (e) {
          state = state.copyWith(
            isLoading: false,
            error: _formatAuthSignupError(e),
          );
          return null;
        }

        if (res.session == null) {
          state = state.copyWith(
            isLoading: false,
            error: 'Sign up did not return a session. In Supabase: Authentication → '
                'Providers → Email — disable "Confirm email" for this flow, or confirm your email.',
          );
          return null;
        }

        final sbUser = res.user!;
        final profileUser = await _loadProfileRow(sbUser.id);
        final user = profileUser ??
            _fallbackUserFromSignup(
              sbUser: sbUser,
              email: email,
              phoneNorm: phoneNorm,
              firstName: firstName,
              lastName: lastName,
            );
        state = state.copyWith(user: user, isLoading: false);

        final fnRes = await Supabase.instance.client.functions.invoke(
          'send-phone-otp',
          body: {'phone': phoneNorm},
        );
        if (fnRes.status != 200) {
          final msg = _fnErrorMessage(fnRes.data);
          state = state.copyWith(isLoading: false, error: msg);
          return null;
        }

        return phoneNorm;
      }

      final email = emailOptional?.trim() ?? '';
      if (email.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Email is required for legacy API sign up.',
        );
        return null;
      }

      final response = await _authService.register(
        RegisterRequest(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          locationId: locationId,
          phone: phone,
        ),
      );
      state = state.copyWith(isLoading: false);
      return response.email;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _formatAuthSignupError(e));
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  String _formatAuthSignupError(AuthException e) {
    final code = e.statusCode;
    final msg = e.message;
    if (code == '422' || msg.toLowerCase().contains('already')) {
      return 'This email or phone is already registered. Try signing in, or delete the test user in Supabase → Authentication → Users.';
    }
    if (msg.toLowerCase().contains('email') &&
        msg.toLowerCase().contains('invalid')) {
      return '$msg Try adding a real email in the optional email field, or contact support.';
    }
    return msg.isNotEmpty ? msg : 'Sign up failed ($code). Check password rules in Supabase (Authentication → Providers → Email).';
  }

  String _fnErrorMessage(dynamic data) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'Could not send verification SMS. Try again.';
  }

  /// [identifier] is phone (Supabase) or email (legacy).
  Future<bool> verifyOtp(String identifier, String otpCode) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (Env.hasSupabase) {
        final res = await Supabase.instance.client.functions.invoke(
          'verify-phone-otp',
          body: {'phone': identifier, 'otpCode': otpCode},
        );
        if (res.status != 200) {
          state = state.copyWith(
            isLoading: false,
            error: _fnErrorMessage(res.data),
          );
          return false;
        }
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid == null) {
          state = state.copyWith(isLoading: false, error: 'Session lost. Sign in again.');
          return false;
        }
        final user = await _loadProfileRow(uid);
        state = state.copyWith(user: user, isLoading: false);
        return true;
      }

      await _authService.verifyOtp(
        OtpVerifyRequest(email: identifier, otpCode: otpCode),
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> resendOtp(String identifier) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (Env.hasSupabase) {
        final res = await Supabase.instance.client.functions.invoke(
          'send-phone-otp',
          body: <String, dynamic>{},
        );
        if (res.status != 200) {
          state = state.copyWith(
            isLoading: false,
            error: _fnErrorMessage(res.data),
          );
          return false;
        }
        state = state.copyWith(isLoading: false);
        return true;
      }

      await _authService.resendOtp(identifier);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    if (Env.hasSupabase) {
      await Supabase.instance.client.auth.signOut();
    }
    await SecureStorage.clearTokens();
    state = const AuthState(isInitialized: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authServiceProvider)),
);
