import 'package:flutter/material.dart';

import 'dart:io';
import 'profile_data.dart';

import '../landing_page_components/landing_page.dart';
import 'membership_duration.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/auth_state.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
  DateTime? _birthdate;
  TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Controllers for address fields
  late TextEditingController _addressController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateProvinceController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;

  // Controllers for emergency contact
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;

  @override
  void initState() {
    super.initState();
    _birthdate = profileNotifier.value.birthdate;
    // Don't populate password field for security - it will be empty initially
    _passwordController.text = '';

    // Initialize address controllers
    _addressController = TextEditingController(
      text: profileNotifier.value.address ?? '',
    );
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
    _contactListener = () => setState(() {});
    _emailListener = () => setState(() {});

    // Load fresh profile data from server
    _loadProfileData();
    _firstNameController.addListener(_firstNameListener);
    _middleNameController.addListener(_middleNameListener);
    _lastNameController.addListener(_lastNameListener);
    _contactController.addListener(_contactListener);
    _emailController.addListener(_emailListener);
    // Add listeners for address controllers
    _addressController.addListener(() => setState(() {}));
    _streetController.addListener(() => setState(() {}));
    _cityController.addListener(() => setState(() {}));
    _stateProvinceController.addListener(() => setState(() {}));
    _postalCodeController.addListener(() => setState(() {}));
    _countryController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_firstNameListener);
    _middleNameController.removeListener(_middleNameListener);
    _lastNameController.removeListener(_lastNameListener);
    _contactController.removeListener(_contactListener);
    _emailController.removeListener(_emailListener);
    // Remove listeners for address controllers
    _addressController.removeListener(() => setState(() {}));
    _streetController.removeListener(() => setState(() {}));
    _cityController.removeListener(() => setState(() {}));
    _stateProvinceController.removeListener(() => setState(() {}));
    _postalCodeController.removeListener(() => setState(() {}));
    _countryController.removeListener(() => setState(() {}));
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();

    _passwordController.dispose();
    // Dispose of address controllers
    _addressController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateProvinceController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    // Dispose of emergency contact controllers
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  // Load fresh profile data from server
  Future<void> _loadProfileData() async {
    try {
      // Get customer ID from auth state
      final customerId = authState.customerId;
      if (customerId == null) return;

      final result = await AuthService.getProfileData(customerId);
      if (result.success && result.profileData != null) {
        final data = result.profileData!;

        // Update profile notifier with fresh data
        profileNotifier.value = ProfileData(
          firstName: data['first_name'] ?? '',
          middleName: data['middle_name'] ?? '',
          lastName: data['last_name'] ?? '',
          contactNumber: data['phone_number'] ?? '',
          email: data['email'] ?? '',
          birthdate:
              data['birthdate'] != null
                  ? DateTime.tryParse(data['birthdate'])
                  : null,
          emergencyContactName: data['emergency_contact_name'],
          emergencyContactPhone: data['emergency_contact_number'],
          address: data['address'] ?? '',
          street: data['address_details']?['street'] ?? '',
          city: data['address_details']?['city'] ?? '',
          stateProvince: data['address_details']?['state'] ?? '',
          postalCode: data['address_details']?['postal_code'] ?? '',
          country: data['address_details']?['country'] ?? '',
        );

        // Update controllers with fresh data
        setState(() {
          _firstNameController.text = data['first_name'] ?? '';
          _middleNameController.text = data['middle_name'] ?? '';
          _lastNameController.text = data['last_name'] ?? '';
          _contactController.text = data['phone_number'] ?? '';
          _emailController.text = data['email'] ?? '';
          if (data['birthdate'] != null) {
            _birthdate = DateTime.tryParse(data['birthdate']);
          }
          _addressController.text = data['address'] ?? '';
          _streetController.text = data['address_details']?['street'] ?? '';
          _cityController.text = data['address_details']?['city'] ?? '';
          _stateProvinceController.text =
              data['address_details']?['state'] ?? '';
          _postalCodeController.text =
              data['address_details']?['postal_code'] ?? '';
          _countryController.text = data['address_details']?['country'] ?? '';
          _emergencyNameController.text = data['emergency_contact_name'] ?? '';
          _emergencyPhoneController.text =
              data['emergency_contact_number'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
    }
  }

  bool _hasChanges() {
    return _firstNameController.text != profileNotifier.value.firstName ||
        _middleNameController.text != profileNotifier.value.middleName ||
        _lastNameController.text != profileNotifier.value.lastName ||
        _contactController.text != profileNotifier.value.contactNumber ||
        _emailController.text != (profileNotifier.value.email ?? '') ||
        _birthdate != profileNotifier.value.birthdate ||
        _passwordController.text.isNotEmpty; // Include password changes
  }

  // Add this method to check if address fields have changed
  bool _hasAddressChanges() {
    return _addressController.text != (profileNotifier.value.address ?? '') ||
        _streetController.text != (profileNotifier.value.street ?? '') ||
        _cityController.text != (profileNotifier.value.city ?? '') ||
        _stateProvinceController.text !=
            (profileNotifier.value.stateProvince ?? '') ||
        _postalCodeController.text !=
            (profileNotifier.value.postalCode ?? '') ||
        _countryController.text != (profileNotifier.value.country ?? '');
  }

  // Check if emergency contact fields have changed (for desktop view)
  bool _hasEmergencyContactChanges() {
    return _emergencyNameController.text !=
            (profileNotifier.value.emergencyContactName ?? '') ||
        _emergencyPhoneController.text !=
            (profileNotifier.value.emergencyContactPhone ?? '');
  }

  // Save profile changes to server
  Future<void> _saveProfileToServer() async {
    try {
      final customerId = authState.customerId;
      if (customerId == null) return;

      // Prepare profile data for update
      final profileData = {
        'customer_id': customerId,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'middle_name': _middleNameController.text.trim(),
        'email': _emailController.text.trim(),
        'birthdate': _birthdate?.toIso8601String(),
        'phone_number': _contactController.text.trim(),
        'emergency_contact_name': _emergencyNameController.text.trim(),
        'emergency_contact_number': _emergencyPhoneController.text.trim(),
        'address_details': {
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateProvinceController.text.trim(),
          'postal_code': _postalCodeController.text.trim(),
          'country': _countryController.text.trim(),
        },
      };

      // Add password if changed
      if (_passwordController.text.isNotEmpty) {
        profileData['password'] = _passwordController.text;
      }

      final result = await AuthService.updateProfile(profileData);
      if (result.success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Clear password field after successful update
        _passwordController.clear();

        // Reload profile data to get fresh data
        await _loadProfileData();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final bool shouldLogout =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Logout'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldLogout) return;

    try {
      // Call logout API (optional - mainly for logging purposes)
      final result = await AuthService.logout();

      // Clear auth state and local profile data
      await authState.logout();
      profileNotifier.value = ProfileData();

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? 'Logged out successfully!'
                  : 'Logged out locally',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to landing page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LandingPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Even if API call fails, clear auth state and local data and navigate
      await authState.logout();
      profileNotifier.value = ProfileData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out locally'),
            backgroundColor: Colors.orange,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LandingPage()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  Future<void> _pickBirthdate() async {
    DateTime initialDate = _birthdate ?? DateTime(2000, 1, 1);
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _birthdate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isWide = width >= 900;
    final cardMaxWidth = isMobile ? double.infinity : (isWide ? 1200.0 : 700.0);
    final horizontalPadding = isMobile ? 0.0 : 32.0;
    final cardPadding =
        isMobile
            ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 18.0)
            : const EdgeInsets.symmetric(horizontal: 32.0, vertical: 36.0);
    final titleFontSize = isMobile ? 26.0 : 36.0;
    final sectionTitleFontSize = isMobile ? 15.0 : 18.0;
    final buttonPadding =
        isMobile
            ? EdgeInsets.symmetric(vertical: 14)
            : EdgeInsets.symmetric(vertical: 18);
    final avatarRadius = isMobile ? 38.0 : 48.0;
    final iconSize = isMobile ? 28.0 : 36.0;
    final labelFontSize = isMobile ? 13.0 : 15.0;
    final textFieldFontSize = isMobile ? 14.0 : 16.0;

    final List<Widget> leftColumnFields = [
      // Main Profile Information Section Header
      Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.lightBlueAccent.withAlpha((0.1 * 255).toInt()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.lightBlueAccent.withAlpha((0.3 * 255).toInt()),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.person, color: Colors.lightBlueAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.lightBlueAccent,
              ),
            ),
          ],
        ),
      ),
      _buildLabel('First Name', labelFontSize),
      _buildTextField(
        _firstNameController,
        'First Name',
        fontSize: textFieldFontSize,
      ),
      SizedBox(height: 18),
      _buildLabel('Middle Name', labelFontSize),
      _buildTextField(
        _middleNameController,
        'Middle Name',
        fontSize: textFieldFontSize,
      ),
      SizedBox(height: 18),
      _buildLabel('Last Name', labelFontSize),
      _buildTextField(
        _lastNameController,
        'Last Name',
        fontSize: textFieldFontSize,
      ),
      SizedBox(height: 18),
      _buildLabel('Contact Number', labelFontSize),
      _buildTextField(
        _contactController,
        'Contact Number',
        keyboardType: TextInputType.phone,
        fontSize: textFieldFontSize,
      ),
      SizedBox(height: 18),
      _buildLabel('Email', labelFontSize),
      _buildTextField(
        _emailController,
        'Email',
        keyboardType: TextInputType.emailAddress,
        fontSize: textFieldFontSize,
      ),
      SizedBox(height: 18),
      _buildLabel('Birthdate', labelFontSize),
      GestureDetector(
        onTap: _pickBirthdate,
        child: AbsorbPointer(
          child: _buildTextField(
            TextEditingController(
              text:
                  _birthdate != null
                      ? "${_birthdate!.year}-${_birthdate!.month.toString().padLeft(2, '0')}-${_birthdate!.day.toString().padLeft(2, '0')}"
                      : '',
            ),
            'Birthdate',
            suffixIcon: Icon(Icons.calendar_today),
            fontSize: textFieldFontSize,
          ),
        ),
      ),
      SizedBox(height: 18),
      _buildLabel('New Password (leave blank to keep current)', labelFontSize),
      TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: TextStyle(fontSize: textFieldFontSize, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Enter new password to change',
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.black87, width: 1.5),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
      ),
      SizedBox(height: 24),
      // Main Profile Save/Cancel Section
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.1 * 255).toInt()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withAlpha((0.2 * 255).toInt()),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.save, color: Colors.lightBlueAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Save Profile Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.lightBlueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: buttonPadding,
                    ),
                    onPressed: () {
                      setState(() {
                        _firstNameController.text =
                            profileNotifier.value.firstName;
                        _middleNameController.text =
                            profileNotifier.value.middleName;
                        _lastNameController.text =
                            profileNotifier.value.lastName;
                        _contactController.text =
                            profileNotifier.value.contactNumber;
                        _emailController.text =
                            profileNotifier.value.email ?? '';
                        _birthdate = profileNotifier.value.birthdate;

                        _passwordController.text = '';
                        _emergencyNameController.text =
                            profileNotifier.value.emergencyContactName ?? '';
                        _emergencyPhoneController.text =
                            profileNotifier.value.emergencyContactPhone ?? '';
                      });
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: buttonPadding,
                    ),
                    onPressed: _hasChanges() ? _saveProfileToServer : null,
                    child: Text(
                      'Save Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (!_hasChanges()) ...[
              const SizedBox(height: 8),
              Text(
                'No changes to save',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    ];

    final List<Widget> rightColumnFields = [
      _buildLabel('Address Information', sectionTitleFontSize),
      SizedBox(height: 8),
      _buildLabel('Street', labelFontSize),
      _buildTextField(_streetController, 'Street', fontSize: textFieldFontSize),
      SizedBox(height: 14),
      _buildLabel('City', labelFontSize),
      _buildTextField(_cityController, 'City', fontSize: textFieldFontSize),
      SizedBox(height: 14),
      _buildLabel('State / Province', labelFontSize),
      _buildTextField(
        _stateProvinceController,
        'State / Province',
        fontSize: textFieldFontSize,
      ),
      SizedBox(height: 14),
      _buildLabel('Postal Code', labelFontSize),
      _buildTextField(
        _postalCodeController,
        'Postal Code',
        fontSize: textFieldFontSize,
      ),
      SizedBox(height: 14),
      _buildLabel('Country', labelFontSize),
      _buildTextField(
        _countryController,
        'Country',
        fontSize: textFieldFontSize,
      ),
      SizedBox(height: 24),
    ];

    Widget wideHeader = Column(
      children: [
        Center(
          child: Text(
            'Profile',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 8),
        SizedBox(height: 24),

        SizedBox(height: 32),
      ],
    );

    Widget wideEmergencyContact = Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Contact',
            style: TextStyle(
              fontSize: sectionTitleFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          _buildLabel('Emergency Contact Name', labelFontSize),
          _buildTextField(
            _emergencyNameController,
            'Emergency Contact Name',
            fontSize: textFieldFontSize,
          ),
          SizedBox(height: 14),
          _buildLabel('Emergency Contact Phone', labelFontSize),
          _buildTextField(
            _emergencyPhoneController,
            'Emergency Contact Phone',
            keyboardType: TextInputType.phone,
            fontSize: textFieldFontSize,
          ),
          SizedBox(height: 18),
          if (_hasEmergencyContactChanges())
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: buttonPadding,
                    ),
                    onPressed: () {
                      setState(() {
                        _emergencyNameController.text =
                            profileNotifier.value.emergencyContactName ?? '';
                        _emergencyPhoneController.text =
                            profileNotifier.value.emergencyContactPhone ?? '';
                      });
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: buttonPadding,
                    ),
                    onPressed: () {
                      profileNotifier.value = ProfileData(
                        imageFile: profileNotifier.value.imageFile,
                        webImageBytes: profileNotifier.value.webImageBytes,
                        firstName: profileNotifier.value.firstName,
                        middleName: profileNotifier.value.middleName,
                        lastName: profileNotifier.value.lastName,
                        contactNumber: profileNotifier.value.contactNumber,
                        email: profileNotifier.value.email,
                        birthdate: profileNotifier.value.birthdate,
                        password: profileNotifier.value.password,
                        address: profileNotifier.value.address,
                        street: profileNotifier.value.street,
                        city: profileNotifier.value.city,
                        stateProvince: profileNotifier.value.stateProvince,
                        postalCode: profileNotifier.value.postalCode,
                        country: profileNotifier.value.country,
                        emergencyContactName: _emergencyNameController.text,
                        emergencyContactPhone: _emergencyPhoneController.text,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Emergency contact information saved!'),
                        ),
                      );
                      setState(() {});
                    },
                    child: Text(
                      'Save',
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
    );

    Widget wideFormRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 3,
          child: Container(
            constraints: BoxConstraints(minWidth: 320, maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: leftColumnFields,
            ),
          ),
        ),
        Container(
          width: 1,
          height: 600,
          color: Colors.grey[300],
          margin: EdgeInsets.symmetric(horizontal: 24),
        ),
        Flexible(
          flex: 3,
          child: Container(
            constraints: BoxConstraints(minWidth: 320, maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...rightColumnFields,
                if (_hasAddressChanges())
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: buttonPadding,
                          ),
                          onPressed: () {
                            setState(() {
                              _addressController.text =
                                  profileNotifier.value.address ?? '';
                              _streetController.text =
                                  profileNotifier.value.street ?? '';
                              _cityController.text =
                                  profileNotifier.value.city ?? '';
                              _stateProvinceController.text =
                                  profileNotifier.value.stateProvince ?? '';
                              _postalCodeController.text =
                                  profileNotifier.value.postalCode ?? '';
                              _countryController.text =
                                  profileNotifier.value.country ?? '';
                            });
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: buttonPadding,
                          ),
                          onPressed: () async {
                            await _saveProfileToServer();
                          },
                          child: Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
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
        SizedBox(width: 24),
        Flexible(
          flex: 3,
          child: Container(
            constraints: BoxConstraints(minWidth: 320, maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: wideEmergencyContact,
              ),
            ),
          ),
        ),
      ],
    );

    Widget wideWidgetsRow = Column(
      children: [
        SizedBox(height: 32),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [],
          ),
        ),
      ],
    );

    // Emergency contact widget for mobile layout
    Widget mobileEmergencyContact = Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Contact',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          _buildLabel('Emergency Contact Name', 16),
          _buildTextField(
            _emergencyNameController,
            'Emergency Contact Name',
            fontSize: 16,
          ),
          SizedBox(height: 14),
          _buildLabel('Emergency Contact Phone', 16),
          _buildTextField(
            _emergencyPhoneController,
            'Emergency Contact Phone',
            keyboardType: TextInputType.phone,
            fontSize: 16,
          ),
          SizedBox(height: 18),
          if (_hasEmergencyContactChanges())
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      setState(() {
                        _emergencyNameController.text =
                            profileNotifier.value.emergencyContactName ?? '';
                        _emergencyPhoneController.text =
                            profileNotifier.value.emergencyContactPhone ?? '';
                      });
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      profileNotifier.value = ProfileData(
                        imageFile: profileNotifier.value.imageFile,
                        webImageBytes: profileNotifier.value.webImageBytes,
                        firstName: profileNotifier.value.firstName,
                        middleName: profileNotifier.value.middleName,
                        lastName: profileNotifier.value.lastName,
                        contactNumber: profileNotifier.value.contactNumber,
                        email: profileNotifier.value.email,
                        birthdate: profileNotifier.value.birthdate,
                        password: profileNotifier.value.password,
                        address: profileNotifier.value.address,
                        street: profileNotifier.value.street,
                        city: profileNotifier.value.city,
                        stateProvince: profileNotifier.value.stateProvince,
                        postalCode: profileNotifier.value.postalCode,
                        country: profileNotifier.value.country,
                        emergencyContactName:
                            _emergencyNameController.text.trim().isEmpty
                                ? null
                                : _emergencyNameController.text.trim(),
                        emergencyContactPhone:
                            _emergencyPhoneController.text.trim().isEmpty
                                ? null
                                : _emergencyPhoneController.text.trim(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Emergency contact information saved!'),
                        ),
                      );
                      setState(() {});
                    },
                    child: Text(
                      'Save Emergency Contact',
                      style: TextStyle(
                        fontSize: 16,
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
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/gym_view/BACK VIEW OF GYM.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(
                (0.7 * 255).toInt(),
              ), // dark overlay for readability
            ),
          ),
          SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                constraints: BoxConstraints(maxWidth: cardMaxWidth),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 32,
                ),
                child: Padding(
                  padding: cardPadding,
                  child:
                      isWide
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              wideHeader,
                              wideFormRow,
                              wideWidgetsRow,
                              // wideEmergencyContact already included in wideFormRow
                            ],
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  'Profile',
                                  style: TextStyle(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              SizedBox(height: 24),

                              SizedBox(height: 32),
                              ...leftColumnFields,
                              SizedBox(height: isMobile ? 18 : 32),
                              Divider(
                                height: 1,
                                color: Colors.lightBlueAccent.withAlpha(
                                  (0.22 * 255).toInt(),
                                ),
                              ),
                              SizedBox(height: isMobile ? 12 : 24),
                              ...rightColumnFields,
                              if (_hasAddressChanges())
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[300],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: buttonPadding,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _addressController.text =
                                                profileNotifier.value.address ??
                                                '';
                                            _streetController.text =
                                                profileNotifier.value.street ??
                                                '';
                                            _cityController.text =
                                                profileNotifier.value.city ??
                                                '';
                                            _stateProvinceController.text =
                                                profileNotifier
                                                    .value
                                                    .stateProvince ??
                                                '';
                                            _postalCodeController.text =
                                                profileNotifier
                                                    .value
                                                    .postalCode ??
                                                '';
                                            _countryController.text =
                                                profileNotifier.value.country ??
                                                '';
                                          });
                                        },
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: buttonPadding,
                                        ),
                                        onPressed: () async {
                                          await _saveProfileToServer();
                                        },
                                        child: Text(
                                          'Save',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                              mobileEmergencyContact,
                            ],
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LandingPage()),
            );
          },
        ),
        title: membershipExpirationText(
          profileNotifier.value.membershipExpiration,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
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
}
