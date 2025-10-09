import 'package:flutter/material.dart';
// import removed: image picking disabled in read-only mode
import 'dart:io';
import 'profile_data.dart';
import 'package:flutter/foundation.dart';

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

  // Picking image disabled in read-only mode

  @override
  void dispose() {
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Emergency Contact',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: null,
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  kIsWeb
                      ? (_webImageBytes != null
                          ? MemoryImage(_webImageBytes!)
                          : null)
                      : (_emergencyImageFile != null
                          ? FileImage(_emergencyImageFile!)
                          : null),
              child: null,
            ),
          ),
        ),
        SizedBox(height: 24),
        TextField(
          controller: _emergencyNameController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Emergency Contact Name',
            labelStyle: TextStyle(color: Colors.white),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2),
            ),
            hintStyle: TextStyle(color: Colors.white54),
            fillColor: Colors.white10,
            filled: true,
          ),
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(height: 20),
        TextField(
          controller: _emergencyPhoneController,
          readOnly: true,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Emergency Contact Number',
            labelStyle: TextStyle(color: Colors.white),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2),
            ),
            hintStyle: TextStyle(color: Colors.white54),
            fillColor: Colors.white10,
            filled: true,
          ),
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(height: 20),
        // Button removed for read-only mode
      ],
    );
  }
}
