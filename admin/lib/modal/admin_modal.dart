import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class AdminModal {
  // Show the modal dialog for adding a new admin
  static void showAddAdminModal(
      BuildContext context, Function(Map<String, dynamic>) onAdd) {
    // Controllers for new admin form
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController middleNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController contactNumberController =
        TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController dateOfBirthController = TextEditingController();

    // Image variables
    File? selectedImage;
    Uint8List? webImageBytes;
    DateTime? selectedDate;

    // Function to pick date
    Future<void> pickDate(StateSetter setModalState) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate:
            DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
        firstDate: DateTime(1950),
        lastDate: DateTime.now()
            .subtract(const Duration(days: 6570)), // Must be at least 18
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.blue,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null && picked != selectedDate) {
        setModalState(() {
          selectedDate = picked;
          dateOfBirthController.text =
              "${picked.day}/${picked.month}/${picked.year}";
        });
      }
    }

    // Function to pick image
    Future<void> pickImage(StateSetter setModalState) async {
      if (kIsWeb) {
        // Use file_picker for web
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
        );
        if (result != null && result.files.single.bytes != null) {
          setModalState(() {
            webImageBytes = result.files.single.bytes;
          });
        }
      } else if (Platform.isAndroid || Platform.isIOS) {
        final ImagePicker picker = ImagePicker();
        final XFile? image =
            await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setModalState(() {
            selectedImage = File(image.path);
          });
        }
      } else {
        // Desktop (Windows, macOS, Linux)
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
        );
        if (result != null && result.files.single.path != null) {
          setModalState(() {
            selectedImage = File(result.files.single.path!);
          });
        }
      }
    }

    // Validate the form fields
    bool validateForm() {
      // Basic validation - check for empty fields
      if (firstNameController.text.isEmpty ||
          lastNameController.text.isEmpty ||
          emailController.text.isEmpty ||
          contactNumberController.text.isEmpty ||
          passwordController.text.isEmpty ||
          dateOfBirthController.text.isEmpty) {
        // Show error message or handle validation
        return false;
      }
      return true;
    }

    // Build a form field with label
    Widget buildFormField(String label, TextEditingController controller,
        {bool isPassword = false,
        bool isReadOnly = false,
        VoidCallback? onTap}) {
      return Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              readOnly: isReadOnly,
              onTap: onTap,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: isReadOnly
                    ? const Icon(Icons.calendar_today, size: 20)
                    : null,
              ),
            ),
          ),
        ],
      );
    }

    // Build image upload section
    Widget buildImageUploadSection(StateSetter setModalState) {
      return Row(
        children: [
          const SizedBox(
            height: 180,
            width: 150,
            child: Text(
              'Profile Image:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 180,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (kIsWeb && webImageBytes != null)
                        ? Image.memory(
                            webImageBytes!,
                            fit: BoxFit.cover,
                          )
                        : (selectedImage != null)
                            ? Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => pickImage(setModalState),
                  icon: const Icon(Icons.upload, size: 16),
                  label: const Text('Upload Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Admin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildImageUploadSection(setModalState),
                    const SizedBox(height: 12),
                    buildFormField("First name:", firstNameController),
                    const SizedBox(height: 12),
                    buildFormField("Middle name:", middleNameController),
                    const SizedBox(height: 12),
                    buildFormField("Last name:", lastNameController),
                    const SizedBox(height: 12),
                    buildFormField("Date of Birth:", dateOfBirthController,
                        isReadOnly: true, onTap: () => pickDate(setModalState)),
                    const SizedBox(height: 12),
                    buildFormField("Email:", emailController),
                    const SizedBox(height: 12),
                    buildFormField("Contact Number:", contactNumberController),
                    const SizedBox(height: 12),
                    buildFormField("Password:", passwordController,
                        isPassword: true),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () {
                            // Validate and add new admin
                            if (validateForm()) {
                              onAdd({
                                'firstName': firstNameController.text,
                                'middleName': middleNameController.text,
                                'lastName': lastNameController.text,
                                'dateOfBirth': dateOfBirthController.text,
                                'email': emailController.text,
                                'contactNumber': contactNumberController.text,
                                'password':
                                    '********', // Store actual hash in real app
                                'profileImage':
                                    kIsWeb ? webImageBytes : selectedImage,
                              });
                              Navigator.of(context).pop();
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text("Submit"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Show the modal dialog for editing an admin
  static void showEditAdminModal(BuildContext context,
      Map<String, dynamic> admin, Function(Map<String, dynamic>) onEdit) {
    // Controllers for edit admin form
    final TextEditingController firstNameController =
        TextEditingController(text: admin['firstName']);
    final TextEditingController middleNameController =
        TextEditingController(text: admin['middleName'] ?? '');
    final TextEditingController lastNameController =
        TextEditingController(text: admin['lastName']);
    final TextEditingController emailController =
        TextEditingController(text: admin['email']);
    final TextEditingController contactNumberController =
        TextEditingController(text: admin['contactNumber']);
    final TextEditingController passwordController =
        TextEditingController(text: '********');
    final TextEditingController dateOfBirthController =
        TextEditingController(text: admin['dateOfBirth'] ?? '');

    // Image variables
    File? selectedImage =
        admin['profileImage'] is File ? admin['profileImage'] : null;
    Uint8List? webImageBytes =
        admin['profileImage'] is Uint8List ? admin['profileImage'] : null;
    DateTime? selectedDate;

    // Function to pick date
    Future<void> pickDate(StateSetter setModalState) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate:
            selectedDate ?? DateTime.now().subtract(const Duration(days: 6570)),
        firstDate: DateTime(1950),
        lastDate: DateTime.now().subtract(const Duration(days: 6570)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.blue,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null && picked != selectedDate) {
        setModalState(() {
          selectedDate = picked;
          dateOfBirthController.text =
              "${picked.day}/${picked.month}/${picked.year}";
        });
      }
    }

    // Function to pick image
    Future<void> pickImage(StateSetter setModalState) async {
      if (kIsWeb) {
        // Use file_picker for web
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
        );
        if (result != null && result.files.single.bytes != null) {
          setModalState(() {
            webImageBytes = result.files.single.bytes;
            selectedImage = null; // Clear the other image type
          });
        }
      } else if (Platform.isAndroid || Platform.isIOS) {
        final ImagePicker picker = ImagePicker();
        final XFile? image =
            await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setModalState(() {
            selectedImage = File(image.path);
            webImageBytes = null; // Clear the other image type
          });
        }
      } else {
        // Desktop (Windows, macOS, Linux)
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
        );
        if (result != null && result.files.single.path != null) {
          setModalState(() {
            selectedImage = File(result.files.single.path!);
            webImageBytes = null; // Clear the other image type
          });
        }
      }
    }

    // Validate the form fields
    bool validateForm() {
      if (firstNameController.text.isEmpty ||
          lastNameController.text.isEmpty ||
          emailController.text.isEmpty ||
          contactNumberController.text.isEmpty ||
          dateOfBirthController.text.isEmpty) {
        return false;
      }
      return true;
    }

    Widget buildFormField(String label, TextEditingController controller,
        {bool isPassword = false,
        bool isReadOnly = false,
        VoidCallback? onTap}) {
      return Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              readOnly: isReadOnly,
              onTap: onTap,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: isReadOnly
                    ? const Icon(Icons.calendar_today, size: 20)
                    : null,
              ),
            ),
          ),
        ],
      );
    }

    // Build image upload section
    Widget buildImageUploadSection(StateSetter setModalState) {
      return Row(
        children: [
          const SizedBox(
            width: 150,
            child: Text(
              'Profile Image:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (kIsWeb && webImageBytes != null)
                        ? Image.memory(
                            webImageBytes!,
                            fit: BoxFit.cover,
                          )
                        : (selectedImage != null)
                            ? Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => pickImage(setModalState),
                  icon: const Icon(Icons.upload, size: 16),
                  label: const Text('Change Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Admin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildImageUploadSection(setModalState),
                    const SizedBox(height: 12),
                    buildFormField("First name:", firstNameController),
                    const SizedBox(height: 12),
                    buildFormField("Middle name:", middleNameController),
                    const SizedBox(height: 12),
                    buildFormField("Last name:", lastNameController),
                    const SizedBox(height: 12),
                    buildFormField("Date of Birth:", dateOfBirthController,
                        isReadOnly: true, onTap: () => pickDate(setModalState)),
                    const SizedBox(height: 12),
                    buildFormField("Email:", emailController),
                    const SizedBox(height: 12),
                    buildFormField("Contact Number:", contactNumberController),
                    const SizedBox(height: 12),
                    buildFormField("Password:", passwordController,
                        isPassword: true),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () {
                            if (validateForm()) {
                              onEdit({
                                'firstName': firstNameController.text,
                                'middleName': middleNameController.text,
                                'lastName': lastNameController.text,
                                'dateOfBirth': dateOfBirthController.text,
                                'email': emailController.text,
                                'contactNumber': contactNumberController.text,
                                'password':
                                    (passwordController.text != '********' &&
                                            passwordController.text.isNotEmpty)
                                        ? '********'
                                        : admin['password'],
                                'profileImage': webImageBytes ??
                                    selectedImage ??
                                    admin['profileImage'],
                              });
                              Navigator.of(context).pop();
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text("Save"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
