import 'package:flutter/material.dart';

class AdminModal {
  // Show the modal dialog for adding a new admin
  static void showAddAdminModal(
      BuildContext context, Function(Map<String, dynamic>) onAdd) {
    // Controllers for new admin form
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController contactNumberController =
        TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    // Validate the form fields
    bool validateForm() {
      // Basic validation - check for empty fields
      if (firstNameController.text.isEmpty ||
          lastNameController.text.isEmpty ||
          emailController.text.isEmpty ||
          contactNumberController.text.isEmpty ||
          passwordController.text.isEmpty) {
        // Show error message or handle validation
        return false;
      }
      return true;
    }

    // Build a form field with label
    Widget buildFormField(String label, TextEditingController controller,
        {bool isPassword = false}) {
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
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildFormField("First name:", firstNameController),
                const SizedBox(height: 16),
                buildFormField("Last name:", lastNameController),
                const SizedBox(height: 16),
                buildFormField("Email:", emailController),
                const SizedBox(height: 16),
                buildFormField("Contact Number:", contactNumberController),
                const SizedBox(height: 16),
                buildFormField("Password:", passwordController,
                    isPassword: true),
                const SizedBox(height: 24),
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
                            'lastName': lastNameController.text,
                            'email': emailController.text,
                            'contactNumber': contactNumberController.text,
                            'password':
                                '********', // Store actual hash in real app
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
  }
}
