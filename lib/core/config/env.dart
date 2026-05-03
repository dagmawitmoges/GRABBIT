import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Env {
  static String get baseUrl {
    final envUrl = dotenv.env['BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return kIsWeb ? 'https://grabbit-1.onrender.com' : 'http://localhost:3000';
  }

  /// Project URL from Supabase Dashboard → Settings → API.
  static String? get supabaseUrl {
    final v = dotenv.env['SUPABASE_URL']?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  /// `anon` `public` key — safe in the app; never use service_role here.
  static String? get supabaseAnonKey {
    final v = dotenv.env['SUPABASE_ANON_KEY']?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  /// True when `.env` has keys **or** [Supabase.initialize] already ran (e.g. after
  /// hot reload `flutter_dotenv` can be empty while the client still works).
  static bool get hasSupabase {
    if (supabaseUrl != null && supabaseAnonKey != null) return true;
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  static String get environment =>
      dotenv.env['ENV'] ?? 'development';

  static bool get isDevelopment => environment == 'development';
}