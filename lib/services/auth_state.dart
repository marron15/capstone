import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userEmail;
  String? _userName;
  int? _userId;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  int? get userId => _userId;

  // Login method
  void login({
    required int userId,
    required String email,
    required String fullName,
  }) {
    _isLoggedIn = true;
    _userId = userId;
    _userEmail = email;
    _userName = fullName;
    notifyListeners();
  }

  // Logout method
  void logout() {
    _isLoggedIn = false;
    _userId = null;
    _userEmail = null;
    _userName = null;
    notifyListeners();
  }

  // Check if user is authenticated
  bool get isAuthenticated => _isLoggedIn;
}

// Global instance
final AuthState authState = AuthState();
