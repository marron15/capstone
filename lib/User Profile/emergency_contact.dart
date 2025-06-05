import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'profile_data.dart';

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
    setState(() {
      _emergencyImageFile =
          pickedFile != null ? File(pickedFile.path) : _emergencyImageFile;
    });
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Contact',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
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
                  _emergencyImageFile != null
                      ? FileImage(_emergencyImageFile!)
                      : (_webImageBytes != null
                          ? MemoryImage(_webImageBytes!)
                          : null),
              child:
                  _emergencyImageFile == null
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
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),
        TextField(
          controller: _emergencyPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Emergency Contact Number',
            border: OutlineInputBorder(),
          ),
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
