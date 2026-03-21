import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/env.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _create();
    return _instance!;
  }

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
        },
      ),
    );

    dio.interceptors.add(_AuthInterceptor(dio));

    if (Env.isDevelopment) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        logPrint: (o) => debugPrint('[DIO] $o'),    ),
      );
    }

    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await SecureStorage.getRefreshToken();
        if (refreshToken == null) {
          await SecureStorage.clearTokens();
          handler.next(err);
          return;
        }

        final response = await _dio.post(
          ApiConstants.refreshToken,
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Authorization': null}),
        );

        final newAccessToken  = response.data['accessToken']  as String;
        final newRefreshToken = response.data['refreshToken'] as String;

        await SecureStorage.saveTokens(
          accessToken:  newAccessToken,
          refreshToken: newRefreshToken,
        );

        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retried = await _dio.fetch(err.requestOptions);
        handler.resolve(retried);
      } catch (_) {
        await SecureStorage.clearTokens();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
      return;
    }
    handler.next(err);
  }
}