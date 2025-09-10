import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../services/admin_service.dart';

class AdminModal {
  // Show the modal dialog for adding a new admin
  static void showAddAdminModal(
    BuildContext context,
    Function(Map<String, dynamic>) onAdd,
  ) {
    // Controllers for new admin form
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController middleNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController contactNumberController =
        TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController dateOfBirthController = TextEditingController();

    DateTime? selectedDate;
    bool isLoading = false;

    // Function to pick date
    Future<void> pickDate(StateSetter setModalState) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now().subtract(
          const Duration(days: 6570),
        ), // 18 years ago
        firstDate: DateTime(1950),
        lastDate: DateTime.now().subtract(
          const Duration(days: 6570),
        ), // Must be at least 18
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
              "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        });
      }
    }

    // Validate the form fields
    String? validationError;
    bool validateForm() {
      // Basic validation - check for empty fields
      if (firstNameController.text.trim().isEmpty ||
          lastNameController.text.trim().isEmpty ||
          emailController.text.trim().isEmpty ||
          contactNumberController.text.trim().isEmpty ||
          passwordController.text.isEmpty ||
          dateOfBirthController.text.isEmpty) {
        validationError = 'Please fill all required fields correctly';
        return false;
      }

      // Email validation
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(emailController.text.trim())) {
        validationError = 'Please enter a valid email address';
        return false;
      }

      // Password validation
      if (passwordController.text.length < 6) {
        validationError = 'Password must be at least 6 characters';
        return false;
      }

      // Phone number must be exactly 11 digits (numbers only)
      final String phone = contactNumberController.text.trim();
      if (!RegExp(r'^\d+$').hasMatch(phone)) {
        validationError = 'Contact number must contain digits only';
        return false;
      }
      if (phone.length > 11) {
        validationError =
            'Contact number exceeded (${phone.length}) digits. Use 11 digits only.';
        return false;
      }
      if (phone.length < 11) {
        validationError = 'Contact number must be exactly 11 digits';
        return false;
      }

      return true;
    }

    // Handle admin creation
    Future<void> handleAdminCreation(StateSetter setModalState) async {
      if (!validateForm()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError ?? 'Invalid input'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setModalState(() {
        isLoading = true;
      });

      try {
        // Format date for API (DD/MM/YYYY to YYYY-MM-DD)
        String? formattedDate;
        if (dateOfBirthController.text.isNotEmpty) {
          List<String> dateParts = dateOfBirthController.text.split('/');
          if (dateParts.length == 3) {
            formattedDate =
                '${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}';
          }
        }

        final result = await AdminService.signupAdmin(
          firstName: firstNameController.text.trim(),
          middleName: middleNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
          dateOfBirth: formattedDate,
          phoneNumber: contactNumberController.text.trim(),
        );

        // Use setModalState to safely update UI after async operation
        setModalState(() {
          if (result['success'] == true) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Admin ${firstNameController.text} created successfully!',
                ),
                backgroundColor: Colors.green,
              ),
            );

            // Call the callback with the new admin data
            onAdd(result['admin']);

            // Close the modal
            Navigator.of(context).pop();
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to create admin'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      } catch (e) {
        setModalState(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        });
      } finally {
        setModalState(() {
          isLoading = false;
        });
      }
    }

    // Build a form field with label
    Widget buildFormField(
      String label,
      TextEditingController controller, {
      bool isPassword = false,
      bool isReadOnly = false,
      VoidCallback? onTap,
    }) {
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
            keyboardType:
                identical(controller, contactNumberController)
                    ? TextInputType.number
                    : null,
            inputFormatters:
                identical(controller, contactNumberController)
                    ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ]
                    : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black.withAlpha((0.3 * 255).toInt()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Colors.lightBlueAccent,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withAlpha((0.18 * 255).toInt()),
                  width: 1.2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon:
                  isReadOnly
                      ? const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Colors.white70,
                      )
                      : null,
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
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      // Glassmorphism effect
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width:
                              MediaQuery.of(context).size.width < 600
                                  ? MediaQuery.of(context).size.width * 0.99
                                  : 600,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.black.withAlpha((0.7 * 255).toInt()),
                            border: Border.all(
                              color: Colors.white.withAlpha(
                                (0.25 * 255).toInt(),
                              ),
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
                                        onPressed:
                                            () => Navigator.of(context).pop(),
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
                                  buildFormField(
                                    "First Name:",
                                    firstNameController,
                                  ),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                    "Middle Name:",
                                    middleNameController,
                                  ),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                    "Last Name:",
                                    lastNameController,
                                  ),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                    "Date of Birth:",
                                    dateOfBirthController,
                                    isReadOnly: true,
                                    onTap: () => pickDate(setModalState),
                                  ),
                                  const SizedBox(height: 16),
                                  buildFormField("Email:", emailController),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                    "Contact Number:",
                                    contactNumberController,
                                  ),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                    "Password:",
                                    passwordController,
                                    isPassword: true,
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed:
                                              isLoading
                                                  ? null
                                                  : () {
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
                                              vertical: 12,
                                            ),
                                          ),
                                          child: const Text("Cancel"),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed:
                                              isLoading
                                                  ? null
                                                  : () {
                                                    handleAdminCreation(
                                                      setModalState,
                                                    );
                                                  },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          child:
                                              isLoading
                                                  ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.black),
                                                    ),
                                                  )
                                                  : const Text("Submit"),
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
  static void showEditAdminModal(
    BuildContext context,
    Map<String, dynamic> admin,
    Function(Map<String, dynamic>) onEdit,
  ) {
    // Controllers for edit admin form
    final TextEditingController firstNameController = TextEditingController(
      text: admin['first_name'] ?? admin['firstName'],
    );
    final TextEditingController middleNameController = TextEditingController(
      text: admin['middle_name'] ?? admin['middleName'] ?? '',
    );
    final TextEditingController lastNameController = TextEditingController(
      text: admin['last_name'] ?? admin['lastName'],
    );
    final TextEditingController emailController = TextEditingController(
      text: admin['email_address'] ?? admin['email'],
    );
    final TextEditingController contactNumberController = TextEditingController(
      text: admin['phone_number'] ?? admin['contactNumber'],
    );
    final TextEditingController passwordController = TextEditingController(
      text: '********',
    );
    final TextEditingController dateOfBirthController = TextEditingController(
      text: admin['date_of_birth'] ?? admin['dateOfBirth'] ?? '',
    );

    DateTime? selectedDate;
    bool isLoading = false;

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
              "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        });
      }
    }

    // Validate the form fields
    String? editValidationError;
    bool validateForm() {
      if (firstNameController.text.trim().isEmpty ||
          lastNameController.text.trim().isEmpty ||
          emailController.text.trim().isEmpty ||
          contactNumberController.text.trim().isEmpty ||
          dateOfBirthController.text.isEmpty) {
        editValidationError = 'Please fill all required fields correctly';
        return false;
      }

      // Email validation
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(emailController.text.trim())) {
        editValidationError = 'Please enter a valid email address';
        return false;
      }

      // Phone number must be exactly 11 digits (numbers only)
      final String editPhone = contactNumberController.text.trim();
      if (!RegExp(r'^\d+$').hasMatch(editPhone)) {
        editValidationError = 'Contact number must contain digits only';
        return false;
      }
      if (editPhone.length > 11) {
        editValidationError =
            'Contact number exceeded (${editPhone.length}) digits. Use 11 digits only.';
        return false;
      }
      if (editPhone.length < 11) {
        editValidationError = 'Contact number must be exactly 11 digits';
        return false;
      }

      return true;
    }

    // Handle admin update
    Future<void> handleAdminUpdate(StateSetter setModalState) async {
      if (!validateForm()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(editValidationError ?? 'Invalid input'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setModalState(() {
        isLoading = true;
      });

      try {
        // Convert date format if provided
        String? formattedDate;
        if (dateOfBirthController.text.isNotEmpty) {
          List<String> dateParts = dateOfBirthController.text.split('/');
          if (dateParts.length == 3) {
            formattedDate =
                '${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}';
          }
        }

        // Prepare update data with proper field mapping
        Map<String, dynamic> updateData = {
          'firstName': firstNameController.text.trim(),
          'middleName': middleNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'dateOfBirth': formattedDate,
          'emailAddress': emailController.text.trim(),
          'phoneNumber': contactNumberController.text.trim(),
          'updatedBy': 'system',
          'updatedAt': DateTime.now().toIso8601String(),
        };

        // Handle password update if changed
        if (passwordController.text != '********' &&
            passwordController.text.isNotEmpty) {
          updateData['password'] = passwordController.text;
        }

        final adminId = admin['id'];
        final success = await AdminService.updateAdmin(adminId, updateData);

        // Use setModalState to safely update UI after async operation
        setModalState(() {
          if (success) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Admin ${firstNameController.text} updated successfully!',
                ),
                backgroundColor: Colors.green,
              ),
            );

            // Prepare updated admin data for callback
            Map<String, dynamic> updatedAdmin = Map.from(admin);

            // Map the updated fields back to the expected format
            updatedAdmin['first_name'] = updateData['firstName'];
            updatedAdmin['middle_name'] = updateData['middleName'];
            updatedAdmin['last_name'] = updateData['lastName'];
            updatedAdmin['date_of_birth'] = updateData['dateOfBirth'];
            updatedAdmin['email_address'] = updateData['emailAddress'];
            updatedAdmin['phone_number'] = updateData['phoneNumber'];

            // Call the callback with the updated admin data
            onEdit(updatedAdmin);

            // Close the modal
            Navigator.of(context).pop();
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update admin'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      } catch (e) {
        setModalState(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        });
      } finally {
        setModalState(() {
          isLoading = false;
        });
      }
    }

    Widget buildFormField(
      String label,
      TextEditingController controller, {
      bool isPassword = false,
      bool isReadOnly = false,
      VoidCallback? onTap,
    }) {
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
                borderSide: const BorderSide(
                  color: Colors.lightBlueAccent,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withAlpha((0.18 * 255).toInt()),
                  width: 1.2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon:
                  isReadOnly
                      ? const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Colors.white70,
                      )
                      : null,
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
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      // Glassmorphism effect
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width:
                              MediaQuery.of(context).size.width < 600
                                  ? MediaQuery.of(context).size.width * 0.99
                                  : 600,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.black.withAlpha((0.7 * 255).toInt()),
                            border: Border.all(
                              color: Colors.white.withAlpha(
                                (0.25 * 255).toInt(),
                              ),
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
                                        onPressed:
                                            () => Navigator.of(context).pop(),
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
                                  buildFormField(
                                    "First Name:",
                                    firstNameController,
                                  ),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                    "Middle Name:",
                                    middleNameController,
                                  ),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                    "Last Name:",
                                    lastNameController,
                                  ),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                    "Date of Birth:",
                                    dateOfBirthController,
                                    isReadOnly: true,
                                    onTap: () => pickDate(setModalState),
                                  ),
                                  const SizedBox(height: 16),
                                  buildFormField("Email:", emailController),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                    "Contact Number:",
                                    contactNumberController,
                                  ),
                                  const SizedBox(height: 16),
                                  buildFormField(
                                    "Password:",
                                    passwordController,
                                    isPassword: true,
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed:
                                              isLoading
                                                  ? null
                                                  : () {
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
                                              vertical: 12,
                                            ),
                                          ),
                                          child: const Text("Cancel"),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed:
                                              isLoading
                                                  ? null
                                                  : () {
                                                    handleAdminUpdate(
                                                      setModalState,
                                                    );
                                                  },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          child:
                                              isLoading
                                                  ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.black),
                                                    ),
                                                  )
                                                  : const Text("Save"),
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
