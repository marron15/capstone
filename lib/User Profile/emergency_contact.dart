import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'profile_data.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb

class EmergencyContactWidget extends StatefulWidget {
  @override
  _EmergencyContactWidgetState createState() => _EmergencyContactWidgetState();
}

class _EmergencyContactWidgetState extends State<EmergencyContactWidget> {
  File? _emergencyImageFile;
  Uint8List? _webImageBytes;
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers and image from profileNotifier
    _emergencyNameController.text =
        profileNotifier.value.emergencyContactName ?? '';
    _emergencyPhoneController.text =
        profileNotifier.value.emergencyContactPhone ?? '';
    _emergencyImageFile = profileNotifier.value.imageFile;
    _webImageBytes = profileNotifier.value.webImageBytes;
  }

  Future<void> _pickEmergencyImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        // For web, get bytes
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _emergencyImageFile = null; // Ensure file is null for web
        });
      } else {
        // For mobile, get File
        setState(() {
          _emergencyImageFile = File(pickedFile.path);
          _webImageBytes = null; // Ensure bytes are null for mobile
        });
      }
    }
  }

  @override
  void dispose() {
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(
          100,
        ), // Darker, slightly transparent background
        borderRadius: BorderRadius.circular(14), // More rounded corners
        border: Border.all(color: Colors.white10, width: 1), // Subtle border
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ), // Adjusted shadow
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Contact',
            style: TextStyle(
              fontSize: 20, // Adjusted font size
              fontWeight: FontWeight.bold,
              color: Colors.white, // Changed text color to white
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: _pickEmergencyImage,
              child: CircleAvatar(
                radius: 150,
                backgroundColor: Colors.white12, // Subtle background
                backgroundImage:
                    _emergencyImageFile != null
                        ? FileImage(_emergencyImageFile!)
                        : (_webImageBytes != null
                            ? MemoryImage(_webImageBytes!)
                            : null),
                child:
                    (_emergencyImageFile == null && _webImageBytes == null)
                        ? Icon(
                          Icons.camera_alt,
                          size: 32,
                          color: Colors.white70, // Lighter icon color
                        )
                        : null,
              ),
            ),
          ),
          SizedBox(height: 24),
          TextField(
            controller: _emergencyNameController,
            style: TextStyle(color: Colors.white), // Lighter input text
            decoration: InputDecoration(
              labelText: 'Emergency Contact Name',
              labelStyle: TextStyle(
                color: Colors.white70,
              ), // Lighter label text
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
                borderSide: BorderSide(color: Colors.white30), // Lighter border
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
                borderSide: BorderSide(color: Colors.white30), // Lighter border
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
                borderSide: BorderSide(
                  color: Colors.lightBlueAccent,
                  width: 2,
                ), // Accent focused border
              ),
              filled: true,
              fillColor: Colors.white.withAlpha(20), // Subtle white fill
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _emergencyPhoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: Colors.white), // Lighter input text
            decoration: InputDecoration(
              labelText: 'Emergency Contact Number',
              labelStyle: TextStyle(
                color: Colors.white70,
              ), // Lighter label text
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
                borderSide: BorderSide(color: Colors.white30), // Lighter border
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
                borderSide: BorderSide(color: Colors.white30), // Lighter border
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
                borderSide: BorderSide(
                  color: Colors.lightBlueAccent,
                  width: 2,
                ), // Accent focused border
              ),
              filled: true,
              fillColor: Colors.white.withAlpha(20), // Subtle white fill
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Save emergency contact information
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Emergency contact information saved!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // White background
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14), // Rounded corners
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Save Emergency Contact',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black, // Black text
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
