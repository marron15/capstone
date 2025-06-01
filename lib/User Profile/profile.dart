import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'profile_data.dart';
import 'note.dart';
import 'transaction.dart';
import 'emergency_contact.dart';
import '../landing_page_components/landing_page.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'dart:typed_data'; // Import for Uint8List

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
  final TextEditingController _noteController = TextEditingController();
  late VoidCallback _firstNameListener;
  late VoidCallback _middleNameListener;
  late VoidCallback _lastNameListener;
  late VoidCallback _contactListener;
  late VoidCallback _emailListener;
  File? _imageFile;
  Uint8List? _webImageBytes; // Variable to store image bytes for web
  DateTime? _birthdate;
  TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _passwordError;

  // Controllers for address fields
  late TextEditingController _addressController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateProvinceController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;

  // Helper function for InputDecoration styling
  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70), // Lighter label text
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white54), // Lighter hint text
      prefixIcon:
          icon != null
              ? Icon(icon, color: Colors.white70)
              : null, // Lighter icon color
      filled: true,
      fillColor: Colors.white.withAlpha(30), // Subtle white fill for contrast
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), // More rounded corners
        borderSide: BorderSide(color: Colors.white54), // Lighter border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), // More rounded corners
        borderSide: BorderSide(color: Colors.white54), // Lighter border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), // More rounded corners
        borderSide: const BorderSide(
          color: Colors.lightBlueAccent,
          width: 2,
        ), // Accent focused border
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  void initState() {
    super.initState();
    _birthdate = profileNotifier.value.birthdate;
    _imageFile = profileNotifier.value.imageFile;
    _webImageBytes = profileNotifier.value.webImageBytes;
    _passwordController.text = profileNotifier.value.password ?? '';

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
    _noteController.dispose();
    _passwordController.dispose();
    // Dispose of address controllers
    _addressController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateProvinceController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  bool _hasChanges() {
    return (_imageFile != null && profileNotifier.value.imageFile == null) ||
        (_imageFile == null && profileNotifier.value.imageFile != null) ||
        (_imageFile != null &&
            profileNotifier.value.imageFile != null &&
            _imageFile!.path != profileNotifier.value.imageFile!.path) ||
        (_webImageBytes != null &&
            profileNotifier.value.webImageBytes == null) ||
        (_webImageBytes == null &&
            profileNotifier.value.webImageBytes != null) ||
        (_webImageBytes != null &&
            profileNotifier.value.webImageBytes != null &&
            !listEquals(
              _webImageBytes!,
              profileNotifier.value.webImageBytes!,
            )) ||
        _firstNameController.text != profileNotifier.value.firstName ||
        _middleNameController.text != profileNotifier.value.middleName ||
        _lastNameController.text != profileNotifier.value.lastName ||
        _contactController.text != profileNotifier.value.contactNumber ||
        _emailController.text != (profileNotifier.value.email ?? '') ||
        _birthdate != profileNotifier.value.birthdate ||
        _passwordController.text != (profileNotifier.value.password ?? '') ||
        _addressController.text != (profileNotifier.value.address ?? '') ||
        _streetController.text != (profileNotifier.value.street ?? '') ||
        _cityController.text != (profileNotifier.value.city ?? '') ||
        _stateProvinceController.text !=
            (profileNotifier.value.stateProvince ?? '') ||
        _postalCodeController.text !=
            (profileNotifier.value.postalCode ?? '') ||
        _countryController.text != (profileNotifier.value.country ?? '');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        // For web, get bytes
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _imageFile = null; // Ensure file is null for web
          print(
            'Profile (Web): _webImageBytes updated. Length: ${_webImageBytes?.length}',
          );
          print('Profile (Web): _imageFile: $_imageFile');
        });
      } else {
        // For mobile, get File
        setState(() {
          _imageFile = File(pickedFile.path);
          _webImageBytes = null; // Ensure bytes are null for mobile
          print(
            'Profile (Mobile): _imageFile updated. Path: ${_imageFile?.path}',
          );
          print('Profile (Mobile): _webImageBytes: $_webImageBytes');
        });
      }
    }
  }

  void _saveProfile() {
    FocusScope.of(context).unfocus();
    setState(() {
      _passwordError = null;
    });
    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text != profileNotifier.value.password) {
        setState(() {
          _passwordError = 'Password does not match';
        });
        return;
      }
    }
    profileNotifier.value = ProfileData(
      imageFile: _imageFile,
      firstName: _firstNameController.text,
      middleName: _middleNameController.text,
      lastName: _lastNameController.text,
      contactNumber: _contactController.text,
      email: _emailController.text,
      birthdate: _birthdate,
      password: _passwordController.text,
      address: _addressController.text,
      street: _streetController.text,
      city: _cityController.text,
      stateProvince: _stateProvinceController.text,
      postalCode: _postalCodeController.text,
      country: _countryController.text,
      webImageBytes: _webImageBytes,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Profile saved!')));
  }

  Future<void> _pickBirthdate() async {
    DateTime initialDate = _birthdate ?? DateTime(2000, 1, 1);
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LandingPage()),
            );
          },
        ),
        title: Center(
          child: Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withAlpha(
                  (255 * 0.9).round(),
                ), // Replaced withOpacity
                Colors.black.withAlpha(
                  (255 * 0.6).round(),
                ), // Replaced withOpacity
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/gym_view/BACK VIEW OF GYM.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withAlpha((255 * 0.8).round())),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 600.0,
                vertical: 32.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 150,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_webImageBytes != null
                                    ? MemoryImage(_webImageBytes!)
                                    : null),
                        child:
                            _imageFile == null && _webImageBytes == null
                                ? Icon(
                                  Icons.camera_alt,
                                  size: 48,
                                  color: Colors.white70,
                                )
                                : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 44),
                  TextField(
                    controller: _firstNameController,
                    decoration: _inputDecoration(
                      label: 'First Name',
                      icon: Icons.person_outline,
                    ),
                    style: TextStyle(color: Colors.white), // Lighter input text
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _middleNameController,
                    decoration: _inputDecoration(
                      label: 'Middle Name',
                      icon: Icons.person_outline,
                    ),
                    style: TextStyle(color: Colors.white), // Lighter input text
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _lastNameController,
                    decoration: _inputDecoration(
                      label: 'Last Name',
                      icon: Icons.person_outline,
                    ),
                    style: TextStyle(color: Colors.white), // Lighter input text
                  ),
                  SizedBox(height: 28),
                  TextField(
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(
                      label: 'Contact Number',
                      icon: Icons.phone_outlined,
                    ),
                    style: TextStyle(color: Colors.white), // Lighter input text
                  ),
                  SizedBox(height: 28),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      label: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    style: TextStyle(color: Colors.white), // Lighter input text
                  ),

                  SizedBox(height: 28),
                  GestureDetector(
                    onTap: _pickBirthdate,
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: _inputDecoration(
                          label: 'Birthdate',
                          icon: Icons.calendar_today,
                          suffixIcon: Icon(
                            Icons.calendar_today,
                            color: Colors.white70,
                          ), // Lighter icon color
                        ),
                        style: TextStyle(
                          color: Colors.white,
                        ), // Lighter input text
                        controller: TextEditingController(
                          text:
                              _birthdate != null
                                  ? "	${_birthdate!.year}-${_birthdate!.month.toString().padLeft(2, '0')}-${_birthdate!.day.toString().padLeft(2, '0')}"
                                  : '',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 28),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration(
                      label: 'Password',
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70, // Lighter icon color
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    style: TextStyle(color: Colors.white), // Lighter input text
                    readOnly: true,
                  ),
                  SizedBox(height: 40),

                  // Address Information Section (Moved)
                  Text(
                    'Address Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Changed text color to white
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _addressController,
                    decoration: _inputDecoration(
                      label: 'Address',
                      icon: Icons.location_on_outlined,
                    ),
                    style: TextStyle(color: Colors.white), // Lighter input text
                    readOnly: true,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _streetController,
                    decoration: _inputDecoration(
                      label: 'Street',
                      icon: Icons.streetview,
                    ),
                    style: TextStyle(color: Colors.white), // Lighter input text
                    readOnly: true,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _cityController,
                    decoration: _inputDecoration(
                      label: 'City',
                      icon: Icons.location_city_outlined,
                    ),
                    style: TextStyle(color: Colors.white), // Lighter input text
                    readOnly: true,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _stateProvinceController,
                    decoration: _inputDecoration(
                      label: 'State / Province',
                      icon: Icons.location_city,
                    ),
                    style: TextStyle(color: Colors.white), // Lighter input text
                    readOnly: true,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _postalCodeController,
                    decoration: _inputDecoration(
                      label: 'Postal Code',
                      icon: Icons.markunread_mailbox_outlined,
                    ),
                    style: TextStyle(color: Colors.white), // Lighter input text
                    readOnly: true,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _countryController,
                    decoration: _inputDecoration(
                      label: 'Country',
                      icon: Icons.public_outlined,
                    ),
                    style: TextStyle(color: Colors.white), // Lighter input text
                    readOnly: true,
                  ),

                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Membership Expiration: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70, // Lighter text color
                        ),
                      ),
                      Text(
                        '--:--:--',
                        style: TextStyle(
                          fontSize: 18,
                          letterSpacing: 2,
                          color:
                              Colors
                                  .redAccent, // Keep accent color for expiration
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ), // Increased padding
                        backgroundColor: Colors.white, // White background
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            14,
                          ), // Rounded corners
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18, // Increased font size
                          fontWeight: FontWeight.bold, // Bold text
                        ),
                      ),
                      onPressed: _saveProfile,
                      child: Text(
                        'Save',
                        style: TextStyle(color: Colors.black),
                      ), // Black text
                    ),
                  ),
                  SizedBox(height: 48),
                  NoteWidget(
                    controller: _noteController,
                    onSave: () {
                      // TODO: Send _noteController.text to backend here
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Note saved!')));
                    },
                  ),
                  SizedBox(height: 44),
                  TransactionProofWidget(),
                  SizedBox(height: 44),
                  EmergencyContactWidget(),
                  SizedBox(height: 44),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
