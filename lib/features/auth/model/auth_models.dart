// ── Register 

class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String subcityId;
  final String? phone;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.subcityId,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'subcity_id': subcityId,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
      };
}

class RegisterResponse {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final bool isVerified;
  final String message;

  RegisterResponse({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isVerified,
    required this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        isVerified: json['is_verified'] as bool,
        message: json['message'] as String,
      );
}

// ── Login ────────────────────────────────────────────────────────────────────

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class AuthUser {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final bool isVerified;

  AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    required this.isVerified,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: json['role'] as String,
        isVerified: json['is_verified'] as bool,
      );
}

class LoginResponse {
  final AuthUser user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  LoginResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresIn: json['expiresIn'] as int,
      );
}

// ── OTP ──────────────────────────────────────────────────────────────────────

class OtpVerifyRequest {
  final String email;
  final String otpCode;

  OtpVerifyRequest({required this.email, required this.otpCode});

  Map<String, dynamic> toJson() => {
        'email': email,
        'otpCode': otpCode,
      };
}