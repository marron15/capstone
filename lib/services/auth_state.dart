import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'membership_service.dart';
import '../User Profile/profile_data.dart';

class AuthState extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  String? _customerEmail;
  String? _customerName;
  int? _customerId;
  String? _accessToken;
  String? _refreshToken;
  MembershipData? _membershipData;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  String? get customerEmail => _customerEmail;
  String? get customerName => _customerName;
  int? get customerId => _customerId;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  MembershipData? get membershipData => _membershipData;

  // Login method
  Future<void> login({
    required int customerId,
    required String email,
    required String fullName,
    String? accessToken,
    String? refreshToken,
  }) async {
    _isLoggedIn = true;
    _customerId = customerId;
    _customerEmail = email;
    _customerName = fullName;
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    // Fetch membership data
    await _fetchMembershipData(customerId);

    // Store tokens in SharedPreferences
    await _saveTokens();

    notifyListeners();
  }

  // Logout method
  Future<void> logout() async {
    _isLoggedIn = false;
    _customerId = null;
    _customerEmail = null;
    _customerName = null;
    _accessToken = null;
    _refreshToken = null;
    _membershipData = null;

    // Clear tokens from SharedPreferences
    await _clearTokens();

    notifyListeners();
  }

  // Check if customer is authenticated
  bool get isAuthenticated => _isLoggedIn;

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

  // Initialize auth state from stored tokens
  Future<void> initializeFromStorage() async {
    print('🔄 Initializing auth from storage...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final refreshToken = prefs.getString('refresh_token');

      print(
        '🔑 Found stored tokens: access=${accessToken != null}, refresh=${refreshToken != null}',
      );

      if (accessToken != null) {
        print('✅ Validating stored access token...');
        // Validate token with backend
        await _validateAndRestoreAuth(accessToken, refreshToken);
      } else {
        print('❌ No stored access token found');
      }

      _isInitialized = true;
      notifyListeners();
      print('✅ Auth initialization complete');
    } catch (e) {
      print('❌ Failed to initialize auth from storage: $e');
      // Clear any invalid tokens
      await _clearTokens();
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Validate token and restore auth state
  Future<void> _validateAndRestoreAuth(
    String? accessToken,
    String? refreshToken,
  ) async {
    if (accessToken == null) return;

    try {
      print('🔍 Validating token with backend...');
      final validationResult = await _validateTokenWithBackend(accessToken);
      print('🔍 Validation result: $validationResult');

      if (validationResult != null && validationResult['success'] == true) {
        final customerData = validationResult['data'];
        print('✅ Token valid! Restoring customer: ${customerData['email']}');
        _isLoggedIn = true;
        _customerId = customerData['customer_id'];
        _customerEmail = customerData['email'];
        _customerName = customerData['full_name'];
        _accessToken = accessToken;
        _refreshToken = refreshToken;

        // Fetch membership data when restoring auth state
        await _fetchMembershipData(customerData['customer_id']);

        notifyListeners();
        print('✅ Auth state restored successfully');
      } else if (refreshToken != null) {
        print('🔄 Access token invalid, trying refresh token...');
        // Try to refresh token
        await _tryRefreshToken(refreshToken);
      } else {
        print('❌ No valid tokens available');
        await _clearTokens();
      }
    } catch (e) {
      print('❌ Token validation failed: $e');
      await _clearTokens();
    }
  }

  // Try to refresh token
  Future<void> _tryRefreshToken(String refreshToken) async {
    try {
      // You'll implement this method in auth_service.dart
      final refreshResult = await _refreshTokenWithBackend(refreshToken);

      if (refreshResult != null && refreshResult['success'] == true) {
        final customerData = refreshResult['data'];
        _isLoggedIn = true;
        _customerId = customerData['customer_id'];
        _customerEmail = customerData['email'];
        _customerName = customerData['full_name'];
        _accessToken = refreshResult['access_token'];
        _refreshToken = refreshResult['refresh_token'];

        // Fetch membership data when refreshing token
        await _fetchMembershipData(customerData['customer_id']);

        await _saveTokens();
        notifyListeners();
      } else {
        await _clearTokens();
      }
    } catch (e) {
      print('Token refresh failed: $e');
      await _clearTokens();
    }
  }

  // Save tokens to SharedPreferences
  Future<void> _saveTokens() async {
    try {
      print('💾 Saving tokens to storage...');
      final prefs = await SharedPreferences.getInstance();
      if (_accessToken != null) {
        await prefs.setString('access_token', _accessToken!);
        print('💾 Access token saved');
      }
      if (_refreshToken != null) {
        await prefs.setString('refresh_token', _refreshToken!);
        print('💾 Refresh token saved');
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
      print('💾 All tokens and customer data saved successfully');
    } catch (e) {
      print('❌ Failed to save tokens: $e');
    }
  }

  // Clear tokens from SharedPreferences
  Future<void> _clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('customer_id');
      await prefs.remove('customer_email');
      await prefs.remove('customer_name');
    } catch (e) {
      print('Failed to clear tokens: $e');
    }
  }

  // Validate token with backend
  Future<Map<String, dynamic>?> _validateTokenWithBackend(String token) async {
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
            // Don't set password for security - it will be empty initially
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

  Future<Map<String, dynamic>?> _refreshTokenWithBackend(
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
}

// Global instance
final AuthState authState = AuthState();
