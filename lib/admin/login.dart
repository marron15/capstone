import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/admin_service.dart';
import '../services/unified_auth_state.dart';
import '../utils/dom_input_utils.dart';

class LoginPage extends StatefulWidget {
  final bool checkLoginStatus;

  const LoginPage({super.key, this.checkLoginStatus = false});

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
  String? _contactError;
  String? _passwordError;
  bool _domAttributesScheduled = false;

  @override
  void initState() {
    super.initState();
    // Only check login status if explicitly requested
    if (widget.checkLoginStatus) {
      _checkLoginStatus();
    }
    _scheduleDomAttributeSync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleDomAttributeSync();
  }

  // Check if admin is already logged in
  Future<void> _checkLoginStatus() async {
    try {
      // Check if admin is already logged in through unified auth state
      if (unifiedAuthState.isAdminLoggedIn && mounted) {
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

  void _scheduleDomAttributeSync() {
    if (_domAttributesScheduled || !mounted) return;
    _domAttributesScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setInputAttributes('input[autocomplete="tel"]', {
        'id': 'admin-login-phone',
        'name': 'admin-login-phone',
      });
      setInputAttributes('input[autocomplete="current-password"]', {
        'id': 'admin-login-password',
        'name': 'admin-login-password',
      });
      _domAttributesScheduled = false;
    });
  }

  // Handle login
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _contactError = null;
      _passwordError = null;
    });

    try {
      final contactDigits =
          _contactController.text
              .split('')
              .where(
                (char) => char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57,
              )
              .join();
      final result = await AdminService.loginAdmin(
        contactNumber: contactDigits,
        password: _passwordController.text,
      );

      if (result['success'] == true && mounted) {
        // Update unified auth state
        await unifiedAuthState.loginAdmin(
          admin: result['admin'],
          accessToken: result['access_token'],
          refreshToken: result['refresh_token'],
        );

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
          _errorMessage = null; // no global banner
          final String? field = result['field'] as String?;
          if (field == 'phone') {
            _contactError =
                result['message'] as String? ?? 'Invalid contact number';
          } else if (field == 'password') {
            _passwordError = result['message'] as String? ?? 'Invalid password';
          } else {
            _contactError = null;
            _passwordError = null;
            _errorMessage = result['message'] as String? ?? 'Login failed';
          }
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
    Navigator.of(context).pushReplacementNamed('/admin-dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(235, 0, 0, 0),
        elevation: 4,
        centerTitle: true,
        title: const Text(
          'RNR Fitness Gym',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false);
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 245, 245, 245),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Transform.translate(
                      offset: const Offset(0, -24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // RNR Logo outside the card
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Image.asset(
                              'assets/images/RNR.png',
                              width: 200,
                              height: 150,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: size.width < 500 ? 16 : 0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 40,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 20),
                                ),
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  blurRadius: 60,
                                  spreadRadius: -5,
                                  offset: const Offset(0, 30),
                                ),
                              ],
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Gym Logo or App Name
                                    Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 34,
                                          backgroundColor: Colors.grey
                                              .withAlpha(38),
                                          child: Icon(
                                            Icons.admin_panel_settings,
                                            size: 44,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          'GYM ADMIN',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.grey.shade800,
                                            letterSpacing: 2,
                                            fontFamily: 'Roboto',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    TextFormField(
                                      controller: _contactController,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Contact Number',
                                        labelStyle: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.phone,
                                          color: Colors.grey.shade600,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: const Color.fromRGBO(
                                              255,
                                              168,
                                              18,
                                              1,
                                            ),
                                            width: 2,
                                          ),
                                        ),
                                        errorText: _contactError,
                                      ),
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(11),
                                      ],
                                      autofillHints: const [
                                        AutofillHints.telephoneNumber,
                                      ],
                                      restorationId: 'admin_login_contact',
                                      onFieldSubmitted:
                                          (_) =>
                                              FocusScope.of(
                                                context,
                                              ).nextFocus(),
                                      validator: (value) {
                                        final digitsBuffer = StringBuffer();
                                        for (final rune
                                            in (value ?? '').runes) {
                                          if (rune >= 48 && rune <= 57) {
                                            digitsBuffer.writeCharCode(rune);
                                          }
                                        }
                                        final digits = digitsBuffer.toString();
                                        if (digits.isEmpty) {
                                          return 'Please enter your contact number';
                                        }
                                        final isElevenDigits =
                                            digits.length == 11 &&
                                            digits.codeUnits.every(
                                              (code) =>
                                                  code >= 48 && code <= 57,
                                            );
                                        if (!isElevenDigits) {
                                          return 'Contact number must be exactly 11 digits';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        labelStyle: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.lock,
                                          color: Colors.grey.shade600,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: const Color.fromRGBO(
                                              255,
                                              168,
                                              18,
                                              1,
                                            ),
                                            width: 2,
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: Colors.grey.shade600,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible =
                                                  !_isPasswordVisible;
                                            });
                                          },
                                        ),
                                        errorText: _passwordError,
                                      ),
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      restorationId: 'admin_login_password',
                                      onFieldSubmitted:
                                          (_) =>
                                              _isLoading
                                                  ? null
                                                  : _handleLogin(),
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
                                    // Optional global message fallback (as plain text)
                                    if (_errorMessage != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
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
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.black),
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
