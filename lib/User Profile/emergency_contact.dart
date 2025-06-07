import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> _pickEmergencyImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _emergencyImageFile = null;
        });
      } else {
        setState(() {
          _emergencyImageFile = File(pickedFile.path);
          _webImageBytes = null;
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
            onTap: _pickEmergencyImage,
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
              child:
                  (kIsWeb
                          ? _webImageBytes == null
                          : _emergencyImageFile == null)
                      ? Icon(
                        Icons.camera_alt,
                        size: 32,
                        color: Colors.grey[700],
                      )
                      : null,
            ),
          ),
        ),
        SizedBox(height: 24),
        TextField(
          controller: _emergencyNameController,
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
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Save emergency contact information
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Emergency contact information saved!')),
              );
            },
            child: Text('Save Emergency Contact'),
          ),
        ),
      ],
    );
  }
}
