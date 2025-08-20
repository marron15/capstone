import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class AuthState extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  String? _userEmail;
  String? _userName;
  int? _userId;
  String? _accessToken;
  String? _refreshToken;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  int? get userId => _userId;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  // Login method
  Future<void> login({
    required int userId,
    required String email,
    required String fullName,
    String? accessToken,
    String? refreshToken,
  }) async {
    _isLoggedIn = true;
    _userId = userId;
    _userEmail = email;
    _userName = fullName;
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    // Store tokens in SharedPreferences
    await _saveTokens();

    notifyListeners();
  }

  // Logout method
  Future<void> logout() async {
    _isLoggedIn = false;
    _userId = null;
    _userEmail = null;
    _userName = null;
    _accessToken = null;
    _refreshToken = null;

    // Clear tokens from SharedPreferences
    await _clearTokens();

    notifyListeners();
  }

  // Check if user is authenticated
  bool get isAuthenticated => _isLoggedIn;

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
        final userData = validationResult['data'];
        print('✅ Token valid! Restoring user: ${userData['email']}');
        _isLoggedIn = true;
        _userId = userData['user_id'];
        _userEmail = userData['email'];
        _userName = userData['full_name'];
        _accessToken = accessToken;
        _refreshToken = refreshToken;
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
        final userData = refreshResult['data'];
        _isLoggedIn = true;
        _userId = userData['user_id'];
        _userEmail = userData['email'];
        _userName = userData['full_name'];
        _accessToken = refreshResult['access_token'];
        _refreshToken = refreshResult['refresh_token'];

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
      if (_userId != null) {
        await prefs.setInt('user_id', _userId!);
      }
      if (_userEmail != null) {
        await prefs.setString('user_email', _userEmail!);
      }
      if (_userName != null) {
        await prefs.setString('user_name', _userName!);
      }
      print('💾 All tokens and user data saved successfully');
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
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
    } catch (e) {
      print('Failed to clear tokens: $e');
    }
  }

  // Validate token with backend
  Future<Map<String, dynamic>?> _validateTokenWithBackend(String token) async {
    try {
      final result = await AuthService.validateToken(token);
      if (result.success) {
        return {
          'success': true,
          'data': {
            'user_id': result.userData?.userId,
            'email': result.userData?.email,
            'full_name': result.userData?.fullName,
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
            'user_id': result.userData?.userId,
            'email': result.userData?.email,
            'full_name': result.userData?.fullName,
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
