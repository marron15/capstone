import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Base URL for your API (Production)
  // Note: Change back to localhost if testing locally
  static const String baseUrl = 'https://rnrgym.com/gym_api';

  // API endpoints
  static const String signupEndpoint = '$baseUrl/customers/Signup.php';
  static const String requestSignupCodeEndpoint =
      '$baseUrl/customers/RequestSignupCode.php';
  static const String verifySignupCodeEndpoint =
      '$baseUrl/customers/VerifySignupCode.php';
  static const String getAllCustomersEndpoint =
      '$baseUrl/customers/getAllCustomers.php';
  static const String getAllCustomersByAdminEndpoint =
      '$baseUrl/customers/getAllCustomersByAdmin.php';
  static const String updateCustomerEndpoint =
      '$baseUrl/customers/updateCustomersByID.php';
  static const String updateCustomerByAdminEndpoint =
      '$baseUrl/customers/updateCustomerByAdmin.php';
  static const String archiveCustomerEndpoint =
      '$baseUrl/customers/archiveCustomerByID.php';
  static const String restoreCustomerEndpoint =
      '$baseUrl/customers/activateCustomerByID.php';
  static const String getCustomersByStatusEndpoint =
      '$baseUrl/customers/getCustomersByStatus.php';
  static const String getNewMembersThisWeekEndpoint =
      '$baseUrl/customers/getNewMembersThisWeek.php';
  static const String getNewMembersThisMonthEndpoint =
      '$baseUrl/customers/getNewMembersThisMonth.php';
  // Trainers endpoints
  static const String getAllTrainersEndpoint =
      '$baseUrl/gymTrainers/getAllTrainers.php';
  static const String insertTrainerEndpoint =
      '$baseUrl/gymTrainers/insertTrainers.php';
  static const String archiveTrainerEndpoint =
      '$baseUrl/gymTrainers/archiveTrainerByID.php';
  static const String restoreTrainerEndpoint =
      '$baseUrl/gymTrainers/restoreTrainerByID.php';
  // Membership endpoints
  static const String getAllMembershipsEndpoint =
      '$baseUrl/membership/getAllMembership.php';
  // Address endpoints (these PHP scripts read from $_POST)
  static const String insertAddressEndpoint =
      '$baseUrl/address/insertAddress.php';
  static const String updateAddressByIdEndpoint =
      '$baseUrl/address/updatedAddressByID.php';
  static const String upsertMembershipEndpoint =
      '$baseUrl/membership/insertMembership.php';

  // Products endpoints
  static const String getAllProductsEndpoint =
      '$baseUrl/products/getAllProducts.php';
  static const String insertProductEndpoint =
      '$baseUrl/products/insertProducts.php';
  static const String updateProductEndpoint =
      '$baseUrl/products/updateProducts.php';
  static const String deleteProductEndpoint =
      '$baseUrl/products/deleteProductsByID.php';
  static const String restoreProductEndpoint =
      '$baseUrl/products/restoreProductsByID.php';
  static const String productImageProxyEndpoint =
      '$baseUrl/products/getImage.php';
  static const String getProductsByStatusEndpoint =
      '$baseUrl/products/getAllProducts.php';
  static const String createReservationEndpoint =
      '$baseUrl/products/createReservation.php';
  static const String getReservedProductsEndpoint =
      '$baseUrl/products/getReservedProducts.php';
  static const String updateReservationStatusEndpoint =
      '$baseUrl/products/updateReservationStatus.php';

  static Future<Map<String, dynamic>> signupCustomer({
    required String firstName,
    required String lastName,
    String? middleName,
    String? email,
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
      List<String> addressParts =
          [
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
        'password': password,
        'created_by': 'admin', // Mark as admin-created customer
      };

      // Add email only if provided
      if (email != null && email.trim().isNotEmpty) {
        requestBody['email'] = email;
      }

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

      // Signup request

      final response = await http.post(
        Uri.parse(signupEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Hide response body to avoid leaking data

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
              'id':
                  responseData['data']?['customer_id'] ??
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
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> requestCustomerSignupCode({
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
    String? membershipType,
    String? membershipStartDate,
    String? expirationDate,
  }) async {
    try {
      String? address;
      final addressParts =
          [
            street ?? '',
            city ?? '',
            state ?? '',
            postalCode ?? '',
            country ?? '',
          ].where((part) => part.trim().isNotEmpty).toList();
      if (addressParts.isNotEmpty) address = addressParts.join(', ');

      final Map<String, dynamic> requestBody = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'created_by': 'admin_portal',
      };

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

      if (membershipType != null && membershipType.isNotEmpty) {
        requestBody['membership_type'] = membershipType;
      }
      if (membershipStartDate != null && membershipStartDate.isNotEmpty) {
        requestBody['membership_start_date'] = membershipStartDate;
      }
      if (expirationDate != null && expirationDate.isNotEmpty) {
        requestBody['membership_end_date'] = expirationDate;
      }

      final response = await http.post(
        Uri.parse(requestSignupCodeEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Verification code sent successfully',
          'expires_at': responseData['expires_at'],
          'expires_in_minutes': responseData['expires_in_minutes'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send verification',
        };
      }
    } catch (e) {
      debugPrint('Error in requestCustomerSignupCode: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyCustomerSignupCode({
    required String email,
    required String verificationCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(verifySignupCodeEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'verification_code': verificationCode,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data'],
          'membership_created': responseData['membership_created'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Verification failed',
        };
      }
    } catch (e) {
      debugPrint('Error in verifyCustomerSignupCode: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Fetch all customers from the database (without passwords)
  static Future<Map<String, dynamic>> getAllCustomers() async {
    try {
      final response = await http.get(
        Uri.parse(getAllCustomersEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // Hide response details in console

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
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Statistics: new members this week (Mon..Sun)
  static Future<Map<String, int>> getNewMembersThisWeek() async {
    try {
      final res = await http.get(
        Uri.parse(getNewMembersThisWeekEndpoint),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final Map<String, dynamic> parsed =
            jsonDecode(res.body) as Map<String, dynamic>;
        final Map<String, dynamic> data =
            (parsed['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
        return data.map(
          (k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 0),
        );
      }
      return {};
    } catch (e) {
      debugPrint('getNewMembersThisWeek error: $e');
      return {};
    }
  }

  // Statistics: new members this month grouped by week 1..4
  static Future<Map<String, int>> getNewMembersThisMonth() async {
    try {
      final res = await http.get(
        Uri.parse(getNewMembersThisMonthEndpoint),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final Map<String, dynamic> parsed =
            jsonDecode(res.body) as Map<String, dynamic>;
        final Map<String, dynamic> data =
            (parsed['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
        return data.map(
          (k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 0),
        );
      }
      return {};
    } catch (e) {
      debugPrint('getNewMembersThisMonth error: $e');
      return {};
    }
  }

  // Aggregate membership totals by type using memberships endpoint
  static Future<Map<String, int>> getMembershipTotals() async {
    try {
      final res = await http.get(
        Uri.parse(getAllMembershipsEndpoint),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final dynamic parsed = jsonDecode(res.body);
        if (parsed is List) {
          int daily = 0, halfMonth = 0, monthly = 0;
          String norm(dynamic v) => (v ?? '').toString().trim().toLowerCase();
          for (final dynamic m in parsed) {
            if (m is! Map<String, dynamic>) continue;
            final String t = norm(m['membership_type'] ?? m['status']);
            if (t == 'daily')
              daily++;
            else if (t.replaceAll(' ', '') == 'halfmonth' ||
                (t.startsWith('half') && t.contains('month')))
              halfMonth++;
            else
              monthly++; // default bucket
          }
          return {'Daily': daily, 'Half Month': halfMonth, 'Monthly': monthly};
        }
      }
      return {};
    } catch (e) {
      debugPrint('getMembershipTotals error: $e');
      return {};
    }
  }

  // ============================
  // Products
  // ============================

  static String _detectMimeFromFilename(String filename) {
    final String lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }

  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final res = await http.get(
        Uri.parse(getAllProductsEndpoint),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final dynamic parsed = jsonDecode(res.body);
        if (parsed is List) {
          return List<Map<String, dynamic>>.from(parsed);
        }
      }
      return [];
    } catch (e) {
      debugPrint('getAllProducts error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getProductsByStatus(
    dynamic status,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$getProductsByStatusEndpoint?status=$status'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final dynamic parsed = jsonDecode(res.body);
        if (parsed is List) {
          return List<Map<String, dynamic>>.from(parsed);
        }
      }
      return [];
    } catch (e) {
      debugPrint('getProductsByStatus error: $e');
      return [];
    }
  }

  static Future<bool> insertProduct({
    required String name,
    required String description,
    required Uint8List imageBytes,
    required String imageFileName,
    required int quantity,
  }) async {
    try {
      final String mime = _detectMimeFromFilename(imageFileName);
      final String base64Img = base64Encode(imageBytes);
      final String dataUrl =
          mime.startsWith('image/')
              ? 'data:$mime;base64,$base64Img'
              : base64Img;

      final body = jsonEncode({
        'name': name,
        'description': description,
        'img': dataUrl,
        'quantity': quantity,
      });

      final res = await http.post(
        Uri.parse(insertProductEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      // Hide insertProduct raw response

      if (res.statusCode == 200) {
        try {
          final Map<String, dynamic> parsed =
              jsonDecode(res.body) as Map<String, dynamic>;
          return parsed['success'] == true;
        } catch (_) {
          return res.body.toLowerCase().contains('true') ||
              res.body.toLowerCase().contains('success');
        }
      }

      // Fallback: some PHP setups expect form-encoded fields
      final resForm = await http.post(
        Uri.parse(insertProductEndpoint),
        headers: {'Accept': 'application/json'},
        body: {
          'name': name,
          'description': description,
          'img': dataUrl,
          'quantity': quantity.toString(),
        },
      );
      // Hide insertProduct form raw response
      if (resForm.statusCode == 200) {
        try {
          final Map<String, dynamic> parsed =
              jsonDecode(resForm.body) as Map<String, dynamic>;
          return parsed['success'] == true;
        } catch (_) {
          return resForm.body.toLowerCase().contains('true') ||
              resForm.body.toLowerCase().contains('success');
        }
      }
      return false;
    } catch (e) {
      debugPrint('insertProduct error: $e');
      return false;
    }
  }

  static Future<bool> updateProduct({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(updateProductEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'id': id, ...data}),
      );
      if (res.statusCode == 200) {
        final parsed = jsonDecode(res.body);
        if (parsed is Map<String, dynamic>) return parsed['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('updateProduct error: $e');
      return false;
    }
  }

  static Future<bool> deleteProduct(int id) async {
    try {
      final res = await http.post(
        Uri.parse(deleteProductEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'id': id}),
      );
      // Hide archiveProduct raw response
      if (res.statusCode == 200) {
        try {
          final parsed = jsonDecode(res.body);
          if (parsed is Map<String, dynamic>) {
            return parsed['success'] == true;
          }
        } catch (_) {}
      }
      // Fallback to form-encoded
      final resForm = await http.post(
        Uri.parse(deleteProductEndpoint),
        headers: {'Accept': 'application/json'},
        body: {'id': id.toString()},
      );
      debugPrint('archiveProduct FORM status: ${resForm.statusCode}');
      debugPrint('archiveProduct FORM body: ${resForm.body}');
      if (resForm.statusCode == 200) {
        try {
          final parsed = jsonDecode(resForm.body);
          if (parsed is Map<String, dynamic>) {
            return parsed['success'] == true;
          }
        } catch (_) {
          final b = resForm.body.toLowerCase();
          return b.contains('true') || b.contains('success');
        }
      }
      return false;
    } catch (e) {
      debugPrint('deleteProduct error: $e');
      return false;
    }
  }

  static Future<bool> archiveProduct(int id) => deleteProduct(id);

  static Future<bool> restoreProduct(int id) async {
    try {
      final res = await http.post(
        Uri.parse(restoreProductEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'id': id}),
      );
      if (res.statusCode == 200) {
        try {
          final parsed = jsonDecode(res.body);
          if (parsed is Map<String, dynamic>) return parsed['success'] == true;
        } catch (_) {}
      }
      // fallback form-encoded
      final resForm = await http.post(
        Uri.parse(restoreProductEndpoint),
        headers: {'Accept': 'application/json'},
        body: {'id': id.toString()},
      );
      if (resForm.statusCode == 200) {
        try {
          final parsed = jsonDecode(resForm.body);
          if (parsed is Map<String, dynamic>) return parsed['success'] == true;
        } catch (_) {
          final b = resForm.body.toLowerCase();
          return b.contains('true') || b.contains('success');
        }
      }
      return false;
    } catch (e) {
      debugPrint('restoreProduct error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> createProductReservation({
    required int customerId,
    required int productId,
    required int quantity,
    String? notes,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(createReservationEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'customer_id': customerId,
          'product_id': productId,
          'quantity': quantity,
          'notes': notes ?? '',
        }),
      );
      final Map<String, dynamic> parsed =
          jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return parsed;
      }
      return {
        'success': false,
        'message': parsed['message'] ?? 'Failed to reserve product',
      };
    } catch (e) {
      debugPrint('createProductReservation error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static const String getCustomerReservationsEndpoint =
      '$baseUrl/products/getCustomerReservations.php';

  static Future<List<Map<String, dynamic>>> getCustomerReservations({
    required int customerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$getCustomerReservationsEndpoint?customer_id=$customerId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final dynamic parsed = jsonDecode(response.body);

        // Handle case where API returns a List directly
        if (parsed is List) {
          return parsed
              .map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              })
              .where((item) => item.isNotEmpty)
              .toList();
        }

        // Handle case where API returns a Map with 'data' field
        if (parsed is Map<String, dynamic>) {
          if (parsed['success'] == true && parsed['data'] is List) {
            return (parsed['data'] as List)
                .map((item) {
                  if (item is Map<String, dynamic>) {
                    return item;
                  } else if (item is Map) {
                    return Map<String, dynamic>.from(item);
                  }
                  return <String, dynamic>{};
                })
                .where((item) => item.isNotEmpty)
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('getCustomerReservations error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getReservedProducts({
    String? status,
  }) async {
    try {
      final Uri uri =
          (status == null || status.isEmpty)
              ? Uri.parse(getReservedProductsEndpoint)
              : Uri.parse('$getReservedProductsEndpoint?status=$status');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final dynamic parsed = jsonDecode(res.body);
        if (parsed is List) {
          return List<Map<String, dynamic>>.from(parsed);
        }
      }
      return [];
    } catch (e) {
      debugPrint('getReservedProducts error: $e');
      return [];
    }
  }

  static Future<bool> updateReservationStatus({
    required int reservationId,
    required String status,
    String? declineNote,
  }) async {
    try {
      final body = <String, dynamic>{
        'reservation_id': reservationId,
        'status': status,
      };
      if (declineNote != null && declineNote.isNotEmpty) {
        body['decline_note'] = declineNote;
      }

      final res = await http.post(
        Uri.parse(updateReservationStatusEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final Map<String, dynamic> parsed =
            jsonDecode(res.body) as Map<String, dynamic>;
        return parsed['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('updateReservationStatus error: $e');
      return false;
    }
  }

  // Fetch all trainers
  static Future<List<Map<String, String>>> getAllTrainers() async {
    try {
      final response = await http.get(
        Uri.parse(getAllTrainersEndpoint),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final dynamic parsed = jsonDecode(response.body);
        if (parsed is List) {
          return parsed.map<Map<String, String>>((dynamic item) {
            final Map<String, dynamic> row =
                item is Map<String, dynamic> ? item : <String, dynamic>{};
            String getStr(String key) => (row[key] ?? '').toString();
            return {
              'id': getStr('id'),
              'firstName': getStr('first_name'),
              'middleName': getStr('middle_name'),
              'lastName': getStr('last_name'),
              'contactNumber': getStr('contact_number'),
              'status': getStr('status'),
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error in getAllTrainers: $e');
      return [];
    }
  }

  // Trainers total count helper
  static Future<int> getTrainersTotal({bool activeOnly = true}) async {
    try {
      final list = await getAllTrainers();
      if (activeOnly) {
        return list
            .where((t) => (t['status'] ?? '').toLowerCase() != 'inactive')
            .length;
      }
      return list.length;
    } catch (e) {
      debugPrint('getTrainersTotal error: $e');
      return 0;
    }
  }

  // Insert a trainer (form-encoded as PHP expects)
  static Future<bool> insertTrainer({
    required String firstName,
    String? middleName,
    required String lastName,
    required String contactNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(insertTrainerEndpoint),
        headers: {'Accept': 'application/json'},
        body: {
          'firstName': firstName,
          'middleName': middleName ?? '',
          'lastName': lastName,
          'contactNumber': contactNumber,
        },
      );

      if (response.statusCode == 200) {
        // Endpoint returns true/false JSON
        try {
          final dynamic parsed = jsonDecode(response.body);
          if (parsed is bool) return parsed;
          if (parsed is Map<String, dynamic> && parsed['success'] != null) {
            return parsed['success'] == true;
          }
        } catch (_) {
          // Fallback for plain text responses
          final String body = response.body.toLowerCase();
          return body.contains('true') || body.contains('success');
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error in insertTrainer: $e');
      return false;
    }
  }

  static Future<bool> archiveTrainer(int id) async {
    try {
      final res = await http.post(
        Uri.parse(archiveTrainerEndpoint),
        headers: {'Accept': 'application/json'},
        body: {'id': id.toString()},
      );
      if (res.statusCode == 200) {
        try {
          final parsed = jsonDecode(res.body);
          if (parsed is Map<String, dynamic> && parsed['success'] != null) {
            return parsed['success'] == true;
          }
          if (parsed is bool) return parsed;
        } catch (_) {}
      }
      return false;
    } catch (e) {
      debugPrint('archiveTrainer error: $e');
      return false;
    }
  }

  static Future<bool> restoreTrainer(int id) async {
    try {
      final res = await http.post(
        Uri.parse(restoreTrainerEndpoint),
        headers: {'Accept': 'application/json'},
        body: {'id': id.toString()},
      );
      if (res.statusCode == 200) {
        try {
          final parsed = jsonDecode(res.body);
          if (parsed is Map<String, dynamic> && parsed['success'] != null) {
            return parsed['success'] == true;
          }
          if (parsed is bool) return parsed;
        } catch (_) {}
      }
      return false;
    } catch (e) {
      debugPrint('restoreTrainer error: $e');
      return false;
    }
  }

  // Fetch all customers with passwords (admin access)
  static Future<Map<String, dynamic>> getAllCustomersWithPasswords() async {
    try {
      // Fetching customers with passwords

      final response = await http.get(
        Uri.parse(getAllCustomersByAdminEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // Hide raw response

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // If the backend doesn't attach membership, enrich on the client by fetching memberships
        if (responseData['success'] == true && responseData['data'] is List) {
          try {
            final membershipsRes = await http.get(
              Uri.parse(getAllMembershipsEndpoint),
              headers: {'Accept': 'application/json'},
            );
            if (membershipsRes.statusCode == 200 &&
                membershipsRes.body.isNotEmpty) {
              final dynamic parsed = jsonDecode(membershipsRes.body);
              if (parsed is List) {
                // Build latest membership per customer_id
                final Map<String, Map<String, dynamic>> latestByCustomerId = {};
                DateTime parseDate(dynamic v) {
                  final String s = (v ?? '').toString();
                  return DateTime.tryParse(s) ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                }

                int parseInt(dynamic v) =>
                    int.tryParse((v ?? '').toString()) ?? -1;

                for (final dynamic m in parsed) {
                  if (m is! Map<String, dynamic>) continue;
                  final String key =
                      (m['customer_id'] ?? m['customerId'] ?? '').toString();
                  if (key.isEmpty) continue;
                  final Map<String, dynamic>? existing =
                      latestByCustomerId[key];
                  if (existing == null) {
                    latestByCustomerId[key] = m;
                    continue;
                  }

                  final DateTime newStart = parseDate(
                    m['start_date'] ?? m['startDate'],
                  );
                  final DateTime oldStart = parseDate(
                    existing['start_date'] ?? existing['startDate'],
                  );
                  final DateTime newUpdated = parseDate(
                    m['updated_at'] ?? m['updatedAt'],
                  );
                  final DateTime oldUpdated = parseDate(
                    existing['updated_at'] ?? existing['updatedAt'],
                  );
                  final int newId = parseInt(m['id']);
                  final int oldId = parseInt(existing['id']);

                  final bool isNewer =
                      newStart.isAfter(oldStart) ||
                      (newStart.isAtSameMomentAs(oldStart) &&
                          newUpdated.isAfter(oldUpdated)) ||
                      (newStart.isAtSameMomentAs(oldStart) &&
                          newUpdated.isAtSameMomentAs(oldUpdated) &&
                          newId > oldId);

                  if (isNewer) latestByCustomerId[key] = m;
                }

                // Attach membership to each customer in the response
                final List<dynamic> customers =
                    responseData['data'] as List<dynamic>;
                for (final dynamic c in customers) {
                  if (c is Map<String, dynamic>) {
                    final String cid =
                        (c['id'] ?? c['customer_id'] ?? '').toString();
                    final Map<String, dynamic>? mem = latestByCustomerId[cid];
                    if (mem != null) {
                      final String membershipType =
                          (mem['membership_type'] ?? mem['status'] ?? '')
                              .toString();
                      c['membership'] = mem;
                      c['membership_type'] = membershipType;
                      c['status'] = mem['status'] ?? membershipType;
                      c['start_date'] = mem['start_date'] ?? mem['startDate'];
                      c['expiration_date'] =
                          mem['expiration_date'] ?? mem['expirationDate'];
                    }
                  }
                }
              }
            }
          } catch (e) {
            debugPrint(
              'Warning: failed to fetch memberships for enrichment: $e',
            );
          }
        }

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
      return {'success': false, 'message': 'Network error: $e'};
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
      return {'success': false, 'message': 'Network error: $e'};
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
      return {'success': false, 'message': 'Network error: $e'};
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
        headers: {'Accept': 'application/json'},
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
      // Hide raw address insertion response

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
        headers: {'Accept': 'application/json'},
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
      // Hide raw address update response

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

  static Future<bool> upsertCustomerMembership({
    required int customerId,
    required String membershipType,
  }) async {
    try {
      final DateTime now = DateTime.now();
      int addDays;
      switch (membershipType) {
        case 'Daily':
          addDays = 1;
          break;
        case 'Half Month':
          addDays = 15;
          break;
        case 'Monthly':
        default:
          addDays = 30;
      }
      final DateTime expiration = now.add(Duration(days: addDays));

      String formatDate(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final response = await http.post(
        Uri.parse(upsertMembershipEndpoint),
        headers: {'Accept': 'application/json'},
        body: {
          'customerId': customerId.toString(),
          'membershipType': membershipType,
          'startDate': formatDate(now),
          'expirationDate': formatDate(expiration),
          'status': membershipType,
        },
      );

      if (response.statusCode == 200) {
        try {
          final parsed = jsonDecode(response.body);
          if (parsed is Map<String, dynamic>) {
            return parsed['success'] == true;
          }
          if (parsed is bool) {
            return parsed;
          }
        } catch (_) {
          return response.body.toLowerCase().contains('success') ||
              response.body.toLowerCase().contains('true');
        }
      }
      return false;
    } catch (e) {
      debugPrint('upsertCustomerMembership error: $e');
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

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Archive a customer by ID
  static Future<Map<String, dynamic>> archiveCustomer({required int id}) async {
    try {
      final response = await http.post(
        Uri.parse(archiveCustomerEndpoint),
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
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Restore a customer by ID
  static Future<Map<String, dynamic>> restoreCustomer({required int id}) async {
    try {
      final response = await http.post(
        Uri.parse(restoreCustomerEndpoint),
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
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get customers by status
  static Future<Map<String, dynamic>> getCustomersByStatus({
    required String status,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$getCustomersByStatusEndpoint?status=$status'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            jsonDecode(response.body) as Map<String, dynamic>;

        // Enrich with latest membership per customer when possible so UI shows true membership
        try {
          final membershipsRes = await http.get(
            Uri.parse(getAllMembershipsEndpoint),
            headers: {'Accept': 'application/json'},
          );
          if (membershipsRes.statusCode == 200 &&
              membershipsRes.body.isNotEmpty) {
            final dynamic parsed = jsonDecode(membershipsRes.body);
            if (parsed is List) {
              // Build latest membership per customer_id
              final Map<String, Map<String, dynamic>> latestByCustomerId = {};

              DateTime parseDate(dynamic v) {
                final String s = (v ?? '').toString();
                return DateTime.tryParse(s) ??
                    DateTime.fromMillisecondsSinceEpoch(0);
              }

              int parseInt(dynamic v) =>
                  int.tryParse((v ?? '').toString()) ?? -1;

              for (final dynamic m in parsed) {
                if (m is! Map<String, dynamic>) continue;
                final String key =
                    (m['customer_id'] ?? m['customerId'] ?? '').toString();
                if (key.isEmpty) continue;
                final Map<String, dynamic>? existing = latestByCustomerId[key];
                if (existing == null) {
                  latestByCustomerId[key] = m;
                  continue;
                }

                final DateTime newStart = parseDate(
                  m['start_date'] ?? m['startDate'],
                );
                final DateTime oldStart = parseDate(
                  existing['start_date'] ?? existing['startDate'],
                );
                final DateTime newUpdated = parseDate(
                  m['updated_at'] ?? m['updatedAt'],
                );
                final DateTime oldUpdated = parseDate(
                  existing['updated_at'] ?? existing['updatedAt'],
                );
                final int newId = parseInt(m['id']);
                final int oldId = parseInt(existing['id']);

                final bool isNewer =
                    newStart.isAfter(oldStart) ||
                    (newStart.isAtSameMomentAs(oldStart) &&
                        newUpdated.isAfter(oldUpdated)) ||
                    (newStart.isAtSameMomentAs(oldStart) &&
                        newUpdated.isAtSameMomentAs(oldUpdated) &&
                        newId > oldId);

                if (isNewer) latestByCustomerId[key] = m;
              }

              if (responseData['data'] is List) {
                final List<dynamic> customers =
                    responseData['data'] as List<dynamic>;
                for (final dynamic c in customers) {
                  if (c is Map<String, dynamic>) {
                    final String cid =
                        (c['id'] ?? c['customer_id'] ?? c['customerId'] ?? '')
                            .toString();
                    final Map<String, dynamic>? mem = latestByCustomerId[cid];
                    if (mem != null) {
                      final String membershipType =
                          (mem['membership_type'] ?? mem['status'] ?? '')
                              .toString();
                      c['membership'] = mem;
                      c['membership_type'] = membershipType;
                      // Preserve original customer status; do not overwrite with membership status
                      c['start_date'] = mem['start_date'] ?? mem['startDate'];
                      c['expiration_date'] =
                          mem['expiration_date'] ?? mem['expirationDate'];
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint(
            'Warning: failed to enrich customers with memberships: $e',
          );
        }

        return responseData;
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
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get customers by status with passwords (admin use)
  static Future<Map<String, dynamic>> getCustomersByStatusWithPasswords({
    required String status,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$getAllCustomersByAdminEndpoint?status=$status'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            jsonDecode(response.body) as Map<String, dynamic>;

        // Filter by customer status if backend ignored the query param
        if (responseData['success'] == true && responseData['data'] is List) {
          final List<dynamic> list = responseData['data'] as List<dynamic>;
          responseData['data'] =
              list.where((dynamic c) {
                if (c is Map<String, dynamic>) {
                  final String s = (c['status'] ?? '').toString().toLowerCase();
                  return s == status.toLowerCase();
                }
                return false;
              }).toList();
        }

        // Enrich with latest membership for each customer so UI has membership_type
        try {
          final membershipsRes = await http.get(
            Uri.parse(getAllMembershipsEndpoint),
            headers: {'Accept': 'application/json'},
          );
          if (membershipsRes.statusCode == 200 &&
              membershipsRes.body.isNotEmpty) {
            final dynamic parsed = jsonDecode(membershipsRes.body);
            if (parsed is List) {
              final Map<String, Map<String, dynamic>> latestByCustomerId = {};

              DateTime parseDate(dynamic v) {
                final String s = (v ?? '').toString();
                return DateTime.tryParse(s) ??
                    DateTime.fromMillisecondsSinceEpoch(0);
              }

              int parseInt(dynamic v) =>
                  int.tryParse((v ?? '').toString()) ?? -1;

              for (final dynamic m in parsed) {
                if (m is! Map<String, dynamic>) continue;
                final String key =
                    (m['customer_id'] ?? m['customerId'] ?? '').toString();
                if (key.isEmpty) continue;
                final Map<String, dynamic>? existing = latestByCustomerId[key];
                if (existing == null) {
                  latestByCustomerId[key] = m;
                  continue;
                }

                final DateTime newStart = parseDate(
                  m['start_date'] ?? m['startDate'],
                );
                final DateTime oldStart = parseDate(
                  existing['start_date'] ?? existing['startDate'],
                );
                final DateTime newUpdated = parseDate(
                  m['updated_at'] ?? m['updatedAt'],
                );
                final DateTime oldUpdated = parseDate(
                  existing['updated_at'] ?? existing['updatedAt'],
                );
                final int newId = parseInt(m['id']);
                final int oldId = parseInt(existing['id']);

                final bool isNewer =
                    newStart.isAfter(oldStart) ||
                    (newStart.isAtSameMomentAs(oldStart) &&
                        newUpdated.isAfter(oldUpdated)) ||
                    (newStart.isAtSameMomentAs(oldStart) &&
                        newUpdated.isAtSameMomentAs(oldUpdated) &&
                        newId > oldId);

                if (isNewer) latestByCustomerId[key] = m;
              }

              if (responseData['data'] is List) {
                final List<dynamic> customers =
                    responseData['data'] as List<dynamic>;
                for (final dynamic c in customers) {
                  if (c is Map<String, dynamic>) {
                    final String cid =
                        (c['id'] ?? c['customer_id'] ?? c['customerId'] ?? '')
                            .toString();
                    final Map<String, dynamic>? mem = latestByCustomerId[cid];
                    if (mem != null) {
                      final String membershipType =
                          (mem['membership_type'] ?? mem['status'] ?? '')
                              .toString();
                      c['membership'] = mem;
                      c['membership_type'] = membershipType;
                      // Do NOT overwrite customer active/archived status with membership status
                      c['start_date'] = mem['start_date'] ?? mem['startDate'];
                      c['expiration_date'] =
                          mem['expiration_date'] ?? mem['expirationDate'];
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint(
            'Warning: failed to fetch memberships for enrichment (with passwords): $e',
          );
        }

        return responseData;
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
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
