import 'package:flutter/material.dart';

import 'profile_data.dart';

import '../landing_page_components/landing_page.dart';
import 'membership_duration.dart';

import '../services/auth_service.dart';
import '../services/auth_state.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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

    _firstNameController.addListener(_firstNameListener);
    _middleNameController.addListener(_middleNameListener);
    _lastNameController.addListener(_lastNameListener);
    _contactController.addListener(_contactListener);
    _emailController.addListener(_emailListener);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.removeListener(_firstNameListener);
    _middleNameController.removeListener(_middleNameListener);
    _lastNameController.removeListener(_lastNameListener);
    _contactController.removeListener(_contactListener);
    _emailController.removeListener(_emailListener);
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

  bool _hasChanges() {
    return _firstNameController.text != profileNotifier.value.firstName ||
        _middleNameController.text != profileNotifier.value.middleName ||
        _lastNameController.text != profileNotifier.value.lastName ||
        _contactController.text != profileNotifier.value.contactNumber ||
        _emailController.text != (profileNotifier.value.email ?? '') ||
        _birthdate != profileNotifier.value.birthdate ||
        _addressController.text != (profileNotifier.value.address ?? '') ||
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
    return _addressController.text != (profileNotifier.value.address ?? '') ||
        _streetController.text != (profileNotifier.value.street ?? '') ||
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
        'emergency_contact_phone': _emergencyPhoneController.text.trim(),
        'address': _addressController.text.trim(),
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'state_province': _stateProvinceController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'country': _countryController.text.trim(),
      };

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
          address: _addressController.text.trim(),
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          stateProvince: _stateProvinceController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: _countryController.text.trim(),
          emergencyContactName: _emergencyNameController.text.trim(),
          emergencyContactPhone: _emergencyPhoneController.text.trim(),
        );

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

  Future<void> _handleLogout() async {
    try {
      // Clear auth and local profile state
      await authState.logout();
      profileNotifier.value = ProfileData();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LandingPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during logout: $e'),
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
    if (!authState.isLoggedIn) {
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LandingPage()),
                  );
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
              _buildTextField(
                _contactController,
                'Contact Number',
                keyboardType: TextInputType.phone,
                fontSize: textFieldFontSize,
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
              GestureDetector(
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
                          color:
                              _birthdate != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                        ),
                      ),
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              _buildLabel('Password', labelFontSize),
              _buildTextField(
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
              ),
              SizedBox(height: 32),

              // Save Button
              if (_hasChanges())
                SizedBox(
                  width: double.infinity,
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

              _buildLabel('Address', labelFontSize),
              _buildTextField(
                _addressController,
                'Address',
                fontSize: textFieldFontSize,
              ),
              SizedBox(height: 16),

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
              SizedBox(height: 32),

              // Save Address Button
              if (_hasAddressChanges())
                SizedBox(
                  width: double.infinity,
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

              _buildLabel('Emergency Contact Name', labelFontSize),
              _buildTextField(
                _emergencyNameController,
                'Emergency Contact Name',
                fontSize: textFieldFontSize,
              ),
              SizedBox(height: 16),

              _buildLabel('Emergency Contact Phone', labelFontSize),
              _buildTextField(
                _emergencyPhoneController,
                'Emergency Contact Phone',
                keyboardType: TextInputType.phone,
                fontSize: textFieldFontSize,
              ),
              SizedBox(height: 32),

              // Save Emergency Contact Button
              if (_hasEmergencyContactChanges())
                SizedBox(
                  width: double.infinity,
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
