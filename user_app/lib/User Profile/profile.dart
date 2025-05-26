import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'profile_data.dart';
import 'note.dart';
import 'transaction.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  final TextEditingController _noteController = TextEditingController();
  late VoidCallback _nameListener;
  late VoidCallback _contactListener;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: profileNotifier.value.name);
    _contactController = TextEditingController(
      text: profileNotifier.value.contactNumber,
    );
    _imageFile = profileNotifier.value.imageFile;
    _nameListener = () => setState(() {});
    _contactListener = () => setState(() {});
    _nameController.addListener(_nameListener);
    _contactController.addListener(_contactListener);
  }

  @override
  void dispose() {
    _nameController.removeListener(_nameListener);
    _contactController.removeListener(_contactListener);
    _nameController.dispose();
    _contactController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool _hasChanges() {
    return _imageFile != profileNotifier.value.imageFile ||
        _nameController.text != profileNotifier.value.name ||
        _contactController.text != profileNotifier.value.contactNumber;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile != null ? File(pickedFile.path) : _imageFile;
    });
  }

  void _saveProfile() {
    FocusScope.of(context).unfocus();
    profileNotifier.value = ProfileData(
      imageFile: _imageFile,
      name: _nameController.text,
      contactNumber: _contactController.text,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Profile saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        _imageFile != null ? FileImage(_imageFile!) : null,
                    child:
                        _imageFile == null
                            ? Icon(
                              Icons.camera_alt,
                              size: 48,
                              color: Colors.grey[700],
                            )
                            : null,
                  ),
                ),
              ),
              SizedBox(height: 44),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 28),
              TextField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Membership Expiration: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '--:--:--',
                    style: TextStyle(
                      fontSize: 18,
                      letterSpacing: 2,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasChanges() ? _saveProfile : null,
                  child: Text('Save'),
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
            ],
          ),
        ),
      ),
    );
  }
}
