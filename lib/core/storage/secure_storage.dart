import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // Web uses SharedPreferences, mobile uses FlutterSecureStorage
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
    } else {
      const s = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      await s.write(key: _accessTokenKey, value: accessToken);
      await s.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  static Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    }
    const s = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    return s.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    }
    const s = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    return s.read(key: _refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
    } else {
      const s = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      await s.delete(key: _accessTokenKey);
      await s.delete(key: _refreshTokenKey);
    }
  }
}