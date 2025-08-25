import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Base URL for your API - adjust this to match your XAMPP setup
  static const String baseUrl = 'http://localhost/sample_api';

  // API endpoints
  static const String signupEndpoint = '$baseUrl/customers/Signup.php';
  static const String getAllCustomersEndpoint =
      '$baseUrl/customers/getAllCustomers.php';
  static const String getAllCustomersByAdminEndpoint =
      '$baseUrl/customers/getAllCustomersByAdmin.php';
  static const String deleteCustomerEndpoint =
      '$baseUrl/customers/deleteCustomersByID.php';
  static const String updateCustomerEndpoint =
      '$baseUrl/customers/updateCustomersByID.php';
  static const String updateCustomerByAdminEndpoint =
      '$baseUrl/customers/updateCustomerByAdmin.php';
  // Address endpoints (these PHP scripts read from $_POST)
  static const String insertAddressEndpoint =
      '$baseUrl/address/insertAddress.php';
  static const String updateAddressByIdEndpoint =
      '$baseUrl/address/updatedAddressByID.php';

  static Future<Map<String, dynamic>> signupCustomer({
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
    String? membershipType,
    String? expirationDate,
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

      // Prepare request body - match the expected format in Signup.php
      final Map<String, dynamic> requestBody = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'created_by': 'admin', // Mark as admin-created customer
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

      // Add membership data if provided
      if (membershipType != null && membershipType.isNotEmpty) {
        requestBody['membership_type'] = membershipType;
      }
      if (expirationDate != null && expirationDate.isNotEmpty) {
        requestBody['expiration_date'] = expirationDate;
      }

      debugPrint('Sending signup request to: $signupEndpoint');
      debugPrint('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(signupEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Check if the response has the expected structure
        if (responseData['success'] == true) {
          // Return the response with customer ID for membership creation
          final result = {
            'success': true,
            'message':
                responseData['message'] ?? 'Customer created successfully',
            'user': {
              'id': responseData['data']?['customer_id'] ??
                  responseData['data']?['id'],
              'email': responseData['data']?['email'],
              'first_name': responseData['data']?['first_name'],
              'last_name': responseData['data']?['last_name'],
            },
            'membership_created': responseData['membership_created'] ?? false,
          };
          return result;
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to create customer',
          };
        }
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
      debugPrint('Error in signupCustomer: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Fetch all customers from the database (without passwords)
  static Future<Map<String, dynamic>> getAllCustomers() async {
    try {
      debugPrint('Fetching customers from: $getAllCustomersEndpoint');

      final response = await http.get(
        Uri.parse(getAllCustomersEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

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
      debugPrint('Error in getAllCustomers: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Fetch all customers with passwords (admin access)
  static Future<Map<String, dynamic>> getAllCustomersWithPasswords() async {
    try {
      debugPrint(
          'Fetching customers with passwords from: $getAllCustomersByAdminEndpoint');

      final response = await http.get(
        Uri.parse(getAllCustomersByAdminEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

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
      debugPrint('Error in getAllCustomersWithPasswords: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Delete a customer by ID
  static Future<Map<String, dynamic>> deleteCustomer({
    required int id,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(deleteCustomerEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      // Try to parse error
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update a customer by ID
  static Future<Map<String, dynamic>> updateCustomer({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(updateCustomerEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'id': id, ...data}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      // Try to parse error
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update a customer by ID (admin version - can update password)
  static Future<Map<String, dynamic>> updateCustomerByAdmin({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(updateCustomerByAdminEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'id': id, ...data}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      // Try to parse error
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Insert address for a customer (expects form-encoded POST)
  static Future<bool> insertCustomerAddress({
    required int customerId,
    required String street,
    required String city,
    String? state,
    required String postalCode,
    required String country,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(insertAddressEndpoint),
        headers: {
          'Accept': 'application/json',
        },
        body: {
          'customer_id': customerId.toString(),
          'street': street,
          'city': city,
          'state': state ?? '',
          // PHP endpoint expects zip_code
          'zip_code': postalCode,
          'country': country,
        },
      );
      debugPrint(
          'insertAddress status: ${response.statusCode} body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          return responseData['success'] == true;
        } catch (e) {
          // Fallback for non-JSON responses
          return response.body.toLowerCase().contains('success');
        }
      }
      return false;
    } catch (e) {
      debugPrint('insertCustomerAddress error: $e');
      return false;
    }
  }

  // Update address by address id
  static Future<bool> updateCustomerAddressById({
    required int addressId,
    required int customerId,
    required String street,
    required String city,
    String? state,
    required String postalCode,
    required String country,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(updateAddressByIdEndpoint),
        headers: {
          'Accept': 'application/json',
        },
        body: {
          'id': addressId.toString(),
          'customer_id': customerId.toString(),
          'street': street,
          'city': city,
          'state': state ?? '',
          'zip_code': postalCode,
          'country': country,
        },
      );
      debugPrint(
          'updateAddress status: ${response.statusCode} body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          return responseData['success'] == true;
        } catch (e) {
          // Fallback for non-JSON responses
          return response.body.toLowerCase().contains('success');
        }
      }
      return false;
    } catch (e) {
      debugPrint('updateCustomerAddressById error: $e');
      return false;
    }
  }

  // Helper method to check API connectivity
  static Future<bool> checkApiConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/getAllCustomers.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API connection check failed: $e');
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
