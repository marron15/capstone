import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL for your API - adjust this to match your XAMPP setup
  static const String baseUrl = 'http://localhost/sample_api';

  // API endpoints
  static const String signupEndpoint = '$baseUrl/users/Signup.php';
  static const String getAllUsersEndpoint = '$baseUrl/users/getAllUsers.php';

  static Future<Map<String, dynamic>> signupUser({
    required String firstName,
    required String lastName,
    String? middleName,
    required String email,
    required String password,
    String? birthdate,
    String? phoneNumber,
    String? emergencyContactName,
    String? emergencyContactNumber,
    String? street,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? img,
  }) async {
    try {
      // Prepare address string from components
      String? address;
      List<String> addressParts = [
        street ?? '',
        city ?? '',
        state ?? '',
        postalCode ?? '',
        country ?? '',
      ].where((part) => part.trim().isNotEmpty).toList();

      if (addressParts.isNotEmpty) {
        address = addressParts.join(', ');
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
      };

      // Add optional fields if they exist
      if (middleName != null && middleName.trim().isNotEmpty) {
        requestBody['middle_name'] = middleName;
      }
      if (birthdate != null && birthdate.trim().isNotEmpty) {
        requestBody['birthdate'] = birthdate;
      }
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        requestBody['phone_number'] = phoneNumber;
      }
      if (emergencyContactName != null &&
          emergencyContactName.trim().isNotEmpty) {
        requestBody['emergency_contact_name'] = emergencyContactName;
      }
      if (emergencyContactNumber != null &&
          emergencyContactNumber.trim().isNotEmpty) {
        requestBody['emergency_contact_number'] = emergencyContactNumber;
      }
      if (address != null) {
        requestBody['address'] = address;
      }
      if (img != null && img.trim().isNotEmpty) {
        requestBody['img'] = img;
      }

      // Set created_by for admin signup
      requestBody['created_by'] = 'admin';

      print('Sending signup request to: $signupEndpoint');
      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(signupEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        // Try to parse error response
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Unknown error occurred',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('Error in signupUser: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Fetch all users from the database
  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      print('Fetching users from: $getAllUsersEndpoint');

      final response = await http.get(
        Uri.parse(getAllUsersEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        // Try to parse error response
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Unknown error occurred',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('Error in getAllUsers: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Helper method to check API connectivity
  static Future<bool> checkApiConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/getAllUsers.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('API connection check failed: $e');
      return false;
    }
  }

  // Helper method to test signup endpoint
  static Future<Map<String, dynamic>> testSignupEndpoint() async {
    try {
      final response = await http.post(
        Uri.parse(signupEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}), // Empty body to test endpoint response
      );

      return {
        'status_code': response.statusCode,
        'response_body': response.body,
        'endpoint': signupEndpoint,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'endpoint': signupEndpoint,
      };
    }
  }
}
