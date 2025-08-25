import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

class CustomerViewEditModal {
  // Show the modal dialog for viewing and editing a customer
  static Future<bool> showCustomerModal(
      BuildContext context, Map<String, dynamic> customer) async {
    // Debug: Log customer data
    debugPrint('Customer data passed to modal: $customer');

    // Controllers for customer form
    final TextEditingController firstNameController =
        TextEditingController(text: customer['first_name'] ?? '');
    final TextEditingController middleNameController =
        TextEditingController(text: customer['middle_name'] ?? '');
    final TextEditingController lastNameController =
        TextEditingController(text: customer['last_name'] ?? '');
    final TextEditingController emailController =
        TextEditingController(text: customer['email'] ?? '');
    final TextEditingController contactController =
        TextEditingController(text: customer['phone_number'] ?? '');
    final TextEditingController birthdateController =
        TextEditingController(text: customer['birthdate'] ?? '');
    final TextEditingController emergencyNameController =
        TextEditingController(text: customer['emergency_contact_name'] ?? '');
    final TextEditingController emergencyPhoneController =
        TextEditingController(text: customer['emergency_contact_number'] ?? '');

    // Handle address fields with fallbacks
    final TextEditingController streetController = TextEditingController(
        text: customer['address_details']?['street'] ??
            (customer['address'] != null
                ? customer['address'].toString().split(',')[0].trim()
                : ''));
    final TextEditingController cityController = TextEditingController(
        text: customer['address_details']?['city'] ??
            (customer['address'] != null &&
                    customer['address'].toString().split(',').length > 1
                ? customer['address'].toString().split(',')[1].trim()
                : ''));
    final TextEditingController stateController = TextEditingController(
        text: customer['address_details']?['state'] ??
            (customer['address'] != null &&
                    customer['address'].toString().split(',').length > 2
                ? customer['address'].toString().split(',')[2].trim()
                : ''));
    final TextEditingController postalCodeController = TextEditingController(
        text: customer['address_details']?['postal_code'] ??
            (customer['address'] != null &&
                    customer['address'].toString().split(',').length > 3
                ? customer['address'].toString().split(',')[3].trim()
                : ''));
    final TextEditingController countryController = TextEditingController(
        text: customer['address_details']?['country'] ??
            (customer['address'] != null &&
                    customer['address'].toString().split(',').length > 4
                ? customer['address'].toString().split(',')[4].trim()
                : 'Philippines'));

    // State variables
    bool isEditing = false;
    bool isLoading = false;
    String? errorMessage;
    DateTime? selectedDate;
    File? selectedImage;
    Uint8List? webImageBytes;

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
          birthdateController.text =
              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        });
      }
    }

    // Function to pick image
    Future<void> pickImage(StateSetter setModalState) async {
      if (kIsWeb) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
        );
        if (result != null && result.files.single.bytes != null) {
          setModalState(() {
            webImageBytes = result.files.single.bytes;
            selectedImage = null;
          });
        }
      } else if (Platform.isAndroid || Platform.isIOS) {
        final ImagePicker picker = ImagePicker();
        final XFile? image =
            await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setModalState(() {
            selectedImage = File(image.path);
            webImageBytes = null;
          });
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
        );
        if (result != null && result.files.single.path != null) {
          setModalState(() {
            selectedImage = File(result.files.single.path!);
            webImageBytes = null;
          });
        }
      }
    }

    // Function to save changes
    Future<void> saveChanges(StateSetter setModalState) async {
      setModalState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        // Prepare address string
        List<String> addressParts = [
          streetController.text.trim(),
          cityController.text.trim(),
          stateController.text.trim(),
          postalCodeController.text.trim(),
          countryController.text.trim(),
        ].where((part) => part.isNotEmpty).toList();

        String? address =
            addressParts.isNotEmpty ? addressParts.join(', ') : null;

        // Prepare update data
        final updateData = {
          'first_name': firstNameController.text.trim(),
          'middle_name': middleNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'birthdate': birthdateController.text.trim(),
          'phone_number': contactController.text.trim(),
          'emergency_contact_name': emergencyNameController.text.trim(),
          'emergency_contact_number': emergencyPhoneController.text.trim(),
          'updated_by': 'admin',
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Call API to update customer
        final customerId = customer['customer_id'] ?? customer['id'];
        if (customerId != null) {
          final result = await ApiService.updateCustomer(
            id: customerId is int
                ? customerId
                : int.tryParse(customerId.toString()) ?? -1,
            data: updateData,
          );

          if (result['success'] == true) {
            setModalState(() {
              isEditing = false;
              isLoading = false;
            });

            // Show success message and close modal
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Customer updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop(true);
            }
          } else {
            setModalState(() {
              errorMessage = result['message'] ?? 'Failed to update customer';
              isLoading = false;
            });
          }
        }
      } catch (e) {
        setModalState(() {
          errorMessage = 'Error updating customer: $e';
          isLoading = false;
        });
      }
    }

    // Build a form field with label
    Widget buildFormField(String label, TextEditingController controller,
        {bool isPassword = false,
        bool isReadOnly = false,
        VoidCallback? onTap,
        bool isRequired = false}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isPassword,
            readOnly: isReadOnly || !isEditing,
            onTap: onTap,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black.withAlpha((0.3 * 255).toInt()),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
              suffixIcon: isReadOnly && onTap != null
                  ? const Icon(Icons.calendar_today,
                      color: Colors.white70, size: 20)
                  : null,
            ),
          ),
        ],
      );
    }

    // Build image section
    Widget buildImageSection(StateSetter setModalState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Image',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: Colors.white.withAlpha((0.25 * 255).toInt()),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
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
                                size: 60,
                                color: Colors.white70,
                              ),
                  ),
                ),
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => pickImage(setModalState),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Change Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
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
                              : 700,
                          constraints: const BoxConstraints(maxHeight: 800),
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
                                  // Header
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
                                              child: Icon(
                                                isEditing
                                                    ? Icons.edit
                                                    : Icons.person,
                                                color: Colors.lightBlueAccent,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              isEditing
                                                  ? 'Edit Customer'
                                                  : 'View Customer',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: Colors.white,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isEditing)
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            setModalState(() {
                                              isEditing = true;
                                            });
                                          },
                                          icon:
                                              const Icon(Icons.edit, size: 18),
                                          label: const Text('Edit'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.lightBlueAccent,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 10),
                                          ),
                                        ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        icon: const Icon(
                                          Icons.close,
                                          size: 26,
                                          color: Colors.white,
                                        ),
                                        tooltip: 'Close',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
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

                                  // Error message
                                  if (errorMessage != null)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      margin: const EdgeInsets.only(bottom: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withAlpha(
                                          (0.2 * 255).toInt(),
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.red.withAlpha(
                                            (0.5 * 255).toInt(),
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: Colors.red,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              errorMessage!,
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Personal Information Section
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withAlpha((0.05 * 255).toInt()),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white
                                            .withAlpha((0.1 * 255).toInt()),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.person,
                                              color: Colors.lightBlueAccent,
                                              size: 24,
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Personal Information',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.lightBlueAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        buildImageSection(setModalState),
                                        const SizedBox(height: 24),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: buildFormField(
                                                  "First Name",
                                                  firstNameController,
                                                  isRequired: true),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: buildFormField(
                                                  "Middle Name",
                                                  middleNameController),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        buildFormField(
                                            "Last Name", lastNameController,
                                            isRequired: true),
                                        const SizedBox(height: 20),
                                        buildFormField("Date of Birth",
                                            birthdateController,
                                            isReadOnly: true,
                                            onTap: () =>
                                                pickDate(setModalState)),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: buildFormField(
                                                  "Email", emailController,
                                                  isRequired: true),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: buildFormField(
                                                  "Contact Number",
                                                  contactController),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: buildFormField(
                                                  "Emergency Contact Name",
                                                  emergencyNameController),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: buildFormField(
                                                  "Emergency Contact Phone",
                                                  emergencyPhoneController),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Address Section
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withAlpha((0.05 * 255).toInt()),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white
                                            .withAlpha((0.1 * 255).toInt()),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              color: Colors.lightBlueAccent,
                                              size: 24,
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Address Information',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.lightBlueAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        buildFormField(
                                            "Street", streetController),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: buildFormField(
                                                  "City", cityController),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: buildFormField(
                                                  "State/Province",
                                                  stateController),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: buildFormField(
                                                  "Postal Code",
                                                  postalCodeController),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: buildFormField(
                                                  "Country", countryController),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  // Action buttons
                                  if (isEditing)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton(
                                          onPressed: isLoading
                                              ? null
                                              : () {
                                                  setModalState(() {
                                                    isEditing = false;
                                                    // Reset form to original values
                                                    firstNameController.text =
                                                        customer[
                                                                'first_name'] ??
                                                            '';
                                                    middleNameController
                                                        .text = customer[
                                                            'middle_name'] ??
                                                        '';
                                                    lastNameController.text =
                                                        customer['last_name'] ??
                                                            '';
                                                    emailController.text =
                                                        customer['email'] ?? '';
                                                    contactController
                                                        .text = customer[
                                                            'phone_number'] ??
                                                        '';
                                                    birthdateController.text =
                                                        customer['birthdate'] ??
                                                            '';
                                                    emergencyNameController
                                                        .text = customer[
                                                            'emergency_contact_name'] ??
                                                        '';
                                                    emergencyPhoneController
                                                        .text = customer[
                                                            'emergency_contact_number'] ??
                                                        '';
                                                    streetController
                                                        .text = customer[
                                                                'address_details']
                                                            ?['street'] ??
                                                        '';
                                                    cityController
                                                        .text = customer[
                                                                'address_details']
                                                            ?['city'] ??
                                                        '';
                                                    stateController
                                                        .text = customer[
                                                                'address_details']
                                                            ?['state'] ??
                                                        '';
                                                    postalCodeController
                                                        .text = customer[
                                                                'address_details']
                                                            ?['postal_code'] ??
                                                        '';
                                                    countryController
                                                        .text = customer[
                                                                'address_details']
                                                            ?['country'] ??
                                                        '';
                                                    selectedImage = null;
                                                    webImageBytes = null;
                                                    errorMessage = null;
                                                  });
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 12),
                                          ),
                                          child: const Text("Cancel"),
                                        ),
                                        const SizedBox(width: 16),
                                        ElevatedButton(
                                          onPressed: isLoading
                                              ? null
                                              : () =>
                                                  saveChanges(setModalState),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.lightBlueAccent,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 12),
                                          ),
                                          child: isLoading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.black),
                                                  ),
                                                )
                                              : const Text("Save Changes"),
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
    return false; // Return false if modal is closed without updating
  }
}
