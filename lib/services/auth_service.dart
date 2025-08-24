import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://localhost/sample_api/customers';

  static Future<LoginResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Login.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      // Debug logging
      print('🔍 Login API Response: $responseData');
      print('🔍 Customer data: ${responseData['data']}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return LoginResult(
          success: true,
          message: responseData['message'],
          customerData: CustomerData.fromJson(responseData['data']),
          accessToken: responseData['access_token'],
          refreshToken: responseData['refresh_token'],
        );
      } else {
        return LoginResult(
          success: false,
          message: responseData['message'] ?? 'Login failed',
          customerData: null,
        );
      }
    } catch (e) {
      return LoginResult(
        success: false,
        message: 'Network error: ${e.toString()}',
        customerData: null,
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
          customerData: CustomerData.fromJson(responseData['data']),
          accessToken: responseData['access_token'],
          refreshToken: responseData['refresh_token'],
        );
      } else {
        return SignupResult(
          success: false,
          message: responseData['message'] ?? 'Signup failed',
          customerData: null,
        );
      }
    } catch (e) {
      return SignupResult(
        success: false,
        message: 'Network error: ${e.toString()}',
        customerData: null,
      );
    }
  }

  static Future<LogoutResult> logout({int? customerId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Logout.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({if (customerId != null) 'customer_id': customerId}),
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
          customerData: CustomerData.fromJson(responseData['data']),
        );
      } else {
        return TokenValidationResult(
          success: false,
          message: responseData['message'] ?? 'Token validation failed',
          customerData: null,
        );
      }
    } catch (e) {
      return TokenValidationResult(
        success: false,
        message: 'Network error: ${e.toString()}',
        customerData: null,
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
          customerData: CustomerData.fromJson(responseData['data']),
        );
      } else {
        return RefreshTokenResult(
          success: false,
          message: responseData['message'] ?? 'Token refresh failed',
          accessToken: null,
          refreshToken: null,
          customerData: null,
        );
      }
    } catch (e) {
      return RefreshTokenResult(
        success: false,
        message: 'Network error: ${e.toString()}',
        accessToken: null,
        refreshToken: null,
        customerData: null,
      );
    }
  }
}

class LoginResult {
  final bool success;
  final String message;
  final CustomerData? customerData;
  final String? accessToken;
  final String? refreshToken;

  LoginResult({
    required this.success,
    required this.message,
    this.customerData,
    this.accessToken,
    this.refreshToken,
  });
}

class SignupResult {
  final bool success;
  final String message;
  final CustomerData? customerData;
  final String? accessToken;
  final String? refreshToken;

  SignupResult({
    required this.success,
    required this.message,
    this.customerData,
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
  final CustomerData? customerData;

  TokenValidationResult({
    required this.success,
    required this.message,
    this.customerData,
  });
}

class RefreshTokenResult {
  final bool success;
  final String message;
  final String? accessToken;
  final String? refreshToken;
  final CustomerData? customerData;

  RefreshTokenResult({
    required this.success,
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.customerData,
  });
}

class CustomerData {
  final int customerId;
  final String email;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String fullName;
  final String? phoneNumber;
  final String? birthdate;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactNumber;
  final String? img;
  final String? createdAt;

  CustomerData({
    required this.customerId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.fullName,
    this.phoneNumber,
    this.birthdate,
    this.address,
    this.emergencyContactName,
    this.emergencyContactNumber,
    this.img,
    this.createdAt,
  });

  factory CustomerData.fromJson(Map<String, dynamic> json) {
    // Debug: Print the exact types we're receiving
    print('🔍 CustomerData.fromJson received: $json');
    json.forEach((key, value) {
      print('🔍 $key: ${value.runtimeType} = $value');
    });

    return CustomerData(
      customerId: _safeInt(json['customer_id'] ?? json['id']),
      email: _safeString(json['email']) ?? '',
      firstName: _safeString(json['first_name']) ?? '',
      lastName: _safeString(json['last_name']) ?? '',
      middleName: _safeString(json['middle_name']),
      fullName: _safeString(json['full_name']) ?? '',
      phoneNumber: _safeString(json['phone_number']),
      birthdate: _safeString(json['birthdate']),
      address: _safeString(json['address']),
      emergencyContactName: _safeString(json['emergency_contact_name']),
      emergencyContactNumber: _safeString(json['emergency_contact_number']),
      img: _safeString(json['img']),
      createdAt: _safeString(json['created_at']),
    );
  }

  // Helper method to safely convert to int
  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Helper method to safely convert to String
  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'birthdate': birthdate,
      'address': address,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_number': emergencyContactNumber,
      'img': img,
      'created_at': createdAt,
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
  final String? emergencyContactName;
  final String? emergencyContactNumber;

  SignupData({
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.email,
    required this.password,
    this.birthdate,
    this.address,
    this.phoneNumber,
    this.emergencyContactName,
    this.emergencyContactNumber,
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
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_number': emergencyContactNumber,
    };
  }
}
