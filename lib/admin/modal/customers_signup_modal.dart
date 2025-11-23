import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../../PH phone number valid/phone_formatter.dart';

bool _isValidEmailAddress(String email) {
  final int atIndex = email.indexOf('@');
  if (atIndex <= 0 || atIndex == email.length - 1) {
    return false;
  }

  final String localPart = email.substring(0, atIndex);
  final String domainPart = email.substring(atIndex + 1);

  if (localPart.isEmpty || domainPart.isEmpty) {
    return false;
  }

  if (domainPart.contains('..') ||
      domainPart.startsWith('.') ||
      domainPart.endsWith('.')) {
    return false;
  }

  final List<String> labels = domainPart.split('.');
  if (labels.length < 2) {
    return false;
  }

  final String tld = labels.last;
  if (tld.length < 2 || tld.length > 24) {
    return false;
  }

  for (final String label in labels) {
    if (label.isEmpty) {
      return false;
    }
    for (final int code in label.codeUnits) {
      final bool isLetter =
          (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
      final bool isDigit = code >= 48 && code <= 57;
      if (!(isLetter || isDigit || code == 45)) {
        return false;
      }
    }
  }

  for (final int code in localPart.codeUnits) {
    final bool isLetter =
        (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
    final bool isDigit = code >= 48 && code <= 57;
    const String allowedSpecials = "!#\$%&'*+-/=?^_`{|}~.";
    if (!(isLetter ||
        isDigit ||
        allowedSpecials.contains(String.fromCharCode(code)))) {
      return false;
    }
  }

  return true;
}

class AdminSignUpModal extends StatefulWidget {
  const AdminSignUpModal({super.key});

  @override
  State<AdminSignUpModal> createState() => _AdminSignUpModalState();
}

class _AdminSignUpModalState extends State<AdminSignUpModal>
    with TickerProviderStateMixin {
  bool _obscurePassword = true;
  bool _obscureRePassword = true;
  bool _isLoading = false;
  String? _signupError;
  late AnimationController _controller;
  Animation<double>? _scaleAnim;
  Animation<double>? _fadeAnim;
  late AnimationController _iconController;
  Animation<double>? _iconAnim;

  int _currentStep = 0;
  DateTime? _selectedBirthdate;
  final TextEditingController _birthdateController = TextEditingController();
  String? _selectedMembershipType = 'Monthly';
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _middleNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _dobDayFocus = FocusNode();
  final FocusNode _dobMonthFocus = FocusNode();
  final FocusNode _dobYearFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _contactFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();
  final FocusNode _rePassFocus = FocusNode();
  File? _selectedImage;
  Uint8List? _webImageBytes;
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _rePasswordController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();

  // Error state variables for required fields
  String? _firstNameError;
  String? _lastNameError;
  String? _birthdateError;
  String? _emergencyNameError;
  String? _emergencyPhoneError;
  String? _contactError;
  String? _emailError;
  String? _passwordError;
  String? _rePasswordError;
  String? _membershipTypeError;

  // Controllers for address fields
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateProvinceController =
      TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  // Error state variables for address fields
  String? _streetError;
  String? _cityError;
  String? _stateProvinceError;
  String? _postalCodeError;
  String? _countryError;
  bool _verificationRequested = false;
  bool _isRequestingVerification = false;
  String? _verificationStatusMessage;
  String? _verificationError;
  String? _pendingVerificationEmail;
  int? _verificationExpiresInMinutes;
  DateTime? _pendingMembershipStartDate;
  DateTime? _pendingMembershipExpirationDate;

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
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _iconAnim = Tween<double>(begin: 0.0, end: 0.12).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
    _emailController.addListener(_emailListener);
    _rePasswordController.addListener(_validatePasswordMatch);

    // Prefill default country for sign up
    _countryController.text = 'Philippines';
  }

  @override
  void dispose() {
    _controller.dispose();
    _iconController.dispose();
    _firstNameFocus.dispose();
    _middleNameFocus.dispose();
    _lastNameFocus.dispose();
    _contactFocus.dispose();
    _emailFocus.dispose();
    _dobDayFocus.dispose();
    _dobMonthFocus.dispose();
    _dobYearFocus.dispose();
    _passFocus.dispose();
    _rePassFocus.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _birthdateController.dispose();
    _passwordController.dispose();
    _rePasswordController.dispose();
    _verificationCodeController.dispose();
    _emailController.removeListener(_emailListener);
    _rePasswordController.removeListener(_validatePasswordMatch);
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    Widget? suffixIcon,
    String? hintText,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white),
      filled: true,
      fillColor: Colors.black.withAlpha((0.3 * 255).toInt()),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.lightBlueAccent, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withAlpha((0.18 * 255).toInt()),
          width: 1.2,
        ),
      ),
      suffixIcon: suffixIcon,
      errorText: errorText,
    );
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Use file_picker for web
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _webImageBytes = result.files.single.bytes;
        });
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } else {
      // Desktop (Windows, macOS, Linux)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
        });
      }
    }
  }

  void _clearVerificationStateFields() {
    _verificationRequested = false;
    _verificationStatusMessage = null;
    _verificationError = null;
    _pendingVerificationEmail = null;
    _verificationExpiresInMinutes = null;
    _pendingMembershipStartDate = null;
    _pendingMembershipExpirationDate = null;
    _verificationCodeController.clear();
  }

  void _emailListener() {
    if (!_verificationRequested) return;
    final normalized = _emailController.text.trim().toLowerCase();
    if (_pendingVerificationEmail != null &&
        normalized != _pendingVerificationEmail) {
      if (mounted) {
        setState(_clearVerificationStateFields);
      } else {
        _clearVerificationStateFields();
      }
    }
  }

  void _validatePasswordMatch() {
    // Only validate if re-enter password field is not empty
    if (_rePasswordController.text.isEmpty) {
      setState(() {
        _rePasswordError = null;
      });
      return;
    }

    if (_passwordController.text != _rePasswordController.text) {
      setState(() {
        _rePasswordError = 'Passwords do not match.';
      });
    } else {
      setState(() {
        _rePasswordError = null;
      });
    }
  }

  String? _composeAddressString() {
    final parts =
        [
          _streetController.text.trim(),
          _cityController.text.trim(),
          _stateProvinceController.text.trim(),
          _postalCodeController.text.trim(),
          _countryController.text.trim(),
        ].where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  DateTime _calculateMembershipExpiration(DateTime startDate) {
    final type = (_selectedMembershipType ?? 'Monthly').toLowerCase();
    if (type == 'daily') return startDate.add(const Duration(days: 1));
    if (type == 'half month') return startDate.add(const Duration(days: 15));
    return startDate.add(const Duration(days: 30));
  }

  bool _validateFinalStepInputs() {
    bool hasError = false;
    String? contactError;
    String? emailError;
    String? passwordError;
    String? emergencyPhoneError;

    final cleanedContact = PhoneFormatter.cleanPhoneNumber(
      _contactController.text.trim(),
    );
    if (cleanedContact.isNotEmpty && cleanedContact.length != 11) {
      contactError = 'Contact number must be exactly 11 digits';
      hasError = true;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      emailError = 'Email is required.';
      hasError = true;
    } else if (!_isValidEmailAddress(email)) {
      emailError = 'Please enter a valid email address';
      hasError = true;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      passwordError = 'Password is required.';
      hasError = true;
    } else if (password.length < 6) {
      passwordError = 'Password must be at least 6 characters long';
      hasError = true;
    }

    final emergency = PhoneFormatter.cleanPhoneNumber(
      _emergencyPhoneController.text.trim(),
    );
    if (emergency.isNotEmpty && emergency.length != 11) {
      emergencyPhoneError =
          'Emergency contact number must be exactly 11 digits';
      hasError = true;
    }

    if (_rePasswordError != null) {
      hasError = true;
    }

    setState(() {
      _contactError = contactError;
      _emailError = emailError;
      _passwordError = passwordError;
      _emergencyPhoneError = emergencyPhoneError;
    });
    return !hasError;
  }

  Future<void> _sendVerificationCode() async {
    if (!_validateFinalStepInputs()) return;

    final String firstName = _firstNameController.text.trim();
    final String middleName = _middleNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    final String email = _emailController.text.trim().toLowerCase();
    final String contactNumber = PhoneFormatter.cleanPhoneNumber(
      _contactController.text.trim(),
    );
    final String emergencyContact = PhoneFormatter.cleanPhoneNumber(
      _emergencyPhoneController.text.trim(),
    );
    final String? birthdate =
        _selectedBirthdate != null ? _birthdateController.text.trim() : null;
    final DateTime membershipStartDate = DateTime.now();
    final DateTime membershipEndDate = _calculateMembershipExpiration(
      membershipStartDate,
    );

    setState(() {
      _isRequestingVerification = true;
      _signupError = null;
      _verificationError = null;
    });

    try {
      final result = await ApiService.requestCustomerSignupCode(
        firstName: firstName,
        lastName: lastName,
        middleName: middleName.isNotEmpty ? middleName : null,
        email: email,
        password: _passwordController.text,
        birthdate: birthdate,
        phoneNumber: contactNumber.isNotEmpty ? contactNumber : null,
        emergencyContactName:
            _emergencyNameController.text.trim().isNotEmpty
                ? _emergencyNameController.text.trim()
                : null,
        emergencyContactNumber:
            emergencyContact.isNotEmpty ? emergencyContact : null,
        street:
            _streetController.text.trim().isNotEmpty
                ? _streetController.text.trim()
                : null,
        city:
            _cityController.text.trim().isNotEmpty
                ? _cityController.text.trim()
                : null,
        state:
            _stateProvinceController.text.trim().isNotEmpty
                ? _stateProvinceController.text.trim()
                : null,
        postalCode:
            _postalCodeController.text.trim().isNotEmpty
                ? _postalCodeController.text.trim()
                : null,
        country:
            _countryController.text.trim().isNotEmpty
                ? _countryController.text.trim()
                : null,
        membershipType: _selectedMembershipType,
        membershipStartDate:
            '${membershipStartDate.year}-${membershipStartDate.month.toString().padLeft(2, '0')}-${membershipStartDate.day.toString().padLeft(2, '0')}',
        expirationDate:
            '${membershipEndDate.year}-${membershipEndDate.month.toString().padLeft(2, '0')}-${membershipEndDate.day.toString().padLeft(2, '0')}',
      );

      if (result['success'] == true) {
        setState(() {
          _verificationRequested = true;
          _verificationStatusMessage = result['message'];
          _verificationError = null;
          _pendingVerificationEmail = email;
          _verificationExpiresInMinutes =
              result['expires_in_minutes'] is int
                  ? result['expires_in_minutes']
                  : int.tryParse(
                    result['expires_in_minutes']?.toString() ?? '',
                  );
          _pendingMembershipStartDate = membershipStartDate;
          _pendingMembershipExpirationDate = membershipEndDate;
        });
        _verificationCodeController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Verification code sent successfully.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _verificationError =
              result['message'] ?? 'Failed to send verification code.';
        });
      }
    } catch (e) {
      setState(() {
        _verificationError =
            'Failed to send verification code. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingVerification = false;
        });
      }
    }
  }

  Future<void> _handleSignup() async {
    if (!_verificationRequested) {
      setState(() {
        _signupError = 'Send a verification code before creating the account.';
      });
      return;
    }

    final String code = _verificationCodeController.text.trim();
    if (code.length != 6) {
      setState(() {
        _verificationError = 'Enter the 6-digit verification code.';
      });
      return;
    }

    final String email =
        (_pendingVerificationEmail ?? _emailController.text.trim())
            .toLowerCase();

    setState(() {
      _signupError = null;
      _verificationError = null;
      _isLoading = true;
    });

    try {
      final result = await ApiService.verifyCustomerSignupCode(
        email: email,
        verificationCode: code,
      );

      if (result['success'] == true && mounted) {
        final String firstName = _firstNameController.text.trim();
        final String middleName = _middleNameController.text.trim();
        final String lastName = _lastNameController.text.trim();
        final String contact = PhoneFormatter.cleanPhoneNumber(
          _contactController.text.trim(),
        );
        final String? birthdate =
            _selectedBirthdate != null
                ? _birthdateController.text.trim()
                : null;
        final String? fullAddress = _composeAddressString();
        final DateTime startDate =
            _pendingMembershipStartDate ?? DateTime.now();
        final DateTime expirationDate =
            _pendingMembershipExpirationDate ??
            _calculateMembershipExpiration(startDate);

        _clearVerificationStateFields();

        Navigator.of(context).pop({
          'success': true,
          'customerData': {
            'name': '$firstName $lastName',
            'contactNumber': contact,
            'membershipType': _selectedMembershipType,
            'expirationDate': expirationDate,
            'startDate': startDate,
            'email': email,
            'fullName':
                '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName',
            'birthdate': birthdate,
            'address': fullAddress,
            'emergencyContactName': _emergencyNameController.text.trim(),
            'emergencyContactPhone': _emergencyPhoneController.text.trim(),
            'customerId': result['data']?['customer_id'],
          },
        });
      } else {
        setState(() {
          _signupError =
              result['message'] ?? 'Failed to verify the signup code.';
        });
      }
    } catch (e) {
      setState(() {
        _signupError = 'Verification failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: FadeTransition(
        opacity: _fadeAnim ?? const AlwaysStoppedAnimation(1.0),
        child: ScaleTransition(
          scale: _scaleAnim ?? const AlwaysStoppedAnimation(1.0),
          child: Align(
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  // Glassmorphism effect only behind modal
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width:
                          MediaQuery.of(context).size.width < 800
                              ? MediaQuery.of(context).size.width * 0.98
                              : 740,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: Colors.black.withAlpha((0.7 * 255).toInt()),
                        border: Border.all(
                          color: Colors.white.withAlpha((0.25 * 255).toInt()),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withAlpha(
                              (0.18 * 255).toInt(),
                            ),
                            blurRadius: 32,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 38,
                          vertical: 22,
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
                                        AnimatedBuilder(
                                          animation:
                                              _iconAnim ??
                                              const AlwaysStoppedAnimation(0.0),
                                          builder: (context, child) {
                                            return Transform.rotate(
                                              angle:
                                                  (_iconAnim ??
                                                          const AlwaysStoppedAnimation(
                                                            0.0,
                                                          ))
                                                      .value,
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.blueAccent
                                                          .withAlpha(
                                                            (0.25 * 255)
                                                                .toInt(),
                                                          ),
                                                      Colors.lightBlueAccent
                                                          .withAlpha(
                                                            (0.18 * 255)
                                                                .toInt(),
                                                          ),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.person_add,
                                                  color: Colors.lightBlueAccent,
                                                  size: 24,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 12),
                                        const Flexible(
                                          child: Text(
                                            'Add New Customer',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: Colors.white,
                                              letterSpacing: 0.2,
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
                              const SizedBox(height: 1),
                              Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                child: Divider(
                                  thickness: 1.5,
                                  color: Colors.lightBlueAccent.withAlpha(
                                    (0.22 * 255).toInt(),
                                  ),
                                  height: 24,
                                  endIndent: 12,
                                  indent: 2,
                                ),
                              ),
                              if (_currentStep == 0) ...[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 1.5),
                                    const Text(
                                      'Personal Information \n',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final bool isWide =
                                            constraints.maxWidth > 520;
                                        final double fieldWidth =
                                            isWide
                                                ? (constraints.maxWidth - 16) /
                                                    2
                                                : constraints.maxWidth;
                                        Widget sized(Widget child) => SizedBox(
                                          width: fieldWidth,
                                          child: child,
                                        );
                                        return Wrap(
                                          spacing: 16,
                                          runSpacing: 14,
                                          children: [
                                            sized(
                                              TextField(
                                                controller:
                                                    _firstNameController,
                                                focusNode: _firstNameFocus,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: _inputDecoration(
                                                  label: 'First Name',
                                                  icon: Icons.person_outline,
                                                  focusNode: _firstNameFocus,
                                                  hintText: 'First Name',
                                                  errorText: _firstNameError,
                                                ),
                                              ),
                                            ),
                                            sized(
                                              TextField(
                                                controller:
                                                    _middleNameController,
                                                focusNode: _middleNameFocus,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: _inputDecoration(
                                                  label: 'Middle Name',
                                                  icon: Icons.person_outline,
                                                  focusNode: _middleNameFocus,
                                                  hintText: 'M.I.',
                                                ),
                                              ),
                                            ),
                                            sized(
                                              TextField(
                                                controller: _lastNameController,
                                                focusNode: _lastNameFocus,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: _inputDecoration(
                                                  label: 'Last Name',
                                                  icon: Icons.person_outline,
                                                  focusNode: _lastNameFocus,
                                                  hintText: 'Last Name',
                                                  errorText: _lastNameError,
                                                ),
                                              ),
                                            ),
                                            sized(
                                              DropdownButtonFormField<String>(
                                                key: ValueKey<String?>(
                                                  _selectedMembershipType,
                                                ),
                                                initialValue:
                                                    _selectedMembershipType,
                                                decoration: _inputDecoration(
                                                  label: 'Membership Type',
                                                  icon: Icons.card_membership,
                                                  focusNode: null,
                                                  errorText:
                                                      _membershipTypeError,
                                                ),
                                                dropdownColor:
                                                    Colors.blueGrey[900],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                                items:
                                                    [
                                                          'Daily',
                                                          'Half Month',
                                                          'Monthly',
                                                        ]
                                                        .map(
                                                          (type) =>
                                                              DropdownMenuItem(
                                                                value: type,
                                                                child: Text(
                                                                  type,
                                                                ),
                                                              ),
                                                        )
                                                        .toList(),
                                                onChanged:
                                                    (val) => setState(
                                                      () =>
                                                          _selectedMembershipType =
                                                              val,
                                                    ),
                                              ),
                                            ),
                                            sized(
                                              TextField(
                                                controller:
                                                    _birthdateController,
                                                readOnly: true,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: _inputDecoration(
                                                  label: 'Birthdate',
                                                  icon: Icons.calendar_today,
                                                  hintText: 'YYYY-MM-DD',
                                                  errorText: _birthdateError,
                                                ),
                                                onTap: () async {
                                                  final DateTime initial =
                                                      _selectedBirthdate ??
                                                      DateTime.now();
                                                  final DateTime?
                                                  picked = await showDatePicker(
                                                    context: context,
                                                    initialDate: initial,
                                                    firstDate: DateTime(1950),
                                                    lastDate: DateTime.now(),
                                                    builder: (context, child) {
                                                      return Theme(
                                                        data: Theme.of(
                                                          context,
                                                        ).copyWith(
                                                          colorScheme:
                                                              const ColorScheme.light(
                                                                primary:
                                                                    Colors.blue,
                                                                onPrimary:
                                                                    Colors
                                                                        .white,
                                                                surface:
                                                                    Colors
                                                                        .white,
                                                                onSurface:
                                                                    Colors
                                                                        .black,
                                                              ),
                                                        ),
                                                        child: child!,
                                                      );
                                                    },
                                                  );
                                                  if (picked != null) {
                                                    setState(() {
                                                      _selectedBirthdate =
                                                          picked;
                                                      _birthdateController
                                                              .text =
                                                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Address Information (moved under Personal Information)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Address Information',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final bool isWide =
                                            constraints.maxWidth > 520;
                                        final double fieldWidth =
                                            isWide
                                                ? (constraints.maxWidth - 16) /
                                                    2
                                                : constraints.maxWidth;
                                        Widget sized(Widget child) => SizedBox(
                                          width: fieldWidth,
                                          child: child,
                                        );
                                        return Wrap(
                                          spacing: 16,
                                          runSpacing: 14,
                                          children: [
                                            sized(
                                              TextField(
                                                controller: _streetController,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: _inputDecoration(
                                                  label: 'Street',
                                                  icon: Icons.streetview,
                                                  hintText: 'Enter street name',
                                                  errorText: _streetError,
                                                ),
                                              ),
                                            ),
                                            sized(
                                              TextField(
                                                controller: _cityController,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: _inputDecoration(
                                                  label: 'City',
                                                  icon:
                                                      Icons
                                                          .location_city_outlined,
                                                  hintText: 'Enter city name',
                                                  errorText: _cityError,
                                                ),
                                              ),
                                            ),
                                            sized(
                                              TextField(
                                                controller:
                                                    _stateProvinceController,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: _inputDecoration(
                                                  label: 'State / Province',
                                                  icon: Icons.location_city,
                                                  hintText:
                                                      'Enter state or province',
                                                  errorText:
                                                      _stateProvinceError,
                                                ),
                                              ),
                                            ),
                                            sized(
                                              TextField(
                                                controller:
                                                    _postalCodeController,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: _inputDecoration(
                                                  label: 'Postal Code',
                                                  icon:
                                                      Icons
                                                          .markunread_mailbox_outlined,
                                                  hintText: 'Enter postal code',
                                                  errorText: _postalCodeError,
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ),
                                            sized(
                                              TextField(
                                                controller: _countryController,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: _inputDecoration(
                                                  label: 'Country',
                                                  icon: Icons.public_outlined,
                                                  hintText: 'Enter country',
                                                  errorText: _countryError,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Emergency information (under Address)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Emergency Contact Information',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final bool isWide =
                                            constraints.maxWidth > 520;
                                        final double fieldWidth =
                                            isWide
                                                ? (constraints.maxWidth - 16) /
                                                    2
                                                : constraints.maxWidth;
                                        Widget sized(Widget child) => SizedBox(
                                          width: fieldWidth,
                                          child: child,
                                        );
                                        return Wrap(
                                          spacing: 16,
                                          runSpacing: 14,
                                          children: [
                                            sized(
                                              TextField(
                                                controller:
                                                    _emergencyNameController,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: _inputDecoration(
                                                  label:
                                                      'Emergency Contact Name',
                                                  icon: Icons.person,
                                                  hintText: 'Full Name',
                                                  errorText:
                                                      _emergencyNameError,
                                                ),
                                              ),
                                            ),
                                            sized(
                                              TextField(
                                                controller:
                                                    _emergencyPhoneController,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: _inputDecoration(
                                                  label:
                                                      'Emergency Contact Phone',
                                                  icon: Icons.phone,

                                                  errorText:
                                                      _emergencyPhoneError,
                                                ),
                                                keyboardType:
                                                    TextInputType.phone,
                                                inputFormatters: [
                                                  PhoneFormatter
                                                      .phoneNumberFormatter,
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () {
                                      // Clear previous errors for step 0
                                      setState(() {
                                        _firstNameError = null;
                                        _lastNameError = null;
                                        _birthdateError = null;
                                        _membershipTypeError = null;
                                      });

                                      // Validate fields for step 0
                                      bool hasError = false;
                                      if (_firstNameController.text
                                          .trim()
                                          .isEmpty) {
                                        setState(() {
                                          _firstNameError =
                                              'First Name is required.';
                                        });
                                        hasError = true;
                                      }
                                      if (_lastNameController.text
                                          .trim()
                                          .isEmpty) {
                                        setState(() {
                                          _lastNameError =
                                              'Last Name is required.';
                                        });
                                        hasError = true;
                                      }
                                      if (_selectedBirthdate == null) {
                                        setState(() {
                                          _birthdateError =
                                              'Birthdate is required.';
                                        });
                                        hasError = true;
                                      }
                                      if (_selectedMembershipType == null) {
                                        setState(() {
                                          _membershipTypeError =
                                              'Membership type is required.';
                                        });
                                        hasError = true;
                                      }

                                      if (!hasError) {
                                        setState(() {
                                          _currentStep = 1;
                                        });
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                      color: Colors.black,
                                    ),
                                    label: const Text(
                                      'Next',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else if (_currentStep == -1) ...[
                                // Emergency contact and image upload step (moved to step 1)
                                const Text(
                                  'Upload Profile Image (Optional)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: CircleAvatar(
                                    radius: 48,
                                    backgroundColor: Colors.white24,
                                    backgroundImage:
                                        _webImageBytes != null
                                            ? MemoryImage(_webImageBytes!)
                                            : _selectedImage != null
                                            ? FileImage(_selectedImage!)
                                                as ImageProvider
                                            : null,
                                    child:
                                        (_webImageBytes == null &&
                                                _selectedImage == null)
                                            ? IconButton(
                                              icon: const Icon(
                                                Icons.camera_alt,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                              onPressed: _pickImage,
                                            )
                                            : null,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _emergencyNameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    label: 'Emergency Contact Name',
                                    icon: Icons.person,
                                    hintText: 'Full Name',
                                    errorText: _emergencyNameError,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _emergencyPhoneController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    label: 'Emergency Contact Phone',
                                    icon: Icons.phone,

                                    errorText: _emergencyPhoneError,
                                  ),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    PhoneFormatter.phoneNumberFormatter,
                                  ],
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _currentStep = 0;
                                              _clearVerificationStateFields();
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.arrow_back,
                                            size: 18,
                                            color: Colors.black,
                                          ),
                                          label: const Text(
                                            'Back',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _emergencyNameError = null;
                                              _emergencyPhoneError = null;
                                            });

                                            bool hasError = false;
                                            if (_emergencyNameController.text
                                                .trim()
                                                .isEmpty) {
                                              setState(() {
                                                _emergencyNameError =
                                                    'Emergency contact name is required.';
                                              });
                                              hasError = true;
                                            }
                                            if (_emergencyPhoneController.text
                                                .trim()
                                                .isEmpty) {
                                              setState(() {
                                                _emergencyPhoneError =
                                                    'Emergency contact phone is required.';
                                              });
                                              hasError = true;
                                            }

                                            if (!hasError) {
                                              setState(() {
                                                _currentStep = 2;
                                              });
                                            }
                                          },
                                          child: const Text(
                                            'Next',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (_currentStep == -1) ...[
                                // Address step (moved to step 2)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Address Information',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _streetController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        label: 'Street',
                                        icon: Icons.streetview,
                                        hintText: 'Enter street name',
                                        errorText: _streetError,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextField(
                                      controller: _cityController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        label: 'City',
                                        icon: Icons.location_city_outlined,
                                        hintText: 'Enter city name',
                                        errorText: _cityError,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextField(
                                      controller: _stateProvinceController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        label: 'State / Province',
                                        icon: Icons.location_city,
                                        hintText: 'Enter state or province',
                                        errorText: _stateProvinceError,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextField(
                                      controller: _postalCodeController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        label: 'Postal Code',
                                        icon: Icons.markunread_mailbox_outlined,
                                        hintText: 'Enter postal code',
                                        errorText: _postalCodeError,
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 14),
                                    TextField(
                                      controller: _countryController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        label: 'Country',
                                        icon: Icons.public_outlined,
                                        hintText: 'Enter country',
                                        errorText: _countryError,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _currentStep = 1;
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.arrow_back,
                                            size: 18,
                                            color: Colors.black,
                                          ),
                                          label: const Text(
                                            'Back',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _streetError = null;
                                              _cityError = null;
                                              _stateProvinceError = null;
                                              _postalCodeError = null;
                                              _countryError = null;
                                            });

                                            bool hasError = false;
                                            if (_cityController.text
                                                .trim()
                                                .isEmpty) {
                                              setState(() {
                                                _cityError =
                                                    'City is required.';
                                              });
                                              hasError = true;
                                            }
                                            if (_stateProvinceController.text
                                                .trim()
                                                .isEmpty) {
                                              setState(() {
                                                _stateProvinceError =
                                                    'State / Province is required.';
                                              });
                                              hasError = true;
                                            }
                                            if (_postalCodeController.text
                                                .trim()
                                                .isEmpty) {
                                              setState(() {
                                                _postalCodeError =
                                                    'Postal Code is required.';
                                              });
                                              hasError = true;
                                            }
                                            if (_countryController.text
                                                .trim()
                                                .isEmpty) {
                                              setState(() {
                                                _countryError =
                                                    'Country is required.';
                                              });
                                              hasError = true;
                                            }

                                            if (!hasError) {
                                              setState(() {
                                                _currentStep = 3;
                                              });
                                            }
                                          },
                                          child: const Text(
                                            'Next',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                // Contact, email, and password step
                                TextField(
                                  controller: _contactController,
                                  focusNode: _contactFocus,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    label: 'Contact Number',
                                    icon: Icons.phone_outlined,
                                    focusNode: _contactFocus,

                                    errorText: _contactError,
                                  ),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    PhoneFormatter.phoneNumberFormatter,
                                  ],
                                ),
                                const SizedBox(height: 18),
                                TextField(
                                  controller: _emailController,
                                  focusNode: _emailFocus,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                    focusNode: _emailFocus,
                                    hintText: 'example@email.com',
                                    errorText: _emailError,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 18),
                                TextField(
                                  controller: _passwordController,
                                  focusNode: _passFocus,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    focusNode: _passFocus,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white70,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () =>
                                                _obscurePassword =
                                                    !_obscurePassword,
                                          ),
                                    ),
                                  ).copyWith(errorText: _passwordError),
                                ),
                                const SizedBox(height: 18),
                                TextField(
                                  controller: _rePasswordController,
                                  focusNode: _rePassFocus,
                                  obscureText: _obscureRePassword,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    label: 'Re-Enter Password',
                                    icon: Icons.lock_outline,
                                    focusNode: _rePassFocus,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureRePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white70,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () =>
                                                _obscureRePassword =
                                                    !_obscureRePassword,
                                          ),
                                    ),
                                  ).copyWith(errorText: _rePasswordError),
                                ),
                                const SizedBox(height: 16),
                                if (_verificationRequested) ...[
                                  TextField(
                                    controller: _verificationCodeController,
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(6),
                                    ],
                                    decoration: _inputDecoration(
                                      label: 'Verification Code',
                                      icon: Icons.verified_outlined,
                                      errorText: _verificationError,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _verificationStatusMessage ??
                                              'Enter the 6-digit code sent to ${_pendingVerificationEmail ?? _emailController.text.trim()}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed:
                                            _isRequestingVerification ||
                                                    _isLoading
                                                ? null
                                                : _sendVerificationCode,
                                        child: const Text('Resend code'),
                                      ),
                                    ],
                                  ),
                                  if (_verificationExpiresInMinutes != null)
                                    Text(
                                      'Code expires in $_verificationExpiresInMinutes minute(s)',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                ],
                                // Error message display
                                if (_signupError != null)
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
                                            _signupError!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _currentStep = 0;
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.arrow_back,
                                            size: 18,
                                            color: Colors.black,
                                          ),
                                          label: const Text(
                                            'Back',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          onPressed:
                                              (_isLoading ||
                                                      _isRequestingVerification)
                                                  ? null
                                                  : () async {
                                                    if (_verificationRequested) {
                                                      await _handleSignup();
                                                    } else {
                                                      await _sendVerificationCode();
                                                    }
                                                  },
                                          child:
                                              _verificationRequested
                                                  ? _isLoading
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
                                                        'Verify & Create Account',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15,
                                                          color: Colors.black,
                                                        ),
                                                      )
                                                  : _isRequestingVerification
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
                                                    'Send Verification Code',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 15,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
