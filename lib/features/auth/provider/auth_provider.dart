import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../model/auth_models.dart';
import '../model/subcity_model.dart';
import '../service/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final subcitiesProvider = FutureProvider<List<Subcity>>((ref) async {
  return ref.read(authServiceProvider).getSubcities();
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

  Future<void> _restoreSession() async {
    final token = await SecureStorage.getAccessToken();
    if (token == null) {
      state = state.copyWith(isInitialized: true);
      return;
    }
    try {
      final response =
          await DioClient.instance.get(ApiConstants.me);
      final user = AuthUser.fromJson(
          response.data as Map<String, dynamic>);
      state = state.copyWith(user: user, isInitialized: true);
    } on DioException catch (_) {
      await SecureStorage.clearTokens();
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authService.login(
        LoginRequest(email: email, password: password),
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

  Future<String?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String subcityId,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authService.register(
        RegisterRequest(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          subcityId: subcityId,
          phone: phone,
        ),
      );
      state = state.copyWith(isLoading: false);
      return response.email;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> verifyOtp(String email, String otpCode) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.verifyOtp(
        OtpVerifyRequest(email: email, otpCode: otpCode),
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void logout() async {
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