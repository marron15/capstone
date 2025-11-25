import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:math' as math;
// Removed image picker and file picker imports
import '../../services/unified_auth_state.dart';
import '../services/api_service.dart';
import '../../PH phone number valid/phone_validator.dart';
import '../../PH phone number valid/phone_formatter.dart';

class CustomerViewEditModal {
  // Show the modal dialog for viewing and editing a customer
  static Future<bool> showCustomerModal(
    BuildContext context,
    Map<String, dynamic> customer,
  ) async {
    // Avoid logging customer data in console

    // Force portrait orientation while the modal is open
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // After the async gap above, ensure the context is still mounted
    if (!context.mounted) {
      return false;
    }

    // Controllers for customer form
    final TextEditingController firstNameController = TextEditingController(
      text: customer['first_name'] ?? '',
    );
    final TextEditingController middleNameController = TextEditingController(
      text: customer['middle_name'] ?? '',
    );
    final TextEditingController lastNameController = TextEditingController(
      text: customer['last_name'] ?? '',
    );
    final TextEditingController emailController = TextEditingController(
      text: customer['email'] ?? '',
    );
    final TextEditingController contactController = TextEditingController(
      text: PhoneFormatter.formatWithSpaces(customer['phone_number'] ?? ''),
    );
    final TextEditingController birthdateController = TextEditingController(
      text: customer['birthdate'] ?? '',
    );
    final TextEditingController emergencyNameController = TextEditingController(
      text: customer['emergency_contact_name'] ?? '',
    );
    final TextEditingController emergencyPhoneController =
        TextEditingController(
          text: PhoneFormatter.formatWithSpaces(
            customer['emergency_contact_number'] ?? '',
          ),
        );
    // Handle password field - store original password for display
    final String originalPassword = customer['password'] ?? '';
    final TextEditingController passwordController = TextEditingController(
      text: '', // Start empty for editing
    );

    // Store the current display password (for showing when not editing)
    String currentDisplayPassword =
        originalPassword.startsWith(r'$2y$') && originalPassword.length > 50
            ? '' // Don't show hashed passwords
            : originalPassword;

    // Transaction controllers and related UI removed

    // Handle address fields with fallbacks
    final TextEditingController streetController = TextEditingController(
      text:
          customer['address_details']?['street'] ??
          (customer['address'] != null
              ? customer['address'].toString().split(',')[0].trim()
              : ''),
    );
    final TextEditingController cityController = TextEditingController(
      text:
          customer['address_details']?['city'] ??
          (customer['address'] != null &&
                  customer['address'].toString().split(',').length > 1
              ? customer['address'].toString().split(',')[1].trim()
              : ''),
    );
    final TextEditingController stateController = TextEditingController(
      text:
          customer['address_details']?['state'] ??
          (customer['address'] != null &&
                  customer['address'].toString().split(',').length > 2
              ? customer['address'].toString().split(',')[2].trim()
              : ''),
    );
    final TextEditingController postalCodeController = TextEditingController(
      text:
          customer['address_details']?['postal_code'] ??
          (customer['address'] != null &&
                  customer['address'].toString().split(',').length > 3
              ? customer['address'].toString().split(',')[3].trim()
              : ''),
    );
    final TextEditingController countryController = TextEditingController(
      text:
          customer['address_details']?['country'] ??
          (customer['address'] != null &&
                  customer['address'].toString().split(',').length > 4
              ? customer['address'].toString().split(',')[4].trim()
              : 'Philippines'),
    );

    // Preserve original values for change detection
    final String originalFirstName = firstNameController.text.trim();
    final String originalMiddleName = middleNameController.text.trim();
    final String originalLastName = lastNameController.text.trim();
    final String originalEmail = emailController.text.trim();
    final String originalPhone = PhoneFormatter.cleanPhoneNumber(
      contactController.text.trim(),
    );
    final String originalEmergencyName = emergencyNameController.text.trim();
    final String originalEmergencyPhone = PhoneFormatter.cleanPhoneNumber(
      emergencyPhoneController.text.trim(),
    );
    final String originalStreet = streetController.text.trim();
    final String originalCity = cityController.text.trim();
    final String originalState = stateController.text.trim();
    final String originalPostalCode = postalCodeController.text.trim();
    final String originalCountry = countryController.text.trim();
    final String originalBirthdate = birthdateController.text.trim();

    // Membership Type state with normalization and fallback
    String normalizeMembershipType(String? raw) {
      final String value = (raw ?? '').trim();
      if (value.isEmpty) return '';
      final String lower = value.toLowerCase();
      if (lower == 'daily') return 'Daily';
      if (lower.replaceAll(' ', '') == 'halfmonth') return 'Half Month';
      if (lower == 'monthly') return 'Monthly';
      return '';
    }

    String membershipType = normalizeMembershipType(
      (customer['membership']?['membership_type'] ??
              customer['membership_type'] ??
              // Fallbacks when API provided camelCase or uses status
              customer['membership']?['status'] ??
              customer['status'] ??
              customer['membershipType'])
          .toString(),
    );
    final String originalMembershipType = membershipType;

    // State variables
    bool isEditing = true;
    bool isLoading = false;
    bool isPasswordVisible = false;
    String? errorMessage;
    // Image-related state removed
    String? contactError;
    String? emergencyPhoneError;

    // Transaction-related state removed

    // Image picker removed

    // Transaction-related pickers removed

    // Function to save changes
    Future<void> saveChanges(StateSetter setModalState) async {
      setModalState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        // Validate contact number and emergency number as Philippine mobile numbers
        final String phone = PhoneFormatter.cleanPhoneNumber(
          contactController.text.trim(),
        );
        final String emergencyPhone = PhoneFormatter.cleanPhoneNumber(
          emergencyPhoneController.text.trim(),
        );
        String? localContactError;
        String? localEmergencyError;

        if (phone.isNotEmpty) {
          final phoneValidation = PhoneValidator.validatePhilippineMobile(
            phone,
          );
          if (!phoneValidation.isValid) {
            localContactError = phoneValidation.errorMessage;
          }
        }

        if (emergencyPhone.isNotEmpty) {
          final emergencyValidation = PhoneValidator.validatePhilippineMobile(
            emergencyPhone,
          );
          if (!emergencyValidation.isValid) {
            localEmergencyError = emergencyValidation.errorMessage;
          }
        }
        if (localContactError != null || localEmergencyError != null) {
          setModalState(() {
            isLoading = false;
            contactError = localContactError;
            emergencyPhoneError = localEmergencyError;
          });
          return;
        }
        // Clear errors if valid
        setModalState(() {
          contactError = null;
          emergencyPhoneError = null;
        });
        final dynamic rawCustomerId =
            customer['customerId'] ?? customer['customer_id'] ?? customer['id'];
        if (rawCustomerId == null) {
          setModalState(() {
            errorMessage =
                'Customer ID not found. Available keys: ${customer.keys.join(', ')}';
            isLoading = false;
          });
          return;
        }
        final int customerId =
            rawCustomerId is int
                ? rawCustomerId
                : int.tryParse('$rawCustomerId') ?? -1;

        final String lockedFirstName = originalFirstName;
        final String lockedMiddleName = originalMiddleName;
        final String lockedLastName = originalLastName;
        final String lockedBirthdate = originalBirthdate;
        final String lockedEmail =
            emailController.text.trim().isNotEmpty
                ? emailController.text.trim()
                : originalEmail;

        const bool firstNameChanged = false;
        const bool middleNameChanged = false;
        const bool lastNameChanged = false;
        final bool emailChanged = lockedEmail != originalEmail;
        final bool phoneChanged = phone != originalPhone;
        final bool emergencyNameChanged =
            emergencyNameController.text.trim() != originalEmergencyName;
        final bool emergencyPhoneChanged =
            emergencyPhone != originalEmergencyPhone;
        final bool addressChanged =
            streetController.text.trim() != originalStreet ||
            cityController.text.trim() != originalCity ||
            stateController.text.trim() != originalState ||
            postalCodeController.text.trim() != originalPostalCode ||
            countryController.text.trim() != originalCountry;
        final bool hasPasswordChange =
            passwordController.text.trim().isNotEmpty;
        final bool membershipChanged =
            membershipType.isNotEmpty &&
            membershipType != originalMembershipType;

        final bool hasProfileChanges =
            firstNameChanged ||
            middleNameChanged ||
            lastNameChanged ||
            emailChanged ||
            phoneChanged ||
            emergencyNameChanged ||
            emergencyPhoneChanged ||
            addressChanged ||
            hasPasswordChange;

        Future<void> applyLocalMembershipUpdates() async {
          customer['membership_type'] = membershipType;
          customer['membershipType'] = membershipType;
          final DateTime newStartDate = DateTime.now();
          DateTime newExpirationDate;
          switch (membershipType) {
            case 'Daily':
              // Set expiration to 9 PM of the same day (business hours: 11 AM - 9 PM)
              // If created after 9 PM, expire at 9 PM next day
              newExpirationDate = DateTime(
                newStartDate.year,
                newStartDate.month,
                newStartDate.day,
                21, // 9 PM
                0,  // 0 minutes
                0,  // 0 seconds
              );
              if (newStartDate.hour >= 21) {
                newExpirationDate = newExpirationDate.add(const Duration(days: 1));
              }
              break;
            case 'Half Month':
              newExpirationDate = newStartDate.add(const Duration(days: 15));
              break;
            case 'Monthly':
            default:
              newExpirationDate = newStartDate.add(const Duration(days: 30));
          }
          customer['startDate'] = newStartDate;
          customer['expirationDate'] = newExpirationDate;
          // For Daily memberships, include time component in both start and expiration dates
          if (membershipType == 'Daily') {
            customer['start_date'] =
                '${newStartDate.year.toString().padLeft(4, '0')}-${newStartDate.month.toString().padLeft(2, '0')}-${newStartDate.day.toString().padLeft(2, '0')} ${newStartDate.hour.toString().padLeft(2, '0')}:${newStartDate.minute.toString().padLeft(2, '0')}:${newStartDate.second.toString().padLeft(2, '0')}';
            customer['expiration_date'] =
                '${newExpirationDate.year.toString().padLeft(4, '0')}-${newExpirationDate.month.toString().padLeft(2, '0')}-${newExpirationDate.day.toString().padLeft(2, '0')} ${newExpirationDate.hour.toString().padLeft(2, '0')}:${newExpirationDate.minute.toString().padLeft(2, '0')}:${newExpirationDate.second.toString().padLeft(2, '0')}';
          } else {
            customer['start_date'] =
                '${newStartDate.year.toString().padLeft(4, '0')}-${newStartDate.month.toString().padLeft(2, '0')}-${newStartDate.day.toString().padLeft(2, '0')}';
            customer['expiration_date'] =
                '${newExpirationDate.year.toString().padLeft(4, '0')}-${newExpirationDate.month.toString().padLeft(2, '0')}-${newExpirationDate.day.toString().padLeft(2, '0')}';
          }
        }

        if (membershipChanged && !hasProfileChanges) {
          final bool upserted = await ApiService.upsertCustomerMembership(
            customerId: customerId,
            membershipType: membershipType,
          );
          if (upserted) {
            await applyLocalMembershipUpdates();
            setModalState(() {
              isLoading = false;
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Membership updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop(true);
            }
          } else {
            setModalState(() {
              errorMessage = 'Failed to update membership';
              isLoading = false;
            });
          }
          return;
        }

        // Prepare update data
        final Map<String, dynamic> updateData = {
          'first_name': lockedFirstName,
          'middle_name': lockedMiddleName,
          'last_name': lockedLastName,
          'email': lockedEmail,
          'birthdate': lockedBirthdate,
          'phone_number': phone,
          'emergency_contact_name': emergencyNameController.text.trim(),
          'emergency_contact_number': emergencyPhone,
          'status':
              (customer['status'] ?? 'active').toString().isEmpty
                  ? 'active'
                  : (customer['status'] ?? 'active').toString(),
          'password':
              passwordController.text.trim().isNotEmpty
                  ? passwordController.text.trim()
                  : null,
          'updated_by': 'admin',
          'updated_at': DateTime.now().toIso8601String(),
        };

        final bool hasAnyAddress =
            streetController.text.trim().isNotEmpty ||
            cityController.text.trim().isNotEmpty ||
            stateController.text.trim().isNotEmpty ||
            postalCodeController.text.trim().isNotEmpty ||
            countryController.text.trim().isNotEmpty;

        if (hasAnyAddress) {
          updateData['address_details'] = {
            'street': streetController.text.trim(),
            'city': cityController.text.trim(),
            'state': stateController.text.trim(),
            'postal_code': postalCodeController.text.trim(),
            'country': countryController.text.trim(),
          };
        }

        if (membershipType.isNotEmpty) {
          updateData['membership_type'] = membershipType;
        }

        final adminData = unifiedAuthState.adminData;
        final dynamic adminIdValue = adminData == null ? null : adminData['id'];
        final int? adminId =
            adminIdValue is int ? adminIdValue : int.tryParse(adminIdValue?.toString() ?? '');
        final String adminName = adminData == null
            ? ''
            : [
                (adminData['first_name'] ?? '').toString().trim(),
                (adminData['last_name'] ?? '').toString().trim(),
              ].where((segment) => segment.isNotEmpty).join(' ');

        final result = await ApiService.updateCustomerByAdmin(
          id: customerId,
          data: updateData,
          adminId: adminId,
          adminName: adminName.isNotEmpty ? adminName : null,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Request timed out after 30 seconds');
          },
        );

        // Handle API response without logging full payload

        if (result['success'] == true) {
          // Success - update local customer data with new values
          customer['first_name'] = lockedFirstName;
          customer['middle_name'] = lockedMiddleName;
          customer['last_name'] = lockedLastName;
          customer['email'] = lockedEmail;
          customer['birthdate'] = lockedBirthdate;
          customer['phone_number'] = phone;
          customer['emergency_contact_name'] =
              emergencyNameController.text.trim();
          customer['emergency_contact_number'] = emergencyPhone;

          // Update password if it was changed (don't store plain text in local data)
          if (passwordController.text.trim().isNotEmpty) {
            // Password updated (hashed on backend)
          }

          // Update address details if they were changed
          if (hasAnyAddress) {
            customer['address_details'] = {
              'street': streetController.text.trim(),
              'city': cityController.text.trim(),
              'state': stateController.text.trim(),
              'postal_code': postalCodeController.text.trim(),
              'country': countryController.text.trim(),
            };
          }

          // Update local membership type and dates for UI immediately
          if (membershipType.isNotEmpty &&
              membershipType != originalMembershipType) {
            await applyLocalMembershipUpdates();
          }

          // Do not log updated customer data

          // Reset state
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
      } catch (e) {
        debugPrint('Error updating customer: $e');
        setModalState(() {
          errorMessage = 'Error updating customer: $e';
          isLoading = false;
        });
      } finally {
        // Safety mechanism: ensure loading state is always reset
        if (isLoading) {
          setModalState(() {
            isLoading = false;
          });
        }
      }
    }

    // Build a form field with label
    Widget buildFormField(
      String label,
      TextEditingController controller, {
      bool isPassword = false,
      bool isReadOnly = false,
      VoidCallback? onTap,
      bool isRequired = false,
      String? fieldError,
    }) {
      final bool isEditable = isEditing && !isReadOnly;
      final String normalizedLabel = label.toLowerCase();
      final bool isPhoneField =
          normalizedLabel.contains('phone') ||
          normalizedLabel.contains('number');
      final bool isEmailField = normalizedLabel.contains('email');
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
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isPassword,
            readOnly: !isEditable,
            onTap: onTap,
            style: TextStyle(color: isEditable ? Colors.white : Colors.white70),
            keyboardType:
                isPhoneField
                    ? TextInputType.phone
                    : isEmailField
                    ? TextInputType.emailAddress
                    : null,
            inputFormatters:
                isPhoneField ? [PhoneFormatter.phoneNumberFormatter] : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black.withAlpha((0.3 * 255).toInt()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
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
                  isReadOnly && onTap != null
                      ? const Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 20,
                      )
                      : null,
            ),
          ),
          if (fieldError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha((0.14 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withAlpha((0.45 * 255).toInt()),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fieldError,
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
          ],
        ],
      );
    }

    // Profile image section removed

    final bool? dialogResult = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              alignment: Alignment.center,
              insetPadding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      // Glassmorphism effect
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width: math.min(
                            MediaQuery.of(context).size.width * 0.88,
                            820,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: 820,
                            maxHeight: MediaQuery.of(context).size.height * 0.9,
                          ),
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
                              horizontal: 28,
                              vertical: 24,
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
                                              isPasswordVisible =
                                                  false; // Reset password visibility when entering edit mode
                                              // Clear the password field for editing
                                              passwordController.text = '';
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 18,
                                          ),
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
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
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

                                  // Personal and Address Sections side-by-side on wide screens
                                  Builder(
                                    builder: (context) {
                                      final Widget personalSection = Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(
                                            (0.05 * 255).toInt(),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withAlpha(
                                              (0.1 * 255).toInt(),
                                            ),
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
                                                    color:
                                                        Colors.lightBlueAccent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      buildFormField(
                                                        "First Name",
                                                        firstNameController,
                                                        isRequired: true,
                                                        isReadOnly: true,
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      // Middle Name moved to a separate left-right row below
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        'Membership Type',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      IgnorePointer(
                                                        ignoring: !isEditing,
                                                        child: DropdownButtonFormField<
                                                          String
                                                        >(
                                                          key: ValueKey<
                                                            String?
                                                          >(
                                                            membershipType
                                                                    .isEmpty
                                                                ? null
                                                                : membershipType,
                                                          ),
                                                          initialValue:
                                                              membershipType
                                                                      .isEmpty
                                                                  ? null
                                                                  : membershipType,
                                                          items: const [
                                                            DropdownMenuItem(
                                                              value: 'Daily',
                                                              child: Text(
                                                                'Daily',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                              ),
                                                            ),
                                                            DropdownMenuItem(
                                                              value:
                                                                  'Half Month',
                                                              child: Text(
                                                                'Half Month',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                              ),
                                                            ),
                                                            DropdownMenuItem(
                                                              value: 'Monthly',
                                                              child: Text(
                                                                'Monthly',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                          onChanged: (val) {
                                                            if (val == null) {
                                                              return;
                                                            }
                                                            setModalState(() {
                                                              membershipType =
                                                                  val;
                                                            });
                                                          },
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                          dropdownColor:
                                                              const Color(
                                                                0xFF1E1E1E,
                                                              ),
                                                          iconEnabledColor:
                                                              Colors.white70,
                                                          iconDisabledColor:
                                                              Colors.white38,
                                                          decoration: InputDecoration(
                                                            filled: true,
                                                            fillColor: Colors
                                                                .black
                                                                .withAlpha(
                                                                  (0.3 * 255)
                                                                      .toInt(),
                                                                ),
                                                            border: OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    14,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: buildFormField(
                                                    "Middle Name",
                                                    middleNameController,
                                                    isReadOnly: true,
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                Expanded(
                                                  child: buildFormField(
                                                    "Last Name",
                                                    lastNameController,
                                                    isRequired: true,
                                                    isReadOnly: true,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: buildFormField(
                                                    "Date of Birth",
                                                    birthdateController,
                                                    isReadOnly: true,
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                Expanded(
                                                  child: buildFormField(
                                                    "Contact Number",
                                                    contactController,
                                                    fieldError: contactError,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: buildFormField(
                                                    "Email",
                                                    emailController,
                                                    isRequired: true,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Text(
                                                      "New Password",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    if (isEditing)
                                                      IconButton(
                                                        onPressed: () {
                                                          setModalState(() {
                                                            isPasswordVisible =
                                                                !isPasswordVisible;
                                                          });
                                                        },
                                                        icon: Icon(
                                                          isPasswordVisible
                                                              ? Icons
                                                                  .visibility_off
                                                              : Icons
                                                                  .visibility,
                                                          color:
                                                              Colors
                                                                  .lightBlueAccent,
                                                          size: 20,
                                                        ),
                                                        tooltip:
                                                            isPasswordVisible
                                                                ? 'Hide password'
                                                                : 'Show password',
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(
                                                              minWidth: 32,
                                                              minHeight: 32,
                                                            ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                if (!isEditing) ...[
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey
                                                          .withAlpha(
                                                            (0.2 * 255).toInt(),
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.grey
                                                            .withAlpha(
                                                              (0.4 * 255)
                                                                  .toInt(),
                                                            ),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          currentDisplayPassword
                                                                  .isEmpty
                                                              ? Icons.lock
                                                              : Icons.lock_open,
                                                          color:
                                                              currentDisplayPassword
                                                                      .isEmpty
                                                                  ? Colors
                                                                      .orange
                                                                  : Colors
                                                                      .green,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            currentDisplayPassword
                                                                    .isEmpty
                                                                ? "Current password is encrypted (enter new password to update)"
                                                                : "Current password: ${currentDisplayPassword}",
                                                            style: const TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white70,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                ],
                                                TextField(
                                                  controller:
                                                      passwordController,
                                                  obscureText:
                                                      !isPasswordVisible,
                                                  readOnly: !isEditing,
                                                  onChanged: (value) {
                                                    // Update display password when user types during editing
                                                    if (isEditing) {
                                                      setModalState(() {
                                                        currentDisplayPassword =
                                                            value;
                                                      });
                                                    }
                                                  },
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        isEditing
                                                            ? "Enter new password to change it, or leave blank to keep current"
                                                            : currentDisplayPassword
                                                                .isEmpty
                                                            ? "No password set"
                                                            : "Current password is shown above",
                                                    hintStyle: const TextStyle(
                                                      color: Colors.white54,
                                                    ),
                                                    filled: true,
                                                    fillColor: Colors.black
                                                        .withAlpha(
                                                          (0.3 * 255).toInt(),
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                      borderSide: const BorderSide(
                                                        color:
                                                            Colors
                                                                .lightBlueAccent,
                                                        width: 1.2,
                                                      ),
                                                    ),
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 14,
                                                        ),
                                                    suffixIcon:
                                                        isEditing
                                                            ? IconButton(
                                                              onPressed: () {
                                                                setModalState(() {
                                                                  isPasswordVisible =
                                                                      !isPasswordVisible;
                                                                });
                                                              },
                                                              icon: Icon(
                                                                isPasswordVisible
                                                                    ? Icons
                                                                        .visibility_off
                                                                    : Icons
                                                                        .visibility,
                                                                color:
                                                                    Colors
                                                                        .white70,
                                                                size: 20,
                                                              ),
                                                              tooltip:
                                                                  isPasswordVisible
                                                                      ? 'Hide password'
                                                                      : 'Show password',
                                                            )
                                                            : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (isEditing) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withAlpha(
                                                    (0.1 * 255).toInt(),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.blue
                                                        .withAlpha(
                                                          (0.3 * 255).toInt(),
                                                        ),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.info_outline,
                                                      color: Colors.blue,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Expanded(
                                                      child: Text(
                                                        "Enter a new password to change it, or leave blank to keep the current password.",
                                                        style: TextStyle(
                                                          color: Colors.blue,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 20),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: buildFormField(
                                                    "Emergency Contact Name",
                                                    emergencyNameController,
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                Expanded(
                                                  child: buildFormField(
                                                    "Emergency Contact Phone",
                                                    emergencyPhoneController,
                                                    fieldError:
                                                        emergencyPhoneError,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );

                                      final Widget addressSection = Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(
                                            (0.05 * 255).toInt(),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withAlpha(
                                              (0.1 * 255).toInt(),
                                            ),
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
                                                    color:
                                                        Colors.lightBlueAccent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Membership Type moved to Personal section
                                            const SizedBox(height: 20),
                                            buildFormField(
                                              "Street",
                                              streetController,
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: buildFormField(
                                                    "City",
                                                    cityController,
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                Expanded(
                                                  child: buildFormField(
                                                    "State/Province",
                                                    stateController,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: buildFormField(
                                                    "Postal Code",
                                                    postalCodeController,
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                Expanded(
                                                  child: buildFormField(
                                                    "Country",
                                                    countryController,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                      // Force portrait-style (single column) layout
                                      return Column(
                                        children: [
                                          personalSection,
                                          const SizedBox(height: 24),
                                          addressSection,
                                        ],
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 32),

                                  // Transaction section removed

                                  // Action buttons
                                  if (isEditing)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton(
                                          onPressed:
                                              isLoading
                                                  ? null
                                                  : () {
                                                    setModalState(() {
                                                      isEditing = false;
                                                      isPasswordVisible =
                                                          false; // Reset password visibility
                                                      // Reset form to original values
                                                      firstNameController.text =
                                                          customer['first_name'] ??
                                                          '';
                                                      middleNameController
                                                              .text =
                                                          customer['middle_name'] ??
                                                          '';
                                                      lastNameController.text =
                                                          customer['last_name'] ??
                                                          '';
                                                      emailController.text =
                                                          customer['email'] ??
                                                          '';
                                                      contactController.text =
                                                          PhoneFormatter.formatWithSpaces(
                                                            customer['phone_number'] ??
                                                                '',
                                                          );
                                                      birthdateController.text =
                                                          customer['birthdate'] ??
                                                          '';
                                                      emergencyNameController
                                                              .text =
                                                          customer['emergency_contact_name'] ??
                                                          '';
                                                      emergencyPhoneController
                                                              .text =
                                                          PhoneFormatter.formatWithSpaces(
                                                            customer['emergency_contact_number'] ??
                                                                '',
                                                          );
                                                      // Reset password field and display password
                                                      passwordController.text =
                                                          '';
                                                      currentDisplayPassword =
                                                          originalPassword
                                                                      .startsWith(
                                                                        r'$2y$',
                                                                      ) &&
                                                                  originalPassword
                                                                          .length >
                                                                      50
                                                              ? '' // Don't show hashed passwords
                                                              : originalPassword;
                                                      streetController.text =
                                                          customer['address_details']?['street'] ??
                                                          '';
                                                      cityController.text =
                                                          customer['address_details']?['city'] ??
                                                          '';
                                                      stateController.text =
                                                          customer['address_details']?['state'] ??
                                                          '';
                                                      postalCodeController
                                                              .text =
                                                          customer['address_details']?['postal_code'] ??
                                                          '';
                                                      countryController.text =
                                                          customer['address_details']?['country'] ??
                                                          '';
                                                      // Transaction reset removed
                                                      // Image state reset removed
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
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                          ),
                                          child: const Text("Cancel"),
                                        ),
                                        const SizedBox(width: 16),
                                        ElevatedButton(
                                          onPressed:
                                              isLoading
                                                  ? null
                                                  : () => saveChanges(
                                                    setModalState,
                                                  ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.lightBlueAccent,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
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

    // Restore portrait orientation after modal closes
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return dialogResult ??
        false; // Return false if modal is closed without updating
  }
}
