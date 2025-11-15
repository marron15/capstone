import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  // Base URL for admin API (Production)
  // Note: Change back to localhost if testing locally
  static const String baseUrl = 'https://rnrgym.com/gym_api/admin_account';

  // Store admin data locally
  static const String _adminKey = 'admin_data';
  static const String _tokenKey = 'admin_token';
  static const String _refreshTokenKey = 'admin_refresh_token';

  // Signup new admin
  static Future<Map<String, dynamic>> signupAdmin({
    required String firstName,
    required String lastName,
    String? middleName,
    required String password,
    String? dateOfBirth,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      // Convert date format if provided
      String? formattedDate;
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        // Parse the date from DD/MM/YYYY format to YYYY-MM-DD
        List<String> dateParts = dateOfBirth.split('/');
        if (dateParts.length == 3) {
          formattedDate =
              '${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}';
        }
      }

      // Prepare request body
      Map<String, dynamic> requestBody = {
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
        'created_by': 'system',
      };

      // Add optional fields
      if (middleName != null && middleName.isNotEmpty) {
        requestBody['middle_name'] = middleName;
      }
      // Always include date_of_birth - PHP backend will handle null values
      requestBody['date_of_birth'] = formattedDate;
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        requestBody['phone_number'] = phoneNumber;
      }
      if (email != null && email.isNotEmpty) {
        requestBody['email'] = email;
      }

      // Creating admin account

      final response = await http.post(
        Uri.parse('$baseUrl/Signup.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Do not log response body to avoid leaking sensitive data

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true) {
          // Store admin data and tokens locally
          if (result['admin'] != null && result['access_token'] != null) {
            await _storeAdminData(
              result['admin'],
              result['access_token'],
              result['refresh_token'] ?? '',
            );
          }

          // Admin created
          return result;
        } else {
          debugPrint('❌ Admin creation failed: ${result['message']}');
          return result;
        }
      } else {
        // Gracefully handle error payloads (e.g., 400/401) and surface backend message
        debugPrint('❌ Admin signup HTTP error: ${response.statusCode}');
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            return {
              'success': false,
              'message':
                  decoded['message'] ?? 'HTTP error: ${response.statusCode}',
            };
          }
        } catch (_) {
          // ignore decode failures and fall back to generic message
        }
        return {
          'success': false,
          'message': 'HTTP error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Exception creating admin: $e');
      return {'success': false, 'message': 'Error creating admin: $e'};
    }
  }

  // Login admin
  static Future<Map<String, dynamic>> loginAdmin({
    required String contactNumber,
    required String password,
  }) async {
    try {
      // Logging in admin

      final response = await http.post(
        Uri.parse('$baseUrl/Login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': contactNumber, 'password': password}),
      );

      // Avoid logging full response body

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true) {
          // Store admin data and tokens locally
          if (result['admin'] != null && result['access_token'] != null) {
            await _storeAdminData(
              result['admin'],
              result['access_token'],
              result['refresh_token'] ?? '',
            );
          }

          // Admin login successful
          return result;
        } else {
          debugPrint('❌ Admin login failed: ${result['message']}');
          return result;
        }
      } else {
        debugPrint('❌ Admin login HTTP error: ${response.statusCode}');
        // Parse server error to show which field is wrong
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            return {
              'success': false,
              'message': decoded['message'] ?? 'Login failed',
              'field': decoded['field'], // 'phone' | 'password'
            };
          }
        } catch (_) {}
        return {
          'success': false,
          'message':
              response.statusCode == 401
                  ? 'Login failed'
                  : 'HTTP error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Exception logging in admin: $e');
      return {'success': false, 'message': 'Error logging in admin: $e'};
    }
  }

  // Get all admins
  static Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getAllAdmin.php'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result is List) {
          // Normalize admins list
          final admins = List<Map<String, dynamic>>.from(result);

          return admins;
        }
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error getting admins: $e');
      return [];
    }
  }

  // Get admin by ID
  static Future<Map<String, dynamic>?> getAdminById(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getAdminByID.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result is Map<String, dynamic>) {
          return result;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting admin by ID: $e');
      return null;
    }
  }

  // Update admin
  static Future<bool> updateAdmin(int id, Map<String, dynamic> data) async {
    try {
      // Map Flutter field names to PHP backend field names
      Map<String, dynamic> mappedData = {
        'id': id,
        'first_name': data['firstName'] ?? data['first_name'],
        'middle_name': data['middleName'] ?? data['middle_name'],
        'last_name': data['lastName'] ?? data['last_name'],
        'date_of_birth': data['dateOfBirth'] ?? data['date_of_birth'],
        'phone_number': data['phoneNumber'] ?? data['phone_number'],
        'email': data['email'] ?? data['email_address'] ?? data['emailAddress'],
        'updated_by': data['updatedBy'] ?? 'system',
        'updated_at': data['updatedAt'] ?? DateTime.now().toIso8601String(),
      };

      // Include password if provided
      if (data['password'] != null && data['password'] != '********') {
        mappedData['password'] = data['password'];
      }

      // Updating admin

      final response = await http.post(
        Uri.parse('$baseUrl/updateAdminByID.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(mappedData),
      );

      // Hidden response body

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error updating admin: $e');
      return false;
    }
  }

  // Archive admin (soft delete)
  static Future<bool> deleteAdmin(int id) async {
    try {
      // Archiving admin with ID

      final response = await http.post(
        Uri.parse('$baseUrl/deleteAdminByID.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );

      // Hidden response body

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error archiving admin: $e');
      return false;
    }
  }

  // Restore admin (activate)
  static Future<bool> restoreAdmin(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/activateAdminByID.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error restoring admin: $e');
      return false;
    }
  }

  // Store admin data locally
  static Future<void> _storeAdminData(
    Map<String, dynamic> admin,
    String accessToken,
    String refreshToken,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_adminKey, jsonEncode(admin));
      await prefs.setString(_tokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      assert(() {
        debugPrint('✅ Admin data stored locally');
        return true;
      }());
    } catch (e) {
      debugPrint('❌ Error storing admin data locally: $e');
    }
  }

  // Get stored admin data
  static Future<Map<String, dynamic>?> getStoredAdminData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminData = prefs.getString(_adminKey);
      if (adminData != null) {
        return jsonDecode(adminData);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting stored admin data: $e');
      return null;
    }
  }

  // Get stored access token
  static Future<String?> getStoredAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      debugPrint('❌ Error getting stored access token: $e');
      return null;
    }
  }

  // Get stored refresh token
  static Future<String?> getStoredRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      debugPrint('❌ Error getting stored refresh token: $e');
      return null;
    }
  }

  // Clear stored admin data (logout)
  static Future<void> clearStoredAdminData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_adminKey);
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      assert(() {
        debugPrint('✅ Admin data cleared locally');
        return true;
      }());
    } catch (e) {
      debugPrint('❌ Error clearing admin data: $e');
    }
  }

  // Check if admin is logged in
  static Future<bool> isAdminLoggedIn() async {
    try {
      final token = await getStoredAccessToken();
      final adminData = await getStoredAdminData();
      return token != null && adminData != null;
    } catch (e) {
      debugPrint('❌ Error checking login status: $e');
      return false;
    }
  }

  // Logout admin
  static Future<void> logoutAdmin() async {
    try {
      await clearStoredAdminData();
      debugPrint('✅ Admin logged out successfully');
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
    }
  }
}
