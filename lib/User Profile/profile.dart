import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'profile_data.dart';

import '../services/auth_service.dart';
import '../services/unified_auth_state.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  late TextEditingController _firstNameController = TextEditingController(
    text: profileNotifier.value.firstName,
  );
  late TextEditingController _middleNameController = TextEditingController(
    text: profileNotifier.value.middleName,
  );
  late TextEditingController _lastNameController = TextEditingController(
    text: profileNotifier.value.lastName,
  );
  late TextEditingController _contactController = TextEditingController(
    text: profileNotifier.value.contactNumber,
  );
  late TextEditingController _emailController = TextEditingController(
    text: profileNotifier.value.email ?? '',
  );

  late VoidCallback _firstNameListener;
  late VoidCallback _middleNameListener;
  late VoidCallback _lastNameListener;
  late VoidCallback _contactListener;
  late VoidCallback _emailListener;
  late VoidCallback _profileListener;
  late VoidCallback _passwordListener;
  String? _contactError;
  String? _emergencyPhoneError;

  DateTime? _birthdate;
  TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Controllers for address fields (composite Address field removed)
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateProvinceController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;
  late VoidCallback _streetListener;
  late VoidCallback _cityListener;
  late VoidCallback _stateProvinceListener;
  late VoidCallback _postalCodeListener;
  late VoidCallback _countryListener;

  // Controllers for emergency contact
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late VoidCallback _emergencyNameListener;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _birthdate = profileNotifier.value.birthdate;
    // Don't populate password field for security - it will be empty initially
    _passwordController.text = '';

    // Initialize address controllers
    _streetController = TextEditingController(
      text: profileNotifier.value.street ?? '',
    );
    _cityController = TextEditingController(
      text: profileNotifier.value.city ?? '',
    );
    _stateProvinceController = TextEditingController(
      text: profileNotifier.value.stateProvince ?? '',
    );
    _postalCodeController = TextEditingController(
      text: profileNotifier.value.postalCode ?? '',
    );
    _countryController = TextEditingController(
      text: profileNotifier.value.country ?? '',
    );

    // Initialize emergency contact controllers
    _emergencyNameController = TextEditingController(
      text: profileNotifier.value.emergencyContactName ?? '',
    );
    _emergencyPhoneController = TextEditingController(
      text: profileNotifier.value.emergencyContactPhone ?? '',
    );

    _firstNameListener = () => setState(() {});
    _middleNameListener = () => setState(() {});
    _lastNameListener = () => setState(() {});
    _contactListener = () {
      _validateContactInline();
      setState(() {});
    };
    _emailListener = () => setState(() {});

    _firstNameController.addListener(_firstNameListener);
    _middleNameController.addListener(_middleNameListener);
    _lastNameController.addListener(_lastNameListener);
    _contactController.addListener(_contactListener);
    _emailController.addListener(_emailListener);
    _passwordListener = () => setState(() {});
    _passwordController.addListener(_passwordListener);
    _emergencyPhoneController.addListener(_validateEmergencyPhoneInline);

    // Address field listeners so Save/Cancel visibility updates while typing
    _streetListener = () => setState(() {});
    _cityListener = () => setState(() {});
    _stateProvinceListener = () => setState(() {});
    _postalCodeListener = () => setState(() {});
    _countryListener = () => setState(() {});
    _streetController.addListener(_streetListener);
    _cityController.addListener(_cityListener);
    _stateProvinceController.addListener(_stateProvinceListener);
    _postalCodeController.addListener(_postalCodeListener);
    _countryController.addListener(_countryListener);

    // Emergency name listener for button visibility
    _emergencyNameListener = () => setState(() {});
    _emergencyNameController.addListener(_emergencyNameListener);

    // Keep UI in sync when profile data is populated after app refresh/login restore
    _profileListener = () {
      final p = profileNotifier.value;
      // Update controllers only when values actually changed to avoid cursor jumps
      if (_firstNameController.text != p.firstName) {
        _firstNameController.text = p.firstName;
      }
      if (_middleNameController.text != p.middleName) {
        _middleNameController.text = p.middleName;
      }
      if (_lastNameController.text != p.lastName) {
        _lastNameController.text = p.lastName;
      }
      if (_contactController.text != p.contactNumber) {
        _contactController.text = p.contactNumber;
      }
      if (_emailController.text != (p.email ?? '')) {
        _emailController.text = p.email ?? '';
      }
      // No composite address field to sync
      if (_streetController.text != (p.street ?? '')) {
        _streetController.text = p.street ?? '';
      }
      if (_cityController.text != (p.city ?? '')) {
        _cityController.text = p.city ?? '';
      }
      if (_stateProvinceController.text != (p.stateProvince ?? '')) {
        _stateProvinceController.text = p.stateProvince ?? '';
      }
      if (_postalCodeController.text != (p.postalCode ?? '')) {
        _postalCodeController.text = p.postalCode ?? '';
      }
      if (_countryController.text != (p.country ?? '')) {
        _countryController.text = p.country ?? '';
      }
      if (_emergencyNameController.text != (p.emergencyContactName ?? '')) {
        _emergencyNameController.text = p.emergencyContactName ?? '';
      }
      if (_emergencyPhoneController.text != (p.emergencyContactPhone ?? '')) {
        _emergencyPhoneController.text = p.emergencyContactPhone ?? '';
      }
      if (_birthdate != p.birthdate) {
        setState(() {
          _birthdate = p.birthdate;
        });
      } else {
        // Still trigger a rebuild so Save buttons reflect latest comparisons
        setState(() {});
      }
    };
    profileNotifier.addListener(_profileListener);
    // Run an initial sync in case profile data was already restored before this page mounted
    _profileListener();

    // As a fallback, fetch profile from API on first mount if fields are empty after auth restore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureProfileLoaded();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.removeListener(_firstNameListener);
    _middleNameController.removeListener(_middleNameListener);
    _lastNameController.removeListener(_lastNameListener);
    _contactController.removeListener(_contactListener);
    _emailController.removeListener(_emailListener);
    _passwordController.removeListener(_passwordListener);
    profileNotifier.removeListener(_profileListener);
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();

    _passwordController.dispose();
    // Dispose of address controllers
    _streetController.removeListener(_streetListener);
    _cityController.removeListener(_cityListener);
    _stateProvinceController.removeListener(_stateProvinceListener);
    _postalCodeController.removeListener(_postalCodeListener);
    _countryController.removeListener(_countryListener);
    _streetController.dispose();
    _cityController.dispose();
    _stateProvinceController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    // Dispose of emergency contact controllers
    _emergencyNameController.removeListener(_emergencyNameListener);
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  bool _hasChanges() {
    return _firstNameController.text != profileNotifier.value.firstName ||
        _middleNameController.text != profileNotifier.value.middleName ||
        _lastNameController.text != profileNotifier.value.lastName ||
        _contactController.text != profileNotifier.value.contactNumber ||
        _emailController.text != (profileNotifier.value.email ?? '') ||
        _birthdate != profileNotifier.value.birthdate ||
        _passwordController.text.trim().isNotEmpty ||
        _streetController.text != (profileNotifier.value.street ?? '') ||
        _cityController.text != (profileNotifier.value.city ?? '') ||
        _stateProvinceController.text !=
            (profileNotifier.value.stateProvince ?? '') ||
        _postalCodeController.text !=
            (profileNotifier.value.postalCode ?? '') ||
        _countryController.text != (profileNotifier.value.country ?? '') ||
        _emergencyNameController.text !=
            (profileNotifier.value.emergencyContactName ?? '') ||
        _emergencyPhoneController.text !=
            (profileNotifier.value.emergencyContactPhone ?? '');
  }

  bool _hasAddressChanges() {
    return _streetController.text != (profileNotifier.value.street ?? '') ||
        _cityController.text != (profileNotifier.value.city ?? '') ||
        _stateProvinceController.text !=
            (profileNotifier.value.stateProvince ?? '') ||
        _postalCodeController.text !=
            (profileNotifier.value.postalCode ?? '') ||
        _countryController.text != (profileNotifier.value.country ?? '');
  }

  bool _hasEmergencyContactChanges() {
    return _emergencyNameController.text !=
            (profileNotifier.value.emergencyContactName ?? '') ||
        _emergencyPhoneController.text !=
            (profileNotifier.value.emergencyContactPhone ?? '');
  }

  void _resetPersonalInfo() {
    final p = profileNotifier.value;
    _firstNameController.text = p.firstName;
    _middleNameController.text = p.middleName;
    _lastNameController.text = p.lastName;
    _contactController.text = p.contactNumber;
    _emailController.text = p.email ?? '';
    setState(() {
      _birthdate = p.birthdate;
      _passwordController.clear();
      _obscurePassword = true;
      _contactError = null;
    });
  }

  void _resetAddress() {
    final p = profileNotifier.value;
    _streetController.text = p.street ?? '';
    _cityController.text = p.city ?? '';
    _stateProvinceController.text = p.stateProvince ?? '';
    _postalCodeController.text = p.postalCode ?? '';
    _countryController.text = p.country ?? '';
    setState(() {});
  }

  void _validateContactInline() {
    final String v = _contactController.text.trim();
    if (v.isEmpty) {
      _contactError = null;
      return;
    }
    // Enforce length and digits only
    final bool digitsOnly = RegExp(r'^\d+$').hasMatch(v);
    if (!digitsOnly || v.length != 11) {
      _contactError = 'Contact number must be exactly 11 digits';
    } else {
      _contactError = null;
    }
  }

  void _validateEmergencyPhoneInline() {
    final String raw = _emergencyPhoneController.text.trim();
    if (raw.isEmpty) {
      _emergencyPhoneError = null;
      return;
    }
    final String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) {
      _emergencyPhoneError = 'Contact number must be exactly 11 digits';
    } else {
      _emergencyPhoneError = null;
    }
    setState(() {});
  }

  void _resetEmergency() {
    final p = profileNotifier.value;
    _emergencyNameController.text = p.emergencyContactName ?? '';
    _emergencyPhoneController.text = p.emergencyContactPhone ?? '';
    setState(() {
      _emergencyPhoneError = null;
    });
  }

  // Save profile changes to server
  Future<void> _saveProfileToServer() async {
    try {
      final customerId = unifiedAuthState.customerId;
      if (customerId == null) return;

      // Prepare profile data for update
      // When user wants to change only password, some text fields may be empty
      // because they haven't touched them. Backend requires first_name, last_name, email.
      // Use existing profile values as fallback for required fields.
      String firstName = _firstNameController.text.trim();
      if (firstName.isEmpty) firstName = profileNotifier.value.firstName;
      String lastName = _lastNameController.text.trim();
      if (lastName.isEmpty) lastName = profileNotifier.value.lastName;
      String middleName = _middleNameController.text.trim();
      if (middleName.isEmpty) middleName = profileNotifier.value.middleName;
      String email = _emailController.text.trim();
      if (email.isEmpty) email = (profileNotifier.value.email ?? '');
      if (email.isEmpty) email = (unifiedAuthState.customerEmail ?? '');
      String phone = _contactController.text.trim();
      if (phone.isEmpty) phone = profileNotifier.value.contactNumber;

      // Validate emergency phone if provided
      final String emergencyPhoneValRaw = _emergencyPhoneController.text.trim();
      final String emergencyPhoneVal = emergencyPhoneValRaw.replaceAll(
        RegExp(r'\D'),
        '',
      );
      if (emergencyPhoneVal.isNotEmpty && emergencyPhoneVal.length != 11) {
        setState(() {
          _emergencyPhoneError = 'Contact number must be exactly 11 digits';
        });
        return;
      } else {
        _emergencyPhoneError = null;
      }

      final Map<String, dynamic> profileData = {
        'customer_id': customerId,
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName,
        'email': email,
        'birthdate': _birthdate?.toIso8601String(),
        'phone_number': phone,
        'emergency_contact_name':
            _emergencyNameController.text.trim().isNotEmpty
                ? _emergencyNameController.text.trim()
                : (profileNotifier.value.emergencyContactName ?? ''),
        // Backend expects `emergency_contact_number` key
        'emergency_contact_number':
            emergencyPhoneVal.isNotEmpty
                ? emergencyPhoneVal
                : (profileNotifier.value.emergencyContactPhone ?? ''),
      };

      // Address: backend expects `address_details` object, not flat keys
      final Map<String, String> addressDetails = {
        'street':
            _streetController.text.trim().isNotEmpty
                ? _streetController.text.trim()
                : (profileNotifier.value.street ?? ''),
        'city':
            _cityController.text.trim().isNotEmpty
                ? _cityController.text.trim()
                : (profileNotifier.value.city ?? ''),
        'state':
            _stateProvinceController.text.trim().isNotEmpty
                ? _stateProvinceController.text.trim()
                : (profileNotifier.value.stateProvince ?? ''),
        'postal_code':
            _postalCodeController.text.trim().isNotEmpty
                ? _postalCodeController.text.trim()
                : (profileNotifier.value.postalCode ?? ''),
        'country':
            _countryController.text.trim().isNotEmpty
                ? _countryController.text.trim()
                : (profileNotifier.value.country ?? ''),
      };

      // Only include when any field is non-empty (avoid sending empty object)
      final bool hasAddressAny = addressDetails.values.any(
        (v) => v.trim().isNotEmpty,
      );
      if (hasAddressAny) {
        profileData['address_details'] = addressDetails;
      }

      // Include password only when user typed a new one
      final String newPassword = _passwordController.text.trim();
      if (newPassword.isNotEmpty) {
        profileData['password'] = newPassword;
      }

      final response = await AuthService.updateProfile(profileData);

      if (response.success == true) {
        // Update local profile data
        profileNotifier.value = ProfileData(
          imageFile: profileNotifier.value.imageFile,
          webImageBytes: profileNotifier.value.webImageBytes,
          firstName: _firstNameController.text.trim(),
          middleName: _middleNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          contactNumber: _contactController.text.trim(),
          email: _emailController.text.trim(),
          birthdate: _birthdate,
          password: profileNotifier.value.password,
          address: profileNotifier.value.address,
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          stateProvince: _stateProvinceController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: _countryController.text.trim(),
          emergencyContactName: _emergencyNameController.text.trim(),
          emergencyContactPhone: _emergencyPhoneController.text.trim(),
        );

        // Clear password field after successful update
        if (newPassword.isNotEmpty) {
          _passwordController.clear();
          _obscurePassword = true;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthdate) {
      setState(() {
        _birthdate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If user is logged out, prevent showing stale data
    if (!unifiedAuthState.isCustomerLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Profile', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Please log in to view your profile.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/customer-landing');
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }
    final isMobile = MediaQuery.of(context).size.width < 600;
    final titleFontSize = isMobile ? 24.0 : 32.0;
    final buttonPadding =
        isMobile
            ? EdgeInsets.symmetric(vertical: 14)
            : EdgeInsets.symmetric(vertical: 18);

    final labelFontSize = isMobile ? 13.0 : 15.0;
    final textFieldFontSize = isMobile ? 14.0 : 16.0;

    // Personal Information Tab
    Widget personalInfoTab = SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 32),
              // Personal Information Fields
              if (isMobile) ...[
                _buildLabel('First Name', labelFontSize),
                _buildTextField(
                  _firstNameController,
                  'First Name',
                  fontSize: textFieldFontSize,
                ),
                SizedBox(height: 16),

                _buildLabel('Middle Name', labelFontSize),
                _buildTextField(
                  _middleNameController,
                  'Middle Name',
                  fontSize: textFieldFontSize,
                ),
                SizedBox(height: 16),

                _buildLabel('Last Name', labelFontSize),
                _buildTextField(
                  _lastNameController,
                  'Last Name',
                  fontSize: textFieldFontSize,
                ),
                SizedBox(height: 16),

                _buildLabel('Contact Number', labelFontSize),
                TextField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Contact Number',
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black87, width: 1.5),
                    ),
                    errorText: _contactError,
                  ),
                  style: TextStyle(
                    fontSize: textFieldFontSize,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),

                _buildLabel('Email', labelFontSize),
                _buildTextField(
                  _emailController,
                  'Email',
                  keyboardType: TextInputType.emailAddress,
                  fontSize: textFieldFontSize,
                ),
                SizedBox(height: 16),

                _buildLabel('Birthdate', labelFontSize),
                _buildDateField(textFieldFontSize, context),
                SizedBox(height: 16),

                _buildLabel('Password', labelFontSize),
                _buildPasswordField(textFieldFontSize),
              ] else ...[
                _buildRow(
                  left: _buildLabeledField(
                    'First Name',
                    _firstNameController,
                    'First Name',
                    labelFontSize,
                    textFieldFontSize,
                  ),
                  right: _buildLabeledField(
                    'Middle Name',
                    _middleNameController,
                    'Middle Name',
                    labelFontSize,
                    textFieldFontSize,
                  ),
                ),
                SizedBox(height: 16),
                _buildRow(
                  left: _buildLabeledField(
                    'Last Name',
                    _lastNameController,
                    'Last Name',
                    labelFontSize,
                    textFieldFontSize,
                  ),
                  right: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Contact Number', labelFontSize),
                      TextField(
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Contact Number',
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.black87,
                              width: 1.5,
                            ),
                          ),
                          errorText: _contactError,
                        ),
                        style: TextStyle(
                          fontSize: textFieldFontSize,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                _buildRow(
                  left: _buildLabeledField(
                    'Email',
                    _emailController,
                    'Email',
                    labelFontSize,
                    textFieldFontSize,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  right: _buildLabeledDate(
                    'Birthdate',
                    labelFontSize,
                    textFieldFontSize,
                    context,
                  ),
                ),
                SizedBox(height: 16),
                _buildLabeledPassword(
                  'Password',
                  labelFontSize,
                  textFieldFontSize,
                ),
              ],
              SizedBox(height: 32),

              // Save/Cancel buttons for personal info
              if (_hasChanges() || _passwordController.text.trim().isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white24),
                          padding: buttonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _resetPersonalInfo,
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: buttonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saveProfileToServer,
                        child: Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );

    // Address Tab
    Widget addressTab = SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Address Information',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 32),

              if (isMobile) ...[
                _buildLabel('Street', labelFontSize),
                _buildTextField(
                  _streetController,
                  'Street',
                  fontSize: textFieldFontSize,
                ),
                SizedBox(height: 16),
                _buildLabel('City', labelFontSize),
                _buildTextField(
                  _cityController,
                  'City',
                  fontSize: textFieldFontSize,
                ),
                SizedBox(height: 16),
                _buildLabel('State/Province', labelFontSize),
                _buildTextField(
                  _stateProvinceController,
                  'State/Province',
                  fontSize: textFieldFontSize,
                ),
                SizedBox(height: 16),
                _buildLabel('Postal Code', labelFontSize),
                _buildTextField(
                  _postalCodeController,
                  'Postal Code',
                  fontSize: textFieldFontSize,
                ),
                SizedBox(height: 16),
                _buildLabel('Country', labelFontSize),
                _buildTextField(
                  _countryController,
                  'Country',
                  fontSize: textFieldFontSize,
                ),
              ] else ...[
                _buildRow(
                  left: _buildLabeledField(
                    'Street',
                    _streetController,
                    'Street',
                    labelFontSize,
                    textFieldFontSize,
                  ),
                  right: _buildLabeledField(
                    'City',
                    _cityController,
                    'City',
                    labelFontSize,
                    textFieldFontSize,
                  ),
                ),
                SizedBox(height: 16),
                _buildRow(
                  left: _buildLabeledField(
                    'State/Province',
                    _stateProvinceController,
                    'State/Province',
                    labelFontSize,
                    textFieldFontSize,
                  ),
                  right: _buildLabeledField(
                    'Postal Code',
                    _postalCodeController,
                    'Postal Code',
                    labelFontSize,
                    textFieldFontSize,
                  ),
                ),
                SizedBox(height: 16),
                _buildRow(
                  left: _buildLabeledField(
                    'Country',
                    _countryController,
                    'Country',
                    labelFontSize,
                    textFieldFontSize,
                  ),
                  right: SizedBox.shrink(),
                ),
              ],
              SizedBox(height: 32),

              // Save/Cancel for address
              if (_hasAddressChanges())
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white24),
                          padding: buttonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _resetAddress,
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: buttonPadding,
                        ),
                        onPressed: _saveProfileToServer,
                        child: Text(
                          'Save Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );

    // Emergency Contact Tab
    Widget emergencyContactTab = SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emergency Contact',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 32),

              if (isMobile) ...[
                _buildLabel('Emergency Contact Name', labelFontSize),
                _buildTextField(
                  _emergencyNameController,
                  'Emergency Contact Name',
                  fontSize: textFieldFontSize,
                ),
                SizedBox(height: 16),
                _buildLabel('Emergency Contact Phone', labelFontSize),
                TextField(
                  controller: _emergencyPhoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Emergency Contact Phone',
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black87, width: 1.5),
                    ),
                    errorText: _emergencyPhoneError,
                  ),
                  style: TextStyle(
                    fontSize: textFieldFontSize,
                    color: Colors.black87,
                  ),
                ),
              ] else ...[
                _buildRow(
                  left: _buildLabeledField(
                    'Emergency Contact Name',
                    _emergencyNameController,
                    'Emergency Contact Name',
                    labelFontSize,
                    textFieldFontSize,
                  ),
                  right: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Emergency Contact Phone', labelFontSize),
                      TextField(
                        controller: _emergencyPhoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Emergency Contact Phone',
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.black87,
                              width: 1.5,
                            ),
                          ),
                          errorText: _emergencyPhoneError,
                        ),
                        style: TextStyle(
                          fontSize: textFieldFontSize,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 32),

              // Save/Cancel for emergency
              if (_hasEmergencyContactChanges())
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white24),
                          padding: buttonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _resetEmergency,
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: buttonPadding,
                        ),
                        onPressed: _saveProfileToServer,
                        child: Text(
                          'Save Emergency Contact',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/customer-landing');
          },
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: const [],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(icon: Icon(Icons.person), text: 'Personal Info'),
            Tab(icon: Icon(Icons.location_on), text: 'Address'),
            Tab(icon: Icon(Icons.emergency), text: 'Emergency'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [personalInfoTab, addressTab, emergencyContactTab],
      ),
    );
  }

  Widget _buildLabel(String label, [double fontSize = 15.0]) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _ensureProfileLoaded() async {
    try {
      // Only attempt when customer is logged in
      if (!unifiedAuthState.isCustomerLoggedIn) return;
      final bool hasAnyField =
          (profileNotifier.value.firstName.isNotEmpty) ||
          (profileNotifier.value.lastName.isNotEmpty) ||
          ((profileNotifier.value.email ?? '').isNotEmpty);
      if (hasAnyField) return; // Already populated

      final int? customerId = unifiedAuthState.customerId;
      if (customerId == null) return;

      final res = await AuthService.getProfileData(customerId);
      if (res.success && res.profileData != null) {
        final data = res.profileData!;
        DateTime? birthdateObj;
        final String? birthStr = data['birthdate'];
        if (birthStr != null && birthStr.isNotEmpty) {
          try {
            birthdateObj = DateTime.parse(birthStr);
          } catch (_) {}
        }
        final String? address = data['address'];
        String? street;
        String? city;
        String? stateProvince;
        String? postalCode;
        String? country;
        if (address != null && address.trim().isNotEmpty) {
          final parts = address.split(',').map((e) => e.trim()).toList();
          if (parts.isNotEmpty) street = parts[0];
          if (parts.length > 1) city = parts[1];
          if (parts.length > 2) stateProvince = parts[2];
          if (parts.length > 3) postalCode = parts[3];
          if (parts.length > 4) country = parts[4];
        }
        profileNotifier.value = ProfileData(
          firstName: (data['first_name'] ?? '').toString(),
          middleName: (data['middle_name'] ?? '').toString(),
          lastName: (data['last_name'] ?? '').toString(),
          contactNumber: (data['phone_number'] ?? '').toString(),
          email: (data['email'] ?? '').toString(),
          birthdate: birthdateObj,
          emergencyContactName:
              (data['emergency_contact_name'] ?? '').toString(),
          emergencyContactPhone:
              (data['emergency_contact_number'] ?? '').toString(),
          address: address ?? '',
          street: street,
          city: city,
          stateProvince: stateProvince,
          postalCode: postalCode,
          country: country,
        );
      }
    } catch (_) {}
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText, {
    bool obscureText = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    double fontSize = 16.0,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.black87, width: 1.5),
        ),
        suffixIcon: suffixIcon,
      ),
      style: TextStyle(fontSize: fontSize, color: Colors.black87),
    );
  }

  // Responsive helpers
  Widget _buildRow({required Widget left, required Widget right}) {
    return Row(
      children: [
        Expanded(child: left),
        SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildLabeledField(
    String label,
    TextEditingController controller,
    String hint,
    double labelFontSize,
    double textFieldFontSize, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, labelFontSize),
        _buildTextField(
          controller,
          hint,
          keyboardType: keyboardType,
          fontSize: textFieldFontSize,
        ),
      ],
    );
  }

  Widget _buildDateField(double textFieldFontSize, BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _birthdate != null
                  ? '${_birthdate!.day}/${_birthdate!.month}/${_birthdate!.year}'
                  : 'Select Birthdate',
              style: TextStyle(
                fontSize: textFieldFontSize,
                color: _birthdate != null ? Colors.black87 : Colors.grey[600],
              ),
            ),
            Icon(Icons.calendar_today, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledDate(
    String label,
    double labelFontSize,
    double textFieldFontSize,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, labelFontSize),
        _buildDateField(textFieldFontSize, context),
      ],
    );
  }

  Widget _buildPasswordField(double textFieldFontSize) {
    return _buildTextField(
      _passwordController,
      'Password',
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey[600],
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
      fontSize: textFieldFontSize,
    );
  }

  Widget _buildLabeledPassword(
    String label,
    double labelFontSize,
    double textFieldFontSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, labelFontSize),
        _buildPasswordField(textFieldFontSize),
      ],
    );
  }
}
