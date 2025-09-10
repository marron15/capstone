import 'package:flutter/material.dart';
import 'dashboard/admin_profile.dart';
import 'services/admin_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Check if admin is already logged in
  Future<void> _checkLoginStatus() async {
    try {
      final isLoggedIn = await AdminService.isAdminLoggedIn();
      if (isLoggedIn && mounted) {
        _navigateToDashboard();
      }
    } catch (e) {
      debugPrint('Error checking login status: $e');
    }
  }

  @override
  void dispose() {
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle login
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AdminService.loginAdmin(
        contactNumber: _contactController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success'] == true && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Welcome back, ${result['admin']['first_name'] ?? 'Admin'}!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to dashboard
        _navigateToDashboard();
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Login failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Navigate to admin dashboard
  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AdminProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF141E30),
              Color(0xFF232526),
            ], // Dark gym-like gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 16,
                color: const Color(0xFF1A1F25), // Even darker card
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: size.width < 500 ? 16 : 0,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 36,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Gym Logo or App Name
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 34,
                              backgroundColor: Colors.greenAccent.withAlpha(38),
                              child: Icon(
                                Icons.fitness_center,
                                size: 44,
                                color: Colors.greenAccent.shade400,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'GYM ADMIN',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.greenAccent.shade400,
                                letterSpacing: 2,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _contactController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Contact Number',
                            labelStyle: TextStyle(
                              color: Colors.greenAccent.shade100,
                            ),
                            prefixIcon: Icon(
                              Icons.phone,
                              color: Colors.greenAccent.shade100,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF232526),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.greenAccent.shade400,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your contact number';
                            }
                            final onlyDigits = RegExp(r'^\d{11}$');
                            if (!onlyDigits.hasMatch(value.trim())) {
                              return 'Contact number must be exactly 11 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(
                              color: Colors.greenAccent.shade100,
                            ),
                            prefixIcon: Icon(
                              Icons.lock,
                              color: Colors.greenAccent.shade100,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF232526),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.greenAccent.shade400,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.greenAccent.shade100,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        // Error message display
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(50),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withAlpha(100),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Colors.greenAccent.shade400,
                              foregroundColor: Colors.black,
                              elevation: 6,
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.black,
                                            ),
                                      ),
                                    )
                                    : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
