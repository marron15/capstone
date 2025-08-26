import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  static const String baseUrl = 'http://localhost/sample_api/admin_account';

  // Store admin data locally
  static const String _adminKey = 'admin_data';
  static const String _tokenKey = 'admin_token';
  static const String _refreshTokenKey = 'admin_refresh_token';

  // Signup new admin
  static Future<Map<String, dynamic>> signupAdmin({
    required String firstName,
    required String lastName,
    String? middleName,
    required String email,
    required String password,
    String? dateOfBirth,
    String? phoneNumber,
    dynamic profileImage,
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
        'email_address': email,
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

      // Handle profile image
      if (profileImage != null) {
        if (kIsWeb && profileImage is Uint8List) {
          // Convert web image to base64
          String base64Image = base64Encode(profileImage);
          requestBody['img'] = 'data:image/jpeg;base64,$base64Image';
        } else if (profileImage is File) {
          // Convert file to base64
          List<int> imageBytes = await profileImage.readAsBytes();
          String base64Image = base64Encode(imageBytes);
          requestBody['img'] = 'data:image/jpeg;base64,$base64Image';
        }
      }

      debugPrint('🔄 Creating admin account...');
      debugPrint('📡 Request body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/Signup.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true) {
          // Store admin data and tokens locally
          if (result['admin'] != null && result['access_token'] != null) {
            await _storeAdminData(result['admin'], result['access_token'],
                result['refresh_token'] ?? '');
          }

          // Best-effort: enrich returned admin with image data immediately
          try {
            final admin = result['admin'];
            final id = admin?['id'];
            if (id != null) {
              final adminId = id is int ? id : int.tryParse(id.toString());
              if (adminId != null) {
                final imageData = await _getAdminImageData(adminId);
                debugPrint('🔄 Image data: $imageData');
                if (imageData != null) {
                  if (imageData.startsWith('http')) {
                    result['admin']['img_url'] = imageData;
                  } else {
                    result['admin']['img'] = imageData;
                  }
                }
              }
            }
          } catch (_) {}

          debugPrint('✅ Admin created successfully');
          return result;
        } else {
          debugPrint('❌ Admin creation failed: ${result['message']}');
          return result;
        }
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'HTTP error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Error creating admin: $e');
      return {
        'success': false,
        'message': 'Error creating admin: $e',
      };
    }
  }

  // Login admin
  static Future<Map<String, dynamic>> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔄 Logging in admin...');

      final response = await http.post(
        Uri.parse('$baseUrl/Login.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true) {
          // Store admin data and tokens locally
          if (result['admin'] != null && result['access_token'] != null) {
            await _storeAdminData(result['admin'], result['access_token'],
                result['refresh_token'] ?? '');
          }

          debugPrint('✅ Admin login successful');
          return result;
        } else {
          debugPrint('❌ Admin login failed: ${result['message']}');
          return result;
        }
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'HTTP error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Error logging in admin: $e');
      return {
        'success': false,
        'message': 'Error logging in admin: $e',
      };
    }
  }

  // Get all admins
  static Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getAllAdmin.php'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result is List) {
          // Normalize admins list
          final admins = List<Map<String, dynamic>>.from(result);

          // Fetch and attach image for each admin in parallel (best-effort)
          final futures = admins.map((admin) async {
            try {
              final id = admin['id'];
              if (id is int || (id is String && int.tryParse(id) != null)) {
                final adminId = id is int ? id : int.parse(id);
                final imageData = await _getAdminImageData(adminId);
                if (imageData != null) {
                  // Prefer full URL when available; fall back to base64/data URI
                  if (imageData.startsWith('http')) {
                    admin['img_url'] = imageData;
                  } else {
                    admin['img'] = imageData;
                  }
                }
              }
            } catch (_) {}
            return admin;
          }).toList();

          final enriched = await Future.wait(futures);
          return enriched;
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
        headers: {
          'Content-Type': 'application/json',
        },
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
        'email_address': data['emailAddress'] ?? data['email_address'],
        'phone_number': data['phoneNumber'] ?? data['phone_number'],
        'updated_by': data['updatedBy'] ?? 'system',
        'updated_at': data['updatedAt'] ?? DateTime.now().toIso8601String(),
      };

      // Include password if provided
      if (data['password'] != null && data['password'] != '********') {
        mappedData['password'] = data['password'];
      }

      // Include image if provided
      if (data['img'] != null) {
        mappedData['img'] = data['img'];
      }

      debugPrint('🔄 Updating admin with ID: $id');
      debugPrint('📡 Request data: $mappedData');

      final response = await http.post(
        Uri.parse('$baseUrl/updateAdminByID.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(mappedData),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

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

  // Delete admin
  static Future<bool> deleteAdmin(int id) async {
    try {
      debugPrint('🔄 Deleting admin with ID: $id');

      final response = await http.post(
        Uri.parse('$baseUrl/deleteAdminByID.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'id': id}),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error deleting admin: $e');
      return false;
    }
  }

  // --- Helpers ---
  // Fetch admin image (URL or base64/data URI) by ID
  static Future<String?> _getAdminImageData(int id) async {
    try {
      // make query params id=id
      final response = await http.get(
        Uri.parse('$baseUrl/getAdminImage.php?id=$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) return null;

      final body = response.body;
      // Try JSON first
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          // Common keys from PHP APIs
          final imgUrl =
              decoded['img_url'] ?? decoded['image_url'] ?? decoded['url'];
          if (imgUrl is String && imgUrl.isNotEmpty) return imgUrl;
          final dataUri =
              decoded['img'] ?? decoded['image'] ?? decoded['profileImage'];
          if (dataUri is String && dataUri.isNotEmpty) return dataUri;
        }
      } catch (_) {
        // Not JSON; could already be a direct URL or base64 string
        final trimmed = body.trim();
        if (trimmed.isNotEmpty) return trimmed;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error fetching admin image: $e');
      return null;
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
      debugPrint('✅ Admin data stored locally');
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
      debugPrint('✅ Admin data cleared locally');
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
