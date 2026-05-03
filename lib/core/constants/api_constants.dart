class ApiConstants {
  // Auth
  static const String register     = '/api/auth/register';
  static const String login        = '/api/auth/login';
  static const String verifyOtp    = '/api/auth/verify-otp';
  static const String resendOtp    = '/api/auth/resend-otp';
  static const String refreshToken = '/api/auth/refresh-token';

  // User
  static const String me           = '/api/me';

  // Public
  static const String locations = '/api/locations';
  static const String deals        = '/api/deals';
  static const String categories   = '/api/admin/categories';
  static const String appConfig    = '/api/admin/app-config';

  // Orders
  static const String orders       = '/api/orders';

  // Upload
  static const String upload       = '/api/upload';
}
