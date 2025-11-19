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
  bool _isDarkMode = true;

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
  // Password listener removed
  String? _contactError;
  String? _emergencyPhoneError;
  String? _emailError;
  bool _isSavingPersonal = false;
  bool _isSavingEmergency = false;

  DateTime? _birthdate;
  // Password field removed; no controller needed
  // Password visibility state unused in read-only mode

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
    // Password field removed

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
    _emailListener = () {
      _validateEmailInline();
      setState(() {});
    };

    _firstNameController.addListener(_firstNameListener);
    _middleNameController.addListener(_middleNameListener);
    _lastNameController.addListener(_lastNameListener);
    _contactController.addListener(_contactListener);
    _emailController.addListener(_emailListener);
    // Password field removed
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
    _validateContactInline();
    _validateEmailInline();
    _validateEmergencyPhoneInline();

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
    // Password field removed
    profileNotifier.removeListener(_profileListener);
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();

    // Password field removed
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

  // Editing disabled: change tracking and reset methods removed

  String _digitsOnly(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int codeUnit in input.codeUnits) {
      if (codeUnit >= 48 && codeUnit <= 57) {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  void _validateContactInline() {
    final String v = _contactController.text.trim();
    final String digits = _digitsOnly(v);
    if (digits.isEmpty) {
      _contactError = 'Contact number is required';
      return;
    }
    // Enforce length and digits only
    if (digits.length != 11) {
      _contactError = 'Contact number must be exactly 11 digits';
    } else {
      _contactError = null;
    }
  }

  void _validateEmailInline() {
    final String value = _emailController.text.trim();
    if (value.isEmpty) {
      _emailError = null;
      return;
    }
    if (_isValidEmail(value)) {
      _emailError = null;
    } else {
      _emailError = 'Please enter a valid email address';
    }
  }

  bool _isValidEmail(String value) {
    final RegExp pattern = RegExp(
      r'^[\w\.\-+]+@([\w-]+\.)+[a-zA-Z]{2,}$',
      caseSensitive: false,
    );
    return pattern.hasMatch(value);
  }

  void _validateEmergencyPhoneInline() {
    final String raw = _emergencyPhoneController.text.trim();
    if (raw.isEmpty) {
      _emergencyPhoneError = null;
      return;
    }
    final String digits = _digitsOnly(raw);
    if (digits.length != 11) {
      _emergencyPhoneError = 'Contact number must be exactly 11 digits';
    } else {
      _emergencyPhoneError = null;
    }
    setState(() {});
  }

  // Editing disabled: reset emergency removed

  // Editing disabled: saving to server removed

  // Date selection disabled in read-only mode

  @override
  Widget build(BuildContext context) {
    final Color bgColor = _isDarkMode ? Colors.black : Colors.white;
    final Color titleColor = _isDarkMode ? Colors.white : Colors.black87;
    final Color appBarBg = bgColor;
    final Color appBarIcon = titleColor;
    // If user is logged out, prevent showing stale data
    if (!unifiedAuthState.isCustomerLoggedIn) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: appBarBg,
          elevation: 0,
          iconTheme: IconThemeData(color: appBarIcon),
          title: Text('Profile', style: TextStyle(color: titleColor)),
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
    // Buttons removed; no button padding required

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
                  color: titleColor,
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
                  readOnly: true,
                ),
                SizedBox(height: 16),

                _buildLabel('Middle Name', labelFontSize),
                _buildTextField(
                  _middleNameController,
                  'Middle Name',
                  fontSize: textFieldFontSize,
                  readOnly: true,
                ),
                SizedBox(height: 16),

                _buildLabel('Last Name', labelFontSize),
                _buildTextField(
                  _lastNameController,
                  'Last Name',
                  fontSize: textFieldFontSize,
                  readOnly: true,
                ),
                SizedBox(height: 16),

                _buildLabel('Contact Number', labelFontSize),
                _buildPhoneInput(
                  controller: _contactController,
                  hintText: 'Contact Number',
                  fontSize: textFieldFontSize,
                  enabled: !_isSavingPersonal,
                  errorText: _contactError,
                ),
                SizedBox(height: 16),

                _buildLabel('Email', labelFontSize),
                _buildTextField(
                  _emailController,
                  'Email',
                  keyboardType: TextInputType.emailAddress,
                  fontSize: textFieldFontSize,
                  readOnly: false,
                  enabled: !_isSavingPersonal,
                  enableInteractiveSelection: true,
                  errorText: _emailError,
                ),
                SizedBox(height: 16),

                _buildLabel('Birthdate', labelFontSize),
                _buildDateField(textFieldFontSize, context),
                SizedBox(height: 16),

                // Password field removed
              ] else ...[
                _buildRow(
                  left: _buildLabeledField(
                    'First Name',
                    _firstNameController,
                    'First Name',
                    labelFontSize,
                    textFieldFontSize,
                    keyboardType: TextInputType.text,
                  ),
                  right: _buildLabeledField(
                    'Middle Name',
                    _middleNameController,
                    'Middle Name',
                    labelFontSize,
                    textFieldFontSize,
                    keyboardType: TextInputType.text,
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
                    keyboardType: TextInputType.text,
                  ),
                  right: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Contact Number', labelFontSize),
                      _buildPhoneInput(
                        controller: _contactController,
                        hintText: 'Contact Number',
                        fontSize: textFieldFontSize,
                        enabled: !_isSavingPersonal,
                        errorText: _contactError,
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
                    readOnly: false,
                    enabled: !_isSavingPersonal,
                    enableInteractiveSelection: true,
                    errorText: _emailError,
                  ),
                  right: _buildLabeledDate(
                    'Birthdate',
                    labelFontSize,
                    textFieldFontSize,
                    context,
                  ),
                ),
                SizedBox(height: 16),
                // Password field removed
              ],
              SizedBox(height: 32),

              _buildActionButtons(
                hasChanges: _hasPersonalChanges,
                isSaving: _isSavingPersonal,
                canSave: _canSavePersonal,
                onCancel: _resetPersonalFields,
                onSave: _savePersonalInfo,
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
                  color: titleColor,
                ),
              ),
              SizedBox(height: 32),

              if (isMobile) ...[
                _buildLabel('Street', labelFontSize),
                _buildTextField(
                  _streetController,
                  'Street',
                  fontSize: textFieldFontSize,
                  readOnly: true,
                ),
                SizedBox(height: 16),
                _buildLabel('City', labelFontSize),
                _buildTextField(
                  _cityController,
                  'City',
                  fontSize: textFieldFontSize,
                  readOnly: true,
                ),
                SizedBox(height: 16),
                _buildLabel('State/Province', labelFontSize),
                _buildTextField(
                  _stateProvinceController,
                  'State/Province',
                  fontSize: textFieldFontSize,
                  readOnly: true,
                ),
                SizedBox(height: 16),
                _buildLabel('Postal Code', labelFontSize),
                _buildTextField(
                  _postalCodeController,
                  'Postal Code',
                  fontSize: textFieldFontSize,
                  readOnly: true,
                ),
                SizedBox(height: 16),
                _buildLabel('Country', labelFontSize),
                _buildTextField(
                  _countryController,
                  'Country',
                  fontSize: textFieldFontSize,
                  readOnly: true,
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

              // Buttons removed for read-only mode
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
                  color: titleColor,
                ),
              ),
              SizedBox(height: 32),

              if (isMobile) ...[
                _buildLabel('Emergency Contact Name', labelFontSize),
                _buildTextField(
                  _emergencyNameController,
                  'Emergency Contact Name',
                  fontSize: textFieldFontSize,
                  readOnly: false,
                  enabled: !_isSavingEmergency,
                  enableInteractiveSelection: true,
                ),
                SizedBox(height: 16),
                _buildLabel('Emergency Contact Phone', labelFontSize),
                _buildPhoneInput(
                  controller: _emergencyPhoneController,
                  hintText: 'Emergency Contact Phone',
                  fontSize: textFieldFontSize,
                  enabled: !_isSavingEmergency,
                  errorText: _emergencyPhoneError,
                ),
              ] else ...[
                _buildRow(
                  left: _buildLabeledField(
                    'Emergency Contact Name',
                    _emergencyNameController,
                    'Emergency Contact Name',
                    labelFontSize,
                    textFieldFontSize,
                    readOnly: false,
                    enabled: !_isSavingEmergency,
                    enableInteractiveSelection: true,
                  ),
                  right: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Emergency Contact Phone', labelFontSize),
                      _buildPhoneInput(
                        controller: _emergencyPhoneController,
                        hintText: 'Emergency Contact Phone',
                        fontSize: textFieldFontSize,
                        enabled: !_isSavingEmergency,
                        errorText: _emergencyPhoneError,
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 32),

              _buildActionButtons(
                hasChanges: _hasEmergencyChanges,
                isSaving: _isSavingEmergency,
                canSave: _canSaveEmergency,
                onCancel: _resetEmergencyFields,
                onSave: _saveEmergencyContact,
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.home, color: appBarIcon),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/customer-landing');
          },
        ),
        title: Text('Profile', style: TextStyle(color: titleColor)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _isDarkMode ? 'Light mode' : 'Dark mode',
            icon: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: appBarIcon,
            ),
            onPressed: () {
              setState(() => _isDarkMode = !_isDarkMode);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: titleColor,
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
          color: _isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  bool get _hasPersonalChanges {
    final profile = profileNotifier.value;
    final String contactInput = _digitsOnly(_contactController.text.trim());
    final String storedContact = _digitsOnly(profile.contactNumber);
    final String emailInput = _emailController.text.trim();
    return contactInput != storedContact || emailInput != (profile.email ?? '');
  }

  bool get _hasEmergencyChanges {
    final profile = profileNotifier.value;
    final String nameInput = _emergencyNameController.text.trim();
    final String phoneInput = _digitsOnly(
      _emergencyPhoneController.text.trim(),
    );
    final String storedPhone = _digitsOnly(profile.emergencyContactPhone ?? '');
    return nameInput != (profile.emergencyContactName ?? '') ||
        phoneInput != storedPhone;
  }

  bool get _canSavePersonal {
    if (_isSavingPersonal || !_hasPersonalChanges) return false;
    final String contactInput = _digitsOnly(_contactController.text.trim());
    if (contactInput.length != 11) return false;
    if (_emailError != null) return false;
    return true;
  }

  bool get _canSaveEmergency {
    if (_isSavingEmergency || !_hasEmergencyChanges) return false;
    final String phoneInput = _digitsOnly(
      _emergencyPhoneController.text.trim(),
    );
    if (phoneInput.length != 11) return false;
    if (_emergencyNameController.text.trim().isEmpty) return false;
    if (_emergencyPhoneError != null) return false;
    return true;
  }

  void _resetPersonalFields() {
    final profile = profileNotifier.value;
    _contactController.text = profile.contactNumber;
    _emailController.text = profile.email ?? '';
    _validateContactInline();
    _validateEmailInline();
    setState(() {});
  }

  void _resetEmergencyFields() {
    final profile = profileNotifier.value;
    _emergencyNameController.text = profile.emergencyContactName ?? '';
    _emergencyPhoneController.text = profile.emergencyContactPhone ?? '';
    _validateEmergencyPhoneInline();
  }

  Future<void> _savePersonalInfo() async {
    if (!_canSavePersonal) return;
    final int? customerId = unifiedAuthState.customerId;
    if (customerId == null) {
      _showSnack(
        'Unable to update profile: missing customer ID',
        isError: true,
      );
      return;
    }

    final String contact = _digitsOnly(_contactController.text.trim());
    final String email = _emailController.text.trim();

    setState(() => _isSavingPersonal = true);
    final Map<String, dynamic> payload = {
      'customer_id': customerId,
      'phone_number': contact,
      'email': email,
    }..removeWhere(
      (key, value) =>
          value == null || (value is String && value.trim().isEmpty),
    );

    final result = await AuthService.updateProfile(payload);
    if (!mounted) return;
    setState(() => _isSavingPersonal = false);

    if (result.success) {
      final String updatedEmail =
          email.isEmpty ? (profileNotifier.value.email ?? '') : email;
      _patchProfileData(contactNumber: contact, email: updatedEmail);
      _showSnack('Personal information updated');
    } else {
      _showSnack(result.message, isError: true);
    }
  }

  Future<void> _saveEmergencyContact() async {
    if (!_canSaveEmergency) return;
    final int? customerId = unifiedAuthState.customerId;
    if (customerId == null) {
      _showSnack(
        'Unable to update profile: missing customer ID',
        isError: true,
      );
      return;
    }

    final String contactName = _emergencyNameController.text.trim();
    final String contactPhone = _digitsOnly(
      _emergencyPhoneController.text.trim(),
    );

    setState(() => _isSavingEmergency = true);
    final Map<String, dynamic> payload = {
      'customer_id': customerId,
      'emergency_contact_name': contactName,
      'emergency_contact_number': contactPhone,
    };

    final result = await AuthService.updateProfile(payload);
    if (!mounted) return;
    setState(() => _isSavingEmergency = false);

    if (result.success) {
      _patchProfileData(
        emergencyContactName: contactName,
        emergencyContactPhone: contactPhone,
      );
      _showSnack('Emergency contact updated');
    } else {
      _showSnack(result.message, isError: true);
    }
  }

  void _patchProfileData({
    String? contactNumber,
    String? email,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    final current = profileNotifier.value;
    profileNotifier.value = ProfileData(
      imageFile: current.imageFile,
      webImageBytes: current.webImageBytes,
      firstName: current.firstName,
      middleName: current.middleName,
      lastName: current.lastName,
      contactNumber: contactNumber ?? current.contactNumber,
      email: email ?? current.email,
      birthdate: current.birthdate,
      emergencyContactName:
          emergencyContactName ?? current.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? current.emergencyContactPhone,
      password: current.password,
      address: current.address,
      street: current.street,
      city: current.city,
      stateProvince: current.stateProvince,
      postalCode: current.postalCode,
      country: current.country,
      membershipExpiration: current.membershipExpiration,
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
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
    bool readOnly = true,
    bool enabled = false,
    bool enableInteractiveSelection = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    double fontSize = 16.0,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      enableInteractiveSelection: enableInteractiveSelection,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: (!enabled || readOnly) ? Colors.grey[100] : Colors.grey[50],
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
        errorText: errorText,
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
    bool readOnly = true,
    bool enabled = false,
    bool enableInteractiveSelection = false,
    String? errorText,
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
          readOnly: readOnly,
          enabled: enabled,
          enableInteractiveSelection: enableInteractiveSelection,
          errorText: errorText,
        ),
      ],
    );
  }

  Widget _buildDateField(double textFieldFontSize, BuildContext context) {
    return GestureDetector(
      onTap: null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _birthdate != null
                  ? '${_birthdate!.day}/${_birthdate!.month}/${_birthdate!.year}'
                  : 'Birthdate',
              style: TextStyle(
                fontSize: textFieldFontSize,
                color: Colors.black54,
              ),
            ),
            Icon(Icons.calendar_today, color: Colors.grey[400]),
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

  Widget _buildPhoneInput({
    required TextEditingController controller,
    required String hintText,
    required double fontSize,
    required bool enabled,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      readOnly: false,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.black87, width: 1.5),
        ),
        errorText: errorText,
      ),
      style: TextStyle(fontSize: fontSize, color: Colors.black87),
    );
  }

  Widget _buildActionButtons({
    required bool hasChanges,
    required bool isSaving,
    required bool canSave,
    required VoidCallback onCancel,
    required Future<void> Function() onSave,
  }) {
    return Row(
      children: [
        OutlinedButton(
          onPressed: (!hasChanges || isSaving) ? null : onCancel,
          child: const Text('Cancel'),
        ),
        SizedBox(width: 12),
        ElevatedButton(
          onPressed: canSave ? () => onSave() : null,
          child:
              isSaving
                  ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Text('Save Changes'),
        ),
      ],
    );
  }

  // Password UI removed
}
