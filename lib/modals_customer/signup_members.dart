import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../PH phone number valid/phone_formatter.dart';
import '../admin/services/api_service.dart';

class SignupMembersModal extends StatefulWidget {
  const SignupMembersModal({super.key});

  @override
  State<SignupMembersModal> createState() => _SignupMembersModalState();
}

class _SignupMembersModalState extends State<SignupMembersModal>
    with TickerProviderStateMixin {
  // UI state
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isRequestingVerification = false;
  bool _verificationRequested = false;
  int _currentStep = 0;

  // Animations
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  // Data state
  String? _signupError;
  String? _verificationError;
  String? _verificationStatusMessage;
  String? _pendingVerificationEmail;
  int? _verificationExpiresInMinutes;
  DateTime? _selectedBirthdate;
  String? _selectedMembershipType = 'Monthly';

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();

  // Address + emergency
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateProvinceController = TextEditingController(
    text: 'Zambales',
  );
  final TextEditingController _postalCodeController = TextEditingController(
    text: '2200',
  );
  final TextEditingController _countryController = TextEditingController();
  final FocusNode _streetFocusNode = FocusNode();
  static const List<String> _olongapoStreets = [
    'Abad Street',
    'Abra Street',
    'Acacia Street',
    'Afable Street',
    'Aguinaldo Street',
    'Anonas Street',
    'Argonaut Highway',
    'Arthur Street',
    'Bacon St.',
    'Balic-Balic Road',
    'Baloy Long Beach Road',
    'Barangay East Bajac-Bajac',
    'Barangay East Tapinac',
    'Barangay Gordon Heights',
    'Baretto Street',
    'Barreto St.',
    'Barreto Street',
    'Barrio Baretto',
    'Barryman Street',
    'Bayabas Street',
    'Betty Lane',
    'Boardwalk',
    'Bonifacio Street',
    'Braveheart Road',
    'Cagayan Street',
    'Canal Road',
    'Canda Street',
    'Causeway Rd',
    'Causeway Rd, Subic Bay Freeport Zone, Philippines',
    'Cebu Street',
    'City Square Mall Lane',
    'Columban Road',
    'Coral',
    'Davidson Street',
    'Del Pilar Street',
    'Dewey Avenue',
    'East 1st Street',
    'East 3rd Street',
    'East 6th Street',
    'East 18th Street',
    'East 20th Street',
    'East 21st Street',
    'East 23rd Street',
    'East 25th Street',
    'East 12th Street',
    'East 18th Street',
    'East 20th Street',
    'East 23rd Street',
    'East Bajac-bajac Bridge',
    'East Bajac-Bajac',
    'East Tapinac',
    'Elicano Street',
    'Eugenio Dela Casa Lane',
    'Fendler Extension',
    'Fendler Street',
    'Finback Street',
    'Foster Street',
    'Gabaya Street',
    'Gallagher Street',
    'Gordon Avenue',
    'Gordon Heights',
    'Graham Street',
    'Hansen Street',
    'Harris Street',
    'Hospital Road',
    'Hughes Street',
    'Ifugao Street',
    'Indiana Street',
    'Ipil-Ipil Street',
    'Jose Abad Santos Avenue',
    'Kalayaan Housing',
    'Kauffman Street',
    'Keith',
    'Kentucky Lane',
    'Kessing Street',
    'Labitan Street',
    'Lawin Street',
    'Long Road',
    'Magsaysay Drive',
    'Maine Street',
    'Manila Avenue',
    'Natividad Street',
    'New Asinan',
    'New Banicain',
    'New Kalalake',
    'Norton Street',
    'Pag-Asa',
    'Palm Street',
    'Perimeter Road',
    'Quezon Street',
    'RH 5 Subic Baraca National Highway',
    'Rizal Avenue Extension',
    'Rizal Avenue',
    'Rizal Highway',
    'Rizal Street',
    'Sampson Road, Subic Bay Freeport Zone, Philippines',
    'Santa Rita Street',
    'Santa Rita',
    'Saulog Genesis Terminal',
    'Schley Road',
    'Sta. Rita Road',
    'Subic-Tipo Expy',
    'Tabacuhan',
    'Tagumpay Street',
    'Texas Street',
    'Tulio Street',
    'Virginia Street',
    'West 20th Street',
    'West 21st Street',
    'West 22nd Street',
    'West 4th Street',
    'West 9th Street',
    'Waterdam Road',
    'Waterfront Road',
    'Waterfront Road, Subic Bay Freeport Zone, Philippines',
    'West 21st Street',
    'West 22nd Street',
    'West 23rd Street',
    'West Bajac Bajac',
    'West Tapinac',
    'ZAMODCA Transport',
  ];
  static final List<String> _streetOptions =
      LinkedHashSet<String>.from(_olongapoStreets).toList();
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  // Error states
  String? _firstNameError;
  String? _lastNameError;
  String? _birthdateError;
  String? _membershipTypeError;
  String? _contactError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _emergencyNameError;
  String? _emergencyPhoneError;
  String? _streetError;
  String? _cityError;
  String? _stateProvinceError;
  String? _postalCodeError;
  String? _countryError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
    _emailController.addListener(_emailListener);
    _lastNameController.addListener(_maybeAutoFillPassword);
    _confirmController.addListener(_validatePasswordMatch);
    _countryController.text = 'Philippines';
    _cityController.text = 'Olongapo City';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.removeListener(_emailListener);
    _lastNameController.removeListener(_maybeAutoFillPassword);
    _confirmController.removeListener(_validatePasswordMatch);

    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _birthdateController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _verificationCodeController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateProvinceController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _streetFocusNode.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.lightBlueAccent, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      errorText: errorText,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  void _emailListener() {
    if (!_verificationRequested) return;
    final normalized = _emailController.text.trim().toLowerCase();
    if (_pendingVerificationEmail != null &&
        normalized != _pendingVerificationEmail) {
      setState(_clearVerificationStateFields);
    }
  }

  void _validatePasswordMatch() {
    if (_confirmController.text.isEmpty) {
      setState(() => _confirmError = null);
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _confirmError = 'Passwords do not match.');
    } else {
      setState(() => _confirmError = null);
    }
  }

  void _clearVerificationStateFields() {
    _verificationRequested = false;
    _verificationStatusMessage = null;
    _verificationError = null;
    _pendingVerificationEmail = null;
    _verificationExpiresInMinutes = null;
    _verificationCodeController.clear();
  }

  void _maybeAutoFillPassword() {
    if (_selectedBirthdate == null) return;
    final String rawLastName = _lastNameController.text.trim();
    if (rawLastName.isEmpty) return;

    final String sanitizedLastName =
        rawLastName.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    final String month = _selectedBirthdate!.month.toString().padLeft(2, '0');
    final String day = _selectedBirthdate!.day.toString().padLeft(2, '0');
    final String generated = '$sanitizedLastName$month$day';

    _passwordController.text = generated;
    _confirmController.text = generated;
    _passwordError = null;
    _confirmError = null;
    setState(() {});
  }

  DateTime _calculateMembershipExpiration(DateTime startDate) {
    final type = (_selectedMembershipType ?? 'Monthly').toLowerCase();
    if (type == 'daily') {
      DateTime expiration = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        21,
      );
      if (startDate.hour >= 21) {
        expiration = expiration.add(const Duration(days: 1));
      }
      return expiration;
    }
    if (type == 'half month') return startDate.add(const Duration(days: 15));
    return startDate.add(const Duration(days: 30));
  }

  bool _validateStep0Inputs() {
    bool hasError = false;
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _birthdateError = null;
      _membershipTypeError = null;
    });

    if (_firstNameController.text.trim().isEmpty) {
      _firstNameError = 'First Name is required.';
      hasError = true;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _lastNameError = 'Last Name is required.';
      hasError = true;
    }
    if (_selectedBirthdate == null) {
      _birthdateError = 'Birthdate is required.';
      hasError = true;
    }
    if (_selectedMembershipType == null) {
      _membershipTypeError = 'Membership type is required.';
      hasError = true;
    }
    return !hasError;
  }

  bool _validateFinalStepInputs() {
    bool hasError = false;
    String? contactError;
    String? emailError;
    String? passwordError;
    String? confirmError;
    String? emergencyPhoneError;

    final String rawContact = _contactController.text.trim();
    if (rawContact.isNotEmpty) {
      final cleanedContact = PhoneFormatter.cleanPhoneNumber(rawContact);
      if (cleanedContact.length != 11) {
        contactError = 'Contact number must be 11 digits';
        hasError = true;
      }
    }

    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      emailError = 'Enter a valid email address';
      hasError = true;
    }

    final password = _passwordController.text;
    if (password.length < 6) {
      passwordError = 'Password must be at least 6 characters';
      hasError = true;
    }
    if (_confirmController.text != password) {
      confirmError = 'Passwords do not match';
      hasError = true;
    }

    final emergency = PhoneFormatter.cleanPhoneNumber(
      _emergencyPhoneController.text.trim(),
    );
    if (_emergencyPhoneController.text.trim().isNotEmpty &&
        emergency.length != 11) {
      emergencyPhoneError = 'Emergency phone must be 11 digits';
      hasError = true;
    }

    setState(() {
      _contactError = contactError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmError = confirmError;
      _emergencyPhoneError = emergencyPhoneError;
    });

    return !hasError;
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime date) =>
      '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';

  Future<void> _sendVerificationCode() async {
    if (!_validateFinalStepInputs()) return;

    final String firstName = _firstNameController.text.trim();
    final String middleName = _middleNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    final String email = _emailController.text.trim().toLowerCase();
    final String rawContact = _contactController.text.trim();
    final String? contactNumber =
        rawContact.isNotEmpty
            ? PhoneFormatter.cleanPhoneNumber(rawContact)
            : null;
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
        phoneNumber: contactNumber,
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
            _selectedMembershipType == 'Daily'
                ? _formatDateTime(membershipStartDate)
                : _formatDate(membershipStartDate),
        expirationDate:
            _selectedMembershipType == 'Daily'
                ? _formatDateTime(membershipEndDate)
                : _formatDate(membershipEndDate),
        createdBy: 'customer_portal',
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
        _clearVerificationStateFields();
        Navigator.of(context).pop({
          'success': true,
          'customerData': result['data'] ?? {},
          'membership_created': result['membership_created'] ?? false,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully.'),
            backgroundColor: Colors.green,
          ),
        );
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

  Widget _buildPersonalStep(BoxConstraints constraints) {
    final bool isWide = constraints.maxWidth > 520;
    final double fieldWidth =
        isWide ? (constraints.maxWidth - 10) / 2 : constraints.maxWidth;
    Widget sized(Widget child) => SizedBox(width: fieldWidth, child: child);

    Widget fields = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Information',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            sized(
              TextField(
                controller: _firstNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'First Name',
                  icon: Icons.person_outline,
                  errorText: _firstNameError,
                ),
              ),
            ),
            sized(
              TextField(
                controller: _middleNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Middle Name',
                  icon: Icons.person_outline,
                  hintText: 'Optional',
                ),
              ),
            ),
            sized(
              TextField(
                controller: _lastNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Last Name',
                  icon: Icons.person_outline,
                  errorText: _lastNameError,
                ),
              ),
            ),
            sized(
              DropdownButtonFormField<String>(
                key: ValueKey<String?>(_selectedMembershipType),
                initialValue: _selectedMembershipType,
                isExpanded: true,
                decoration: _inputDecoration(
                  label: 'Membership Type',
                  icon: Icons.card_membership,
                  errorText: _membershipTypeError,
                ),
                dropdownColor: Colors.blueGrey[900],
                style: const TextStyle(color: Colors.white),
                items:
                    ['Daily', 'Half Month', 'Monthly']
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged:
                    (val) => setState(() => _selectedMembershipType = val),
              ),
            ),
            sized(
              TextField(
                controller: _birthdateController,
                readOnly: true,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Birthdate',
                  icon: Icons.calendar_today,
                  hintText: 'YYYY-MM-DD',
                  errorText: _birthdateError,
                ),
                onTap: () async {
                  final DateTime initial = _selectedBirthdate ?? DateTime(2000);
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Colors.blue,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedBirthdate = picked;
                      _birthdateController.text = _formatDate(picked);
                    });
                    _maybeAutoFillPassword();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Address Information',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            sized(
              RawAutocomplete<String>(
                textEditingController: _streetController,
                focusNode: _streetFocusNode,
                optionsBuilder: (TextEditingValue value) {
                  final query = value.text.trim().toLowerCase();
                  final list =
                      query.isEmpty
                          ? _streetOptions
                          : _streetOptions
                              .where((s) => s.toLowerCase().contains(query))
                              .toList();
                  return list;
                },
                onSelected: (val) => _streetController.text = val,
                fieldViewBuilder: (
                  context,
                  controller,
                  focusNode,
                  onFieldSubmitted,
                ) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      label: 'Street',
                      icon: Icons.streetview,
                      errorText: _streetError,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_drop_down),
                        color: Colors.white70,
                        onPressed: () {
                          _streetFocusNode.requestFocus();
                          _streetController.value = _streetController.value
                              .copyWith(
                                text: _streetController.text,
                                selection: TextSelection.collapsed(
                                  offset: _streetController.text.length,
                                ),
                                composing: TextRange.empty,
                              );
                          setState(() {});
                        },
                      ),
                    ),
                    onTap: () => setState(() {}),
                    onSubmitted: (_) => onFieldSubmitted(),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: Colors.blueGrey[900],
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: fieldWidth,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              dense: true,
                              title: Text(
                                option,
                                style: const TextStyle(color: Colors.white),
                              ),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            sized(
              TextField(
                controller: _cityController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'City',
                  icon: Icons.location_city_outlined,
                  errorText: _cityError,
                ),
              ),
            ),
            sized(
              TextField(
                controller: _stateProvinceController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'State / Province',
                  icon: Icons.location_city,
                  errorText: _stateProvinceError,
                ),
              ),
            ),
            sized(
              TextField(
                controller: _postalCodeController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Postal Code',
                  icon: Icons.markunread_mailbox_outlined,
                  errorText: _postalCodeError,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            sized(
              TextField(
                controller: _countryController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Country',
                  icon: Icons.public_outlined,
                  errorText: _countryError,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Emergency Contact Information',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            sized(
              TextField(
                controller: _emergencyNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Emergency Contact Name',
                  icon: Icons.person,
                  errorText: _emergencyNameError,
                ),
              ),
            ),
            sized(
              TextField(
                controller: _emergencyPhoneController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Emergency Contact Phone',
                  icon: Icons.phone,
                  errorText: _emergencyPhoneError,
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneFormatter.phoneNumberFormatter],
              ),
            ),
          ],
        ),
      ],
    );

    return Column(
      children: [
        Expanded(child: SingleChildScrollView(child: fields)),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              if (_validateStep0Inputs()) {
                setState(() => _currentStep = 1);
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
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationStep(BoxConstraints constraints) {
    final bool isWide = constraints.maxWidth > 520;
    final double halfWidth =
        isWide ? (constraints.maxWidth - 10) / 2 : constraints.maxWidth;

    Widget fields = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact & Security',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: halfWidth,
              child: TextField(
                controller: _contactController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Contact Number (optional)',
                  icon: Icons.phone_outlined,
                  errorText: _contactError,
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneFormatter.phoneNumberFormatter],
              ),
            ),
            SizedBox(
              width: halfWidth,
              child: TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Email',
                  icon: Icons.email_outlined,
                  hintText: 'example@email.com',
                  errorText: _emailError,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            SizedBox(
              width: halfWidth,
              child: TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Password',
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  ),
                  errorText: _passwordError,
                ),
              ),
            ),
            SizedBox(
              width: halfWidth,
              child: TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Re-Enter Password',
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed:
                        () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  errorText: _confirmError,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Password auto-generated: last name + birth month & day (MMDD).',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 10),
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
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed:
                    _isRequestingVerification || _isLoading
                        ? null
                        : _sendVerificationCode,
                child: const Text('Resend code'),
              ),
            ],
          ),
          if (_verificationExpiresInMinutes != null)
            Text(
              'Code expires in $_verificationExpiresInMinutes minute(s)',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          const SizedBox(height: 10),
        ],
        if (_signupError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _signupError!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        fields,
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed:
                      (_isLoading || _isRequestingVerification)
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              )
                              : const Text(
                                'Verify & Create Account',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                          : const Text(
                            'Send Verification Code',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final double dialogWidth =
        MediaQuery.of(context).size.width < 820
            ? MediaQuery.of(context).size.width * 0.95
            : 720;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      alignment: Alignment.center,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Align(
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: dialogWidth,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.9,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: const Color(0xFF0E1114),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.18),
                            blurRadius: 32,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.person_add,
                                        color: Colors.lightBlueAccent,
                                        size: 26,
                                      ),
                                      SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          'Add New Member',
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
                                  onPressed: () => Navigator.of(context).pop(),
                                  tooltip: 'Close',
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Divider(
                                thickness: 1.4,
                                color: Colors.lightBlueAccent.withValues(
                                  alpha: 0.22,
                                ),
                                height: 16,
                                endIndent: 12,
                                indent: 2,
                              ),
                            ),
                            Flexible(
                              fit: FlexFit.loose,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return _currentStep == 0
                                      ? _buildPersonalStep(constraints)
                                      : _buildVerificationStep(constraints);
                                },
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
  }
}
