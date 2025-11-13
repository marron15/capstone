import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/unified_auth_state.dart';
import '../User Profile/profile_data.dart';
import '../utils/dom_input_utils.dart';

class LoginModal extends StatefulWidget {
  const LoginModal({Key? key}) : super(key: key);

  @override
  State<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal>
    with TickerProviderStateMixin, RestorationMixin {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _controller;
  Animation<double>? _scaleAnim;
  Animation<double>? _fadeAnim;
  // Removed unused icon animation

  final FocusNode _contactFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  final TextEditingController _contactOrEmailController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  bool _domAttributesScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _scheduleDomAttributeSync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleDomAttributeSync();
  }

  @override
  String? get restorationId => 'customer_login_modal';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {}

  @override
  void dispose() {
    _controller.dispose();
    _contactFocus.dispose();
    _passFocus.dispose();
    _contactOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _scheduleDomAttributeSync() {
    if (_domAttributesScheduled || !mounted) return;
    _domAttributesScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setInputAttributes('input[autocomplete="tel"]', {
        'id': 'customer-login-phone',
        'name': 'customer-login-phone',
      });
      setInputAttributes('input[autocomplete="current-password"]', {
        'id': 'customer-login-password',
        'name': 'customer-login-password',
      });
      _domAttributesScheduled = false;
    });
  }

  Future<void> _handleLogin() async {
    final contactOrEmail = _contactOrEmailController.text.trim();
    final rawContact = contactOrEmail.replaceAll(' ', '');
    final password = _passwordController.text;

    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Validate input
    if (rawContact.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Email and password are required';
      });
      return;
    }

    // Validate contact number (expects 11 digits like 09XXXXXXXXX)
    final bool isValidPhone =
        rawContact.length == 11 &&
        rawContact.codeUnits.every((code) => code >= 48 && code <= 57);
    if (!isValidPhone) {
      setState(() {
        _errorMessage = 'Please enter a valid contact number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.login(rawContact, password);

      if (result.success && result.customerData != null) {
        // Login successful - update auth state with JWT tokens
        await unifiedAuthState.loginCustomer(
          customerId: result.customerData!.customerId,
          email: result.customerData!.email,
          fullName: result.customerData!.fullName,
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
        );

        // Populate profile data with login information
        DateTime? birthdateObj;
        if (result.customerData!.birthdate != null &&
            result.customerData!.birthdate!.isNotEmpty) {
          try {
            birthdateObj = DateTime.parse(result.customerData!.birthdate!);
          } catch (e) {
            print('Error parsing birthdate: $e');
          }
        }

        // Parse composite address into parts for the profile form
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

        if (mounted) {
          Navigator.of(context).pop(); // Close login modal

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Welcome back, ${result.customerData!.firstName} ${result.customerData!.lastName}!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Login failed
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    Widget? suffixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white60, fontSize: 14),
      prefixIcon: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFFA812), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: FadeTransition(
        opacity: _fadeAnim ?? const AlwaysStoppedAnimation(1.0),
        child: ScaleTransition(
          scale: _scaleAnim ?? const AlwaysStoppedAnimation(1.0),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width:
                          MediaQuery.of(context).size.width < 460
                              ? MediaQuery.of(context).size.width * 0.95
                              : 460,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.black.withValues(alpha: 0.9),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: 4,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 36,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Center(
                                            child: Text(
                                              'Welcome Back',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                                color: Colors.white,
                                                letterSpacing: 0.2,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      size: 26,
                                      color: Colors.white,
                                    ),
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    tooltip: 'Close',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: const Text(
                                  'Login your account',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Divider(
                                  thickness: 1.5,
                                  color: Colors.lightBlueAccent.withAlpha(
                                    (0.22 * 255).toInt(),
                                  ),
                                  height: 50,
                                  endIndent: 12,
                                  indent: 2,
                                ),
                              ),
                              Form(
                                key: _loginFormKey,
                                child: AutofillGroup(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        controller: _contactOrEmailController,
                                        focusNode: _contactFocus,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        decoration: _inputDecoration(
                                          label: 'Contact Number',
                                          icon: Icons.phone_outlined,
                                          focusNode: _contactFocus,
                                        ),
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(11),
                                        ],
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.telephoneNumber,
                                        ],
                                        restorationId: 'login_contact_number',
                                        validator: (_) => null,
                                        onFieldSubmitted:
                                            (_) => FocusScope.of(
                                              context,
                                            ).requestFocus(_passFocus),
                                      ),
                                      const SizedBox(height: 35),
                                      TextFormField(
                                        controller: _passwordController,
                                        focusNode: _passFocus,
                                        obscureText: _obscurePassword,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        decoration: _inputDecoration(
                                          label: 'Password',
                                          icon: Icons.lock_outline,
                                          focusNode: _passFocus,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.white,
                                            ),
                                            onPressed:
                                                () => setState(
                                                  () =>
                                                      _obscurePassword =
                                                          !_obscurePassword,
                                                ),
                                          ),
                                        ),
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                        restorationId: 'login_password',
                                        validator: (_) => null,
                                        onFieldSubmitted:
                                            (_) =>
                                                _isLoading
                                                    ? null
                                                    : _handleLogin(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Error message display
                              if (_errorMessage != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(
                                      (0.2 * 255).toInt(),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withAlpha(
                                        (0.5 * 255).toInt(),
                                      ),
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

                              const SizedBox(height: 24),
                              _AnimatedGradientButton(
                                onPressed: _isLoading ? null : _handleLogin,
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
                                          'Log In',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                              ),
                            ],
                          ),
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
  }
}

class _AnimatedGradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  const _AnimatedGradientButton({required this.onPressed, required this.child});

  @override
  State<_AnimatedGradientButton> createState() =>
      _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<_AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.0,
      upperBound: 0.08,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final Color hoverAccent = const Color(0xFFFFA812);
    final Color textColor = _isHovering ? hoverAccent : Colors.black;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: isEnabled ? _onTapDown : null,
        onTapUp: isEnabled ? _onTapUp : null,
        onTapCancel: isEnabled ? _onTapCancel : null,
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color:
                      isEnabled
                          ? Colors.white
                          : Colors.grey.withValues(alpha: 0.3),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isEnabled
                              ? Colors.black.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: widget.onPressed,
                    child: Container(
                      alignment: Alignment.center,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeInOut,
                        style: TextStyle(
                          color: isEnabled ? textColor : Colors.grey[600],
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                        child: widget.child,
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

class PhoneNumberFormatter extends TextInputFormatter {
  const PhoneNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsBuffer = StringBuffer();
    for (final rune in newValue.text.runes) {
      if (rune >= 48 && rune <= 57) {
        digitsBuffer.writeCharCode(rune);
      }
    }
    final digitsOnly = digitsBuffer.toString();
    final limited =
        digitsOnly.length > 11 ? digitsOnly.substring(0, 11) : digitsOnly;

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      buffer.write(limited[i]);
      if (i == 3 || i == 6) buffer.write(' '); // #### ### ####
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
