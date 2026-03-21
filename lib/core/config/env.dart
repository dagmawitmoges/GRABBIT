import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://localhost:3000';

  static String get environment =>
      dotenv.env['ENV'] ?? 'development';

  static bool get isDevelopment => environment == 'development';
}