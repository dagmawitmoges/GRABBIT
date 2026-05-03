import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../model/auth_models.dart';
import '../model/location_model.dart';

class AuthService {
  final Dio _dio = DioClient.instance;

  /// Fetch all locations from Supabase (preferred) or legacy REST API.
  Future<List<Location>> getLocations() async {
    if (Env.hasSupabase) {
      try {
        final rows = await Supabase.instance.client
            .from('locations')
            .select()
            .order('sort_order', ascending: true);
        final list = rows as List<dynamic>;
        return list
            .map((e) => Location.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } on PostgrestException catch (e) {
        throw e.message;
      } catch (e) {
        throw 'Could not load locations: $e';
      }
    }
    try {
      final response = await _dio.get(ApiConstants.locations);
      final List data = response.data as List;
      return data
          .map((e) => Location.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Register a new user
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(ApiConstants.register, data: request.toJson());
      return RegisterResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Login with email and password
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(ApiConstants.login, data: request.toJson());
      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify OTP code
  Future<String> verifyOtp(OtpVerifyRequest request) async {
    try {
      final response = await _dio.post(ApiConstants.verifyOtp, data: request.toJson());
      return response.data['message'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Resend OTP code
  Future<String> resendOtp(String email) async {
    try {
      final response = await _dio.post(ApiConstants.resendOtp, data: {'email': email});
      return response.data['message'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Centralized error handler
  String _handleError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    switch (e.response?.statusCode) {
      case 400: return 'Invalid input. Please check your details.';
      case 401: return 'Invalid email or password.';
      case 403: return 'Account not verified. Please verify your email.';
      case 409: return 'Email already registered.';
      case 422:
        if (data is Map && data['errors'] != null) {
          final errors = data['errors'] as List;
          return errors.map((e) => e['msg']).join(', ');
        }
        return 'Validation failed. Please check your input.';
      default: return 'Something went wrong. Please try again.';
    }
  }
}
