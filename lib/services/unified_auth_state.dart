import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'auth_service.dart';
import 'membership_service.dart';
import '../User Profile/profile_data.dart';

enum UserType { customer, admin, none }

class UnifiedAuthState extends ChangeNotifier {
  bool _isInitialized = false;
  UserType _userType = UserType.none;

  // Customer data
  String? _customerEmail;
  String? _customerName;
  int? _customerId;
  String? _customerAccessToken;
  String? _customerRefreshToken;
  MembershipData? _membershipData;

  // Admin data
  Map<String, dynamic>? _adminData;
  String? _adminAccessToken;
  String? _adminRefreshToken;

  // Getters
  bool get isInitialized => _isInitialized;
  UserType get userType => _userType;
  bool get isLoggedIn => _userType != UserType.none;
  bool get isCustomerLoggedIn => _userType == UserType.customer;
  bool get isAdminLoggedIn => _userType == UserType.admin;

  // Customer getters
  String? get customerEmail => _customerEmail;
  String? get customerName => _customerName;
  int? get customerId => _customerId;
  String? get customerAccessToken => _customerAccessToken;
  String? get customerRefreshToken => _customerRefreshToken;
  MembershipData? get membershipData => _membershipData;

  // Admin getters
  Map<String, dynamic>? get adminData => _adminData;
  String? get adminAccessToken => _adminAccessToken;
  String? get adminRefreshToken => _adminRefreshToken;

  // Initialize auth state from storage
  Future<void> initializeFromStorage() async {
    print('🔄 Initializing unified auth from storage...');
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check for customer tokens first
      final customerAccessToken = prefs.getString('access_token');
      final customerRefreshToken = prefs.getString('refresh_token');

      // Check for admin tokens
      final adminToken = prefs.getString('admin_token');
      final adminData = prefs.getString('admin_data');

      if (customerAccessToken != null) {
        print('🔍 Found customer tokens, validating...');
        await _validateAndRestoreCustomerAuth(
          customerAccessToken,
          customerRefreshToken,
        );
      } else if (adminToken != null && adminData != null) {
        print('🔍 Found admin tokens, validating...');
        await _validateAndRestoreAdminAuth(adminToken, adminData);
      } else {
        print('❌ No stored tokens found');
      }

      _isInitialized = true;
      notifyListeners();
      print('✅ Unified auth initialization complete - User type: $_userType');
    } catch (e) {
      print('❌ Failed to initialize unified auth from storage: $e');
      await _clearAllTokens();
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Customer login
  Future<void> loginCustomer({
    required int customerId,
    required String email,
    required String fullName,
    String? accessToken,
    String? refreshToken,
  }) async {
    // Clear any existing admin session
    _clearAdminData();

    _userType = UserType.customer;
    _customerId = customerId;
    _customerEmail = email;
    _customerName = fullName;
    _customerAccessToken = accessToken;
    _customerRefreshToken = refreshToken;

    // Fetch membership data
    await _fetchMembershipData(customerId);

    // Store tokens in SharedPreferences
    await _saveCustomerTokens();

    notifyListeners();
  }

  // Admin login
  Future<void> loginAdmin({
    required Map<String, dynamic> admin,
    required String accessToken,
    String? refreshToken,
  }) async {
    // Clear any existing customer session
    _clearCustomerData();

    _userType = UserType.admin;
    _adminData = admin;
    _adminAccessToken = accessToken;
    _adminRefreshToken = refreshToken;

    // Store admin data in SharedPreferences
    await _saveAdminTokens();

    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    await _clearAllTokens();
    _userType = UserType.none;
    _clearCustomerData();
    _clearAdminData();
    notifyListeners();
  }

  // Validate and restore customer auth
  Future<void> _validateAndRestoreCustomerAuth(
    String? accessToken,
    String? refreshToken,
  ) async {
    if (accessToken == null) return;

    try {
      print('🔍 Validating customer token with backend...');
      final validationResult = await _validateCustomerTokenWithBackend(
        accessToken,
      );
      print('🔍 Customer validation result: $validationResult');

      if (validationResult != null && validationResult['success'] == true) {
        final customerData = validationResult['data'];
        print(
          '✅ Customer token valid! Restoring customer: ${customerData['email']}',
        );

        _userType = UserType.customer;
        _customerId = customerData['customer_id'];
        _customerEmail = customerData['email'];
        _customerName = customerData['full_name'];
        _customerAccessToken = accessToken;
        _customerRefreshToken = refreshToken;

        // Fetch membership data when restoring auth state
        await _fetchMembershipData(customerData['customer_id']);

        print('✅ Customer auth state restored successfully');
      } else if (refreshToken != null) {
        print('🔄 Customer access token invalid, trying refresh token...');
        await _tryRefreshCustomerToken(refreshToken);
      } else {
        print('❌ No valid customer tokens available');
        await _clearCustomerTokens();
      }
    } catch (e) {
      print('❌ Customer token validation failed: $e');
      await _clearCustomerTokens();
    }
  }

  // Validate and restore admin auth
  Future<void> _validateAndRestoreAdminAuth(
    String? accessToken,
    String? adminDataString,
  ) async {
    if (accessToken == null || adminDataString == null) return;

    try {
      print('🔍 Validating admin token...');
      final adminData = jsonDecode(adminDataString);

      // For now, we'll assume admin tokens are valid if they exist
      // In a real app, you'd validate with the backend
      _userType = UserType.admin;
      _adminData = adminData;
      _adminAccessToken = accessToken;

      print('✅ Admin auth state restored successfully');
    } catch (e) {
      print('❌ Admin token validation failed: $e');
      await _clearAdminTokens();
    }
  }

  // Validate customer token with backend
  Future<Map<String, dynamic>?> _validateCustomerTokenWithBackend(
    String token,
  ) async {
    try {
      final result = await AuthService.validateToken(token);
      if (result.success) {
        // Also populate profile data when token is validated
        if (result.customerData != null) {
          // Parse composite address string into fields when possible
          String? fullAddress = result.customerData!.address;
          String? street;
          String? city;
          String? stateProvince;
          String? postalCode;
          String? country;
          if (fullAddress != null && fullAddress.trim().isNotEmpty) {
            final parts = fullAddress.split(',').map((e) => e.trim()).toList();
            if (parts.isNotEmpty) street = parts[0];
            if (parts.length > 1) city = parts[1];
            if (parts.length > 2) stateProvince = parts[2];
            if (parts.length > 3) postalCode = parts[3];
            if (parts.length > 4) country = parts[4];
          }
          DateTime? birthdateObj;
          if (result.customerData!.birthdate != null &&
              result.customerData!.birthdate!.isNotEmpty) {
            try {
              birthdateObj = DateTime.parse(result.customerData!.birthdate!);
            } catch (e) {
              print('Error parsing birthdate: $e');
            }
          }

          profileNotifier.value = ProfileData(
            firstName: result.customerData!.firstName,
            middleName: result.customerData!.middleName ?? '',
            lastName: result.customerData!.lastName,
            contactNumber: result.customerData!.phoneNumber ?? '',
            email: result.customerData!.email,
            birthdate: birthdateObj,
            emergencyContactName: result.customerData!.emergencyContactName,
            emergencyContactPhone: result.customerData!.emergencyContactNumber,
            address: fullAddress ?? '',
            street: street,
            city: city,
            stateProvince: stateProvince,
            postalCode: postalCode,
            country: country,
          );
        }

        return {
          'success': true,
          'data': {
            'customer_id': result.customerData?.customerId,
            'email': result.customerData?.email,
            'full_name': result.customerData?.fullName,
          },
        };
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  // Try to refresh customer token
  Future<void> _tryRefreshCustomerToken(String refreshToken) async {
    try {
      final refreshResult = await _refreshCustomerTokenWithBackend(
        refreshToken,
      );

      if (refreshResult != null && refreshResult['success'] == true) {
        final customerData = refreshResult['data'];
        _userType = UserType.customer;
        _customerId = customerData['customer_id'];
        _customerEmail = customerData['email'];
        _customerName = customerData['full_name'];
        _customerAccessToken = refreshResult['access_token'];
        _customerRefreshToken = refreshResult['refresh_token'];

        await _fetchMembershipData(customerData['customer_id']);
        await _saveCustomerTokens();
        notifyListeners();
      } else {
        await _clearCustomerTokens();
      }
    } catch (e) {
      print('Customer token refresh failed: $e');
      await _clearCustomerTokens();
    }
  }

  // Refresh customer token with backend
  Future<Map<String, dynamic>?> _refreshCustomerTokenWithBackend(
    String refreshToken,
  ) async {
    try {
      final result = await AuthService.refreshToken(refreshToken);
      if (result.success) {
        return {
          'success': true,
          'access_token': result.accessToken,
          'refresh_token': result.refreshToken,
          'data': {
            'customer_id': result.customerData?.customerId,
            'email': result.customerData?.email,
            'full_name': result.customerData?.fullName,
          },
        };
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  // Fetch membership data for a customer
  Future<void> _fetchMembershipData(int customerId) async {
    try {
      final membershipResult =
          await MembershipService.getMembershipByCustomerId(customerId);
      if (membershipResult.success && membershipResult.membershipData != null) {
        _membershipData = membershipResult.membershipData;
        print('✅ Membership data fetched: ${_membershipData?.membershipType}');
      } else {
        print('⚠️ No membership data found for customer $customerId');
        _membershipData = null;
      }
    } catch (e) {
      print('❌ Failed to fetch membership data: $e');
      _membershipData = null;
    }
  }

  // Save customer tokens
  Future<void> _saveCustomerTokens() async {
    try {
      print('💾 Saving customer tokens to storage...');
      final prefs = await SharedPreferences.getInstance();
      if (_customerAccessToken != null) {
        await prefs.setString('access_token', _customerAccessToken!);
        print('💾 Customer access token saved');
      }
      if (_customerRefreshToken != null) {
        await prefs.setString('refresh_token', _customerRefreshToken!);
        print('💾 Customer refresh token saved');
      }
      if (_customerId != null) {
        await prefs.setInt('customer_id', _customerId!);
      }
      if (_customerEmail != null) {
        await prefs.setString('customer_email', _customerEmail!);
      }
      if (_customerName != null) {
        await prefs.setString('customer_name', _customerName!);
      }
      print('💾 All customer tokens and data saved successfully');
    } catch (e) {
      print('❌ Failed to save customer tokens: $e');
    }
  }

  // Save admin tokens
  Future<void> _saveAdminTokens() async {
    try {
      print('💾 Saving admin tokens to storage...');
      final prefs = await SharedPreferences.getInstance();
      if (_adminAccessToken != null) {
        await prefs.setString('admin_token', _adminAccessToken!);
        print('💾 Admin access token saved');
      }
      if (_adminRefreshToken != null) {
        await prefs.setString('admin_refresh_token', _adminRefreshToken!);
        print('💾 Admin refresh token saved');
      }
      if (_adminData != null) {
        await prefs.setString('admin_data', jsonEncode(_adminData!));
        print('💾 Admin data saved');
      }
      print('💾 All admin tokens and data saved successfully');
    } catch (e) {
      print('❌ Failed to save admin tokens: $e');
    }
  }

  // Clear customer data
  void _clearCustomerData() {
    _customerId = null;
    _customerEmail = null;
    _customerName = null;
    _customerAccessToken = null;
    _customerRefreshToken = null;
    _membershipData = null;
  }

  // Clear admin data
  void _clearAdminData() {
    _adminData = null;
    _adminAccessToken = null;
    _adminRefreshToken = null;
  }

  // Clear customer tokens
  Future<void> _clearCustomerTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('customer_id');
      await prefs.remove('customer_email');
      await prefs.remove('customer_name');
    } catch (e) {
      print('Failed to clear customer tokens: $e');
    }
  }

  // Clear admin tokens
  Future<void> _clearAdminTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('admin_token');
      await prefs.remove('admin_refresh_token');
      await prefs.remove('admin_data');
    } catch (e) {
      print('Failed to clear admin tokens: $e');
    }
  }

  // Clear all tokens
  Future<void> _clearAllTokens() async {
    await _clearCustomerTokens();
    await _clearAdminTokens();

    // Also clear any locally cached profile form data
    try {
      profileNotifier.value = ProfileData();
    } catch (_) {}
  }
}

// Global instance
final UnifiedAuthState unifiedAuthState = UnifiedAuthState();
