import 'package:flutter/material.dart';
import 'package:capstone/PH phone number valid/phone_formatter.dart';
import 'package:capstone/PH phone number valid/phone_validator.dart';
import 'dart:ui';

class TrainerModal {
  static InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.black.withAlpha((0.3 * 255).toInt()),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.lightBlueAccent, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withAlpha((0.18 * 255).toInt()),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  static void showAddTrainerModal(
    BuildContext context,
    Function(Map<String, String>) onAdd,
  ) {
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController middleNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController contactNumberController =
        TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          alignment: Alignment.center,
          insetPadding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Align(
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: 680,
                      constraints: const BoxConstraints(maxWidth: 720),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: Colors.black.withAlpha((0.7 * 255).toInt()),
                        border: Border.all(
                          color: Colors.white.withAlpha((0.25 * 255).toInt()),
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
                          horizontal: 28,
                          vertical: 24,
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                                          Colors.lightBlueAccent.withAlpha(
                                            (0.18 * 255).toInt(),
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person_add,
                                      color: Colors.lightBlueAccent,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Add Trainer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    icon: const Icon(
                                      Icons.close,
                                      size: 26,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Divider(
                                thickness: 1.5,
                                color: Colors.lightBlueAccent.withAlpha(
                                  (0.22 * 255).toInt(),
                                ),
                                height: 24,
                                endIndent: 12,
                                indent: 2,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: firstNameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('First Name'),
                                validator:
                                    (value) =>
                                        value == null || value.isEmpty
                                            ? 'Please enter first name'
                                            : null,
                              ),
                              const SizedBox(height: 16),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final bool isWide =
                                      constraints.maxWidth > 520;
                                  final double fieldWidth =
                                      isWide
                                          ? (constraints.maxWidth - 16) / 2
                                          : constraints.maxWidth;
                                  Widget sized(Widget child) =>
                                      SizedBox(width: fieldWidth, child: child);
                                  return Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: [
                                      sized(
                                        TextFormField(
                                          controller: middleNameController,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          decoration: _inputDecoration(
                                            'Middle Name (optional)',
                                          ),
                                        ),
                                      ),
                                      sized(
                                        TextFormField(
                                          controller: lastNameController,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          decoration: _inputDecoration(
                                            'Last Name',
                                          ),
                                          validator:
                                              (value) =>
                                                  value == null || value.isEmpty
                                                      ? 'Please enter last name'
                                                      : null,
                                        ),
                                      ),
                                      sized(
                                        TextFormField(
                                          controller: contactNumberController,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          decoration: _inputDecoration(
                                            'Contact Number',
                                          ),
                                          inputFormatters: [
                                            PhoneFormatter.phoneNumberFormatter,
                                          ],
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            final String v =
                                                (value ?? '').trim();
                                            if (v.isEmpty) {
                                              return 'Please enter contact number';
                                            }
                                            return PhoneValidator.isValidPhilippineMobile(
                                                  v,
                                                )
                                                ? null
                                                : 'Enter a valid PH mobile number';
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (formKey.currentState!.validate()) {
                                        onAdd({
                                          'firstName': firstNameController.text,
                                          'middleName':
                                              middleNameController.text,
                                          'lastName': lastNameController.text,
                                          'contactNumber':
                                              PhoneFormatter.cleanPhoneNumber(
                                                contactNumberController.text,
                                              ),
                                        });
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.lightBlueAccent,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Submit'),
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
  }

  static void showEditTrainerModal(
    BuildContext context,
    Map<String, String> trainer,
    Function(Map<String, String>) onEdit,
  ) {
    final TextEditingController firstNameController = TextEditingController(
      text: trainer['firstName'],
    );
    final TextEditingController middleNameController = TextEditingController(
      text: trainer['middleName'],
    );
    final TextEditingController lastNameController = TextEditingController(
      text: trainer['lastName'],
    );
    final TextEditingController contactNumberController = TextEditingController(
      text: PhoneFormatter.formatWithSpaces(trainer['contactNumber'] ?? ''),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          alignment: Alignment.center,
          insetPadding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Align(
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: 680,
                      constraints: const BoxConstraints(maxWidth: 720),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: Colors.black.withAlpha((0.7 * 255).toInt()),
                        border: Border.all(
                          color: Colors.white.withAlpha((0.25 * 255).toInt()),
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
                          horizontal: 28,
                          vertical: 24,
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                                          Colors.lightBlueAccent.withAlpha(
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
                                  const Text(
                                    'Edit Trainer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    icon: const Icon(
                                      Icons.close,
                                      size: 26,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Divider(
                                thickness: 1.5,
                                color: Colors.lightBlueAccent.withAlpha(
                                  (0.22 * 255).toInt(),
                                ),
                                height: 24,
                                endIndent: 12,
                                indent: 2,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: firstNameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('First Name'),
                                validator:
                                    (value) =>
                                        value == null || value.isEmpty
                                            ? 'Please enter first name'
                                            : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: middleNameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  'Middle Name (optional)',
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: lastNameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('Last Name'),
                                validator:
                                    (value) =>
                                        value == null || value.isEmpty
                                            ? 'Please enter last name'
                                            : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: contactNumberController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('Contact Number'),
                                inputFormatters: [
                                  PhoneFormatter.phoneNumberFormatter,
                                ],
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  final String v = (value ?? '').trim();
                                  if (v.isEmpty) {
                                    return 'Please enter contact number';
                                  }
                                  return PhoneValidator.isValidPhilippineMobile(
                                        v,
                                      )
                                      ? null
                                      : 'Enter a valid PH mobile number';
                                },
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (formKey.currentState!.validate()) {
                                        onEdit({
                                          'id': trainer['id'] ?? '',
                                          'firstName': firstNameController.text,
                                          'middleName':
                                              middleNameController.text,
                                          'lastName': lastNameController.text,
                                          'contactNumber':
                                              PhoneFormatter.cleanPhoneNumber(
                                                contactNumberController.text,
                                              ),
                                        });
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.lightBlueAccent,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Save'),
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
  }
}
