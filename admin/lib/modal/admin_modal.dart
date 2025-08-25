import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isPassword,
            readOnly: isReadOnly,
            onTap: onTap,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black.withAlpha((0.3 * 255).toInt()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Colors.lightBlueAccent, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withAlpha((0.18 * 255).toInt()),
                  width: 1.2,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: isReadOnly
                  ? const Icon(Icons.calendar_today,
                      size: 20, color: Colors.white70)
                  : null,
            ),
          ),
        ],
      );
    }

    // Build image upload section
    Widget buildImageUploadSection(StateSetter setModalState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Image:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white24,
              backgroundImage: (kIsWeb && webImageBytes != null)
                  ? MemoryImage(webImageBytes!)
                  : (selectedImage != null)
                      ? FileImage(selectedImage!) as ImageProvider
                      : null,
              child: (kIsWeb && webImageBytes == null && selectedImage == null)
                  ? IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 40,
                      ),
                      onPressed: () => pickImage(setModalState),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => pickImage(setModalState),
              icon: const Icon(Icons.upload, size: 16),
              label: const Text('Upload Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
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
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      // Glassmorphism effect
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width: MediaQuery.of(context).size.width < 600
                              ? MediaQuery.of(context).size.width * 0.99
                              : 600,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.black.withAlpha((0.7 * 255).toInt()),
                            border: Border.all(
                              color:
                                  Colors.white.withAlpha((0.25 * 255).toInt()),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withAlpha(
                                  (0.18 * 255).toInt(),
                                ),
                                blurRadius: 32,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 38,
                              vertical: 36,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.blueAccent.withAlpha(
                                                      (0.25 * 255).toInt(),
                                                    ),
                                                    Colors.lightBlueAccent
                                                        .withAlpha(
                                                      (0.18 * 255).toInt(),
                                                    ),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.admin_panel_settings,
                                                color: Colors.lightBlueAccent,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Flexible(
                                              child: Text(
                                                'Add New Admin',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                  color: Colors.white,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          size: 26,
                                          color: Colors.white,
                                        ),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        tooltip: 'Close',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    child: Divider(
                                      thickness: 1.5,
                                      color: Colors.lightBlueAccent.withAlpha(
                                        (0.22 * 255).toInt(),
                                      ),
                                      height: 24,
                                      endIndent: 12,
                                      indent: 2,
                                    ),
                                  ),
                                  buildImageUploadSection(setModalState),
                                  const SizedBox(height: 24),
                                  buildFormField(
                                      "First Name:", firstNameController),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                      "Middle Name:", middleNameController),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                      "Last Name:", lastNameController),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                      "Date of Birth:", dateOfBirthController,
                                      isReadOnly: true,
                                      onTap: () => pickDate(setModalState)),
                                  const SizedBox(height: 16),
                                  buildFormField("Email:", emailController),
                                  const SizedBox(height: 16),
                                  buildFormField("Contact Number:",
                                      contactNumberController),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                      "Password:", passwordController,
                                      isPassword: true),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red[400],
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                          child: const Text("Cancel"),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // Validate and add new admin
                                            if (validateForm()) {
                                              onAdd({
                                                'firstName':
                                                    firstNameController.text,
                                                'middleName':
                                                    middleNameController.text,
                                                'lastName':
                                                    lastNameController.text,
                                                'dateOfBirth':
                                                    dateOfBirthController.text,
                                                'email': emailController.text,
                                                'contactNumber':
                                                    contactNumberController
                                                        .text,
                                                'password':
                                                    '********', // Store actual hash in real app
                                                'profileImage': kIsWeb
                                                    ? webImageBytes
                                                    : selectedImage,
                                              });
                                              Navigator.of(context).pop();
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                          child: const Text("Submit"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isPassword,
            readOnly: isReadOnly,
            onTap: onTap,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black.withAlpha((0.3 * 255).toInt()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Colors.lightBlueAccent, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withAlpha((0.18 * 255).toInt()),
                  width: 1.2,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: isReadOnly
                  ? const Icon(Icons.calendar_today,
                      size: 20, color: Colors.white70)
                  : null,
            ),
          ),
        ],
      );
    }

    // Build image upload section
    Widget buildImageUploadSection(StateSetter setModalState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Image:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white24,
              backgroundImage: (kIsWeb && webImageBytes != null)
                  ? MemoryImage(webImageBytes!)
                  : (selectedImage != null)
                      ? FileImage(selectedImage!) as ImageProvider
                      : null,
              child: (kIsWeb && webImageBytes == null && selectedImage == null)
                  ? IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 40,
                      ),
                      onPressed: () => pickImage(setModalState),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => pickImage(setModalState),
              icon: const Icon(Icons.upload, size: 16),
              label: const Text('Change Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
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
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      // Glassmorphism effect
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width: MediaQuery.of(context).size.width < 600
                              ? MediaQuery.of(context).size.width * 0.99
                              : 600,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.black.withAlpha((0.7 * 255).toInt()),
                            border: Border.all(
                              color:
                                  Colors.white.withAlpha((0.25 * 255).toInt()),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withAlpha(
                                  (0.18 * 255).toInt(),
                                ),
                                blurRadius: 32,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 38,
                              vertical: 36,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.blueAccent.withAlpha(
                                                      (0.25 * 255).toInt(),
                                                    ),
                                                    Colors.lightBlueAccent
                                                        .withAlpha(
                                                      (0.18 * 255).toInt(),
                                                    ),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.edit,
                                                color: Colors.lightBlueAccent,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Flexible(
                                              child: Text(
                                                'Edit Admin',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                  color: Colors.white,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          size: 26,
                                          color: Colors.white,
                                        ),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        tooltip: 'Close',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    child: Divider(
                                      thickness: 1.5,
                                      color: Colors.lightBlueAccent.withAlpha(
                                        (0.22 * 255).toInt(),
                                      ),
                                      height: 24,
                                      endIndent: 12,
                                      indent: 2,
                                    ),
                                  ),
                                  buildImageUploadSection(setModalState),
                                  const SizedBox(height: 24),
                                  buildFormField(
                                      "First Name:", firstNameController),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                      "Middle Name:", middleNameController),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                      "Last Name:", lastNameController),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                      "Date of Birth:", dateOfBirthController,
                                      isReadOnly: true,
                                      onTap: () => pickDate(setModalState)),
                                  const SizedBox(height: 16),
                                  buildFormField("Email:", emailController),
                                  const SizedBox(height: 16),
                                  buildFormField("Contact Number:",
                                      contactNumberController),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                      "Password:", passwordController,
                                      isPassword: true),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red[400],
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                          child: const Text("Cancel"),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (validateForm()) {
                                              onEdit({
                                                'firstName':
                                                    firstNameController.text,
                                                'middleName':
                                                    middleNameController.text,
                                                'lastName':
                                                    lastNameController.text,
                                                'dateOfBirth':
                                                    dateOfBirthController.text,
                                                'email': emailController.text,
                                                'contactNumber':
                                                    contactNumberController
                                                        .text,
                                                'password':
                                                    (passwordController.text !=
                                                                '********' &&
                                                            passwordController
                                                                .text
                                                                .isNotEmpty)
                                                        ? '********'
                                                        : admin['password'],
                                                'profileImage': webImageBytes ??
                                                    selectedImage ??
                                                    admin['profileImage'],
                                              });
                                              Navigator.of(context).pop();
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                          child: const Text("Save"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
