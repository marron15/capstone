import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://localhost/sample_api/users';

  static Future<LoginResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Login.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return LoginResult(
          success: true,
          message: responseData['message'],
          userData: UserData.fromJson(responseData['data']),
          accessToken: responseData['access_token'],
          refreshToken: responseData['refresh_token'],
        );
      } else {
        return LoginResult(
          success: false,
          message: responseData['message'] ?? 'Login failed',
          userData: null,
        );
      }
    } catch (e) {
      return LoginResult(
        success: false,
        message: 'Network error: ${e.toString()}',
        userData: null,
      );
    }
  }

  static Future<SignupResult> signup(SignupData signupData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Signup.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(signupData.toJson()),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          responseData['success'] == true) {
        return SignupResult(
          success: true,
          message: responseData['message'],
          userData: UserData.fromJson(responseData['data']),
          accessToken: responseData['access_token'],
          refreshToken: responseData['refresh_token'],
        );
      } else {
        return SignupResult(
          success: false,
          message: responseData['message'] ?? 'Signup failed',
          userData: null,
        );
      }
    } catch (e) {
      return SignupResult(
        success: false,
        message: 'Network error: ${e.toString()}',
        userData: null,
      );
    }
  }

  static Future<LogoutResult> logout({int? userId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Logout.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({if (userId != null) 'user_id': userId}),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return LogoutResult(success: true, message: responseData['message']);
      } else {
        return LogoutResult(
          success: false,
          message: responseData['message'] ?? 'Logout failed',
        );
      }
    } catch (e) {
      return LogoutResult(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  static Future<TokenValidationResult> validateToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ValidateToken.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token}),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return TokenValidationResult(
          success: true,
          message: responseData['message'],
          userData: UserData.fromJson(responseData['data']),
        );
      } else {
        return TokenValidationResult(
          success: false,
          message: responseData['message'] ?? 'Token validation failed',
          userData: null,
        );
      }
    } catch (e) {
      return TokenValidationResult(
        success: false,
        message: 'Network error: ${e.toString()}',
        userData: null,
      );
    }
  }

  static Future<RefreshTokenResult> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/RefreshToken.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return RefreshTokenResult(
          success: true,
          message: responseData['message'],
          accessToken: responseData['access_token'],
          refreshToken: responseData['refresh_token'],
          userData: UserData.fromJson(responseData['data']),
        );
      } else {
        return RefreshTokenResult(
          success: false,
          message: responseData['message'] ?? 'Token refresh failed',
          accessToken: null,
          refreshToken: null,
          userData: null,
        );
      }
    } catch (e) {
      return RefreshTokenResult(
        success: false,
        message: 'Network error: ${e.toString()}',
        accessToken: null,
        refreshToken: null,
        userData: null,
      );
    }
  }
}

class LoginResult {
  final bool success;
  final String message;
  final UserData? userData;
  final String? accessToken;
  final String? refreshToken;

  LoginResult({
    required this.success,
    required this.message,
    this.userData,
    this.accessToken,
    this.refreshToken,
  });
}

class SignupResult {
  final bool success;
  final String message;
  final UserData? userData;
  final String? accessToken;
  final String? refreshToken;

  SignupResult({
    required this.success,
    required this.message,
    this.userData,
    this.accessToken,
    this.refreshToken,
  });
}

class LogoutResult {
  final bool success;
  final String message;

  LogoutResult({required this.success, required this.message});
}

class TokenValidationResult {
  final bool success;
  final String message;
  final UserData? userData;

  TokenValidationResult({
    required this.success,
    required this.message,
    this.userData,
  });
}

class RefreshTokenResult {
  final bool success;
  final String message;
  final String? accessToken;
  final String? refreshToken;
  final UserData? userData;

  RefreshTokenResult({
    required this.success,
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.userData,
  });
}

class UserData {
  final int userId;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;

  UserData({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['user_id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      fullName: json['full_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
    };
  }
}

class SignupData {
  final String firstName;
  final String lastName;
  final String? middleName;
  final String email;
  final String password;
  final String? birthdate;
  final String? address;
  final String? phoneNumber;

  SignupData({
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.email,
    required this.password,
    this.birthdate,
    this.address,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'email': email,
      'password': password,
      'birthdate': birthdate,
      'address': address,
      'phone_number': phoneNumber,
    };
  }
}
