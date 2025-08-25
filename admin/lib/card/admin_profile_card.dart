import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../modal/admin_modal.dart';
import '../services/admin_service.dart';

class AdminProfileCard extends StatelessWidget {
  final Map<String, dynamic> admin;
  final int index;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;
  final TextEditingController searchController;
  final List<Map<String, dynamic>> admins;
  final Function(List<Map<String, dynamic>>) updateFilteredAdmins;

  const AdminProfileCard({
    super.key,
    required this.admin,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.searchController,
    required this.admins,
    required this.updateFilteredAdmins,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isDesktopGrid = !isMobile;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 15 : 20),
      child: Card(
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            minHeight: isMobile ? 180 : (isDesktopGrid ? 200 : 230),
            maxHeight: isMobile ? 240 : (isDesktopGrid ? 260 : 300),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Section with Profile Image and Name
                Flexible(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced Profile Image
                      _buildEnhancedProfileImage(isMobile, isDesktopGrid),
                      SizedBox(width: isMobile ? 10 : 12),

                      // Admin Details Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Name with enhanced styling
                            _buildNameSection(isMobile, isDesktopGrid),
                            SizedBox(height: isMobile ? 4 : 6),

                            // Status Badge
                            _buildStatusBadge(),
                            SizedBox(height: isMobile ? 6 : 8),

                            // Contact Information
                            Flexible(
                              child: _buildContactInformation(
                                  isMobile, isDesktopGrid),
                            ),
                          ],
                        ),
                      ),

                      // Action Buttons
                      _buildActionButtons(isMobile, isDesktopGrid, context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced profile image with better styling
  Widget _buildEnhancedProfileImage(bool isMobile, bool isDesktopGrid) {
    final size = isMobile ? 55.0 : (isDesktopGrid ? 65.0 : 75.0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade100,
                Colors.blue.shade50,
              ],
            ),
          ),
          child: _buildProfileImage(admin['img'] ?? admin['profileImage']),
        ),
      ),
    );
  }

  // Enhanced name section
  Widget _buildNameSection(bool isMobile, bool isDesktopGrid) {
    // Build full name with proper handling of missing parts
    List<String> nameParts = [];

    // Add first name (required) - handle both API and local field names
    final firstName = admin['first_name'] ?? admin['firstName'];
    if (firstName != null && firstName.toString().trim().isNotEmpty) {
      nameParts.add(firstName.toString().trim());
    }

    // Add middle name (optional) - handle both API and local field names
    final middleName = admin['middle_name'] ?? admin['middleName'];
    if (middleName != null && middleName.toString().trim().isNotEmpty) {
      nameParts.add(middleName.toString().trim());
    }

    // Add last name (required) - handle both API and local field names
    final lastName = admin['last_name'] ?? admin['lastName'];
    if (lastName != null && lastName.toString().trim().isNotEmpty) {
      nameParts.add(lastName.toString().trim());
    }

    // Join all parts with spaces
    String fullName = nameParts.join(' ');

    // Fallback if no name parts found
    if (fullName.isEmpty) {
      fullName = 'Unknown Admin';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullName,
          style: TextStyle(
            fontSize: isMobile ? 16 : (isDesktopGrid ? 15 : 18),
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'Administrator',
          style: TextStyle(
            fontSize: isMobile ? 10 : (isDesktopGrid ? 9 : 11),
            color: Colors.blue.shade600,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // Status badge
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Active',
            style: TextStyle(
              fontSize: 8,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced contact information section
  Widget _buildContactInformation(bool isMobile, bool isDesktopGrid) {
    // Check if we have date of birth to limit the number of fields shown
    final hasDateOfBirth = (admin['date_of_birth'] ?? admin['dateOfBirth']) !=
            null &&
        (admin['date_of_birth'] ?? admin['dateOfBirth']).toString().isNotEmpty;

    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEnhancedInfoRow(
            Icons.email_outlined,
            'Email',
            admin['email_address'] ?? admin['email'],
            Colors.blue,
            isMobile: isMobile,
            isCompact: isDesktopGrid,
          ),
          SizedBox(height: isMobile ? 4 : 6),
          _buildEnhancedInfoRow(
            Icons.phone_outlined,
            'Contact',
            admin['phone_number'] ?? admin['contactNumber'],
            Colors.green,
            isMobile: isMobile,
            isCompact: isDesktopGrid,
          ),
          // Only show date of birth if there's space and it exists
          if (hasDateOfBirth && !isMobile) ...[
            SizedBox(height: isMobile ? 4 : 6),
            _buildEnhancedInfoRow(
              Icons.cake_outlined,
              'DOB',
              admin['date_of_birth'] ?? admin['dateOfBirth'],
              Colors.purple,
              isMobile: isMobile,
              isCompact: true,
            ),
          ],
          SizedBox(height: isMobile ? 4 : 6),
          _buildEnhancedInfoRow(
            Icons.lock_outline,
            'Password',
            admin['password'] ?? '********',
            Colors.orange,
            isMobile: isMobile,
            isCompact: isDesktopGrid,
          ),
        ],
      ),
    );
  }

  // Enhanced action buttons
  Widget _buildActionButtons(
      bool isMobile, bool isDesktopGrid, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActionButton(
                icon: Icons.edit_outlined,
                color: Colors.blue,
                onPressed: () => _handleEdit(context),
                isMobile: isMobile,
                isDesktopGrid: isDesktopGrid,
                tooltip: 'Edit Admin',
              ),
              Container(
                height: 1,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              _buildActionButton(
                icon: Icons.delete_outline,
                color: Colors.red,
                onPressed: () => _handleDelete(context),
                isMobile: isMobile,
                isDesktopGrid: isDesktopGrid,
                tooltip: 'Delete Admin',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Individual action button
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool isMobile,
    required bool isDesktopGrid,
    required String tooltip,
  }) {
    final size = isMobile ? 32.0 : (isDesktopGrid ? 36.0 : 40.0);
    final iconSize = isMobile ? 16.0 : (isDesktopGrid ? 18.0 : 20.0);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  // Handle edit functionality
  void _handleEdit(BuildContext context) {
    AdminModal.showEditAdminModal(
      context,
      admin,
      (updatedAdmin) {
        // Update the admin in the main list
        final adminIndex = admins.indexWhere((a) => a['id'] == admin['id']);
        if (adminIndex != -1) {
          admins[adminIndex] = updatedAdmin;
        }

        // Call the callback
        onEdit(updatedAdmin);

        // Update filtered admins list
        _updateFilteredList();

        // Show success message
        final firstName =
            updatedAdmin['first_name'] ?? updatedAdmin['firstName'] ?? 'Admin';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$firstName updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  // Handle delete functionality
  void _handleDelete(BuildContext context) {
    final firstName = admin['first_name'] ?? admin['firstName'] ?? 'Unknown';
    final lastName = admin['last_name'] ?? admin['lastName'] ?? 'Admin';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
              const SizedBox(width: 12),
              const Text('Delete Admin'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete $firstName $lastName? This action cannot be undone.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close the confirmation dialog
                Navigator.of(context).pop();

                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 16),
                        Text('Deleting admin...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );

                try {
                  // Call the delete service
                  final adminId = admin['id'];
                  final success = await AdminService.deleteAdmin(adminId);

                  // Check if widget is still mounted before using context
                  if (!context.mounted) return;

                  if (success) {
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('$firstName $lastName deleted successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Call the callback to remove from the list
                    onDelete(index);

                    // Update filtered admins list
                    _updateFilteredList();
                  } else {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete admin'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  // Check if widget is still mounted before using context
                  if (!context.mounted) return;

                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting admin: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Update filtered admins list based on current search
  void _updateFilteredList() {
    final query = searchController.text.toLowerCase();
    List<Map<String, dynamic>> filteredList;

    if (query.isEmpty) {
      filteredList = List.from(admins);
    } else {
      filteredList = admins.where((admin) {
        final firstName = (admin['first_name'] ?? admin['firstName'] ?? '')
            .toString()
            .toLowerCase();
        final middleName = (admin['middle_name'] ?? admin['middleName'] ?? '')
            .toString()
            .toLowerCase();
        final lastName = (admin['last_name'] ?? admin['lastName'] ?? '')
            .toString()
            .toLowerCase();
        final email = (admin['email_address'] ?? admin['email'] ?? '')
            .toString()
            .toLowerCase();
        final phone = (admin['phone_number'] ?? admin['contactNumber'] ?? '')
            .toString()
            .toLowerCase();
        final dateOfBirth =
            (admin['date_of_birth'] ?? admin['dateOfBirth'] ?? '')
                .toString()
                .toLowerCase();

        return firstName.contains(query) ||
            middleName.contains(query) ||
            lastName.contains(query) ||
            email.contains(query) ||
            phone.contains(query) ||
            dateOfBirth.contains(query);
      }).toList();
    }

    updateFilteredAdmins(filteredList);
  }

  // Helper method to build profile image widget
  Widget _buildProfileImage(dynamic profileImage) {
    if (profileImage == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade500,
            ],
          ),
        ),
        child: const Icon(
          Icons.person,
          size: 40,
          color: Colors.white,
        ),
      );
    }

    if (kIsWeb && profileImage is Uint8List) {
      return Image.memory(
        profileImage,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (profileImage is File) {
      return Image.file(
        profileImage,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade300,
            Colors.blue.shade500,
          ],
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  // Enhanced info row with icons and better styling
  Widget _buildEnhancedInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor, {
    bool isMobile = false,
    bool isCompact = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isMobile || isCompact ? 3 : 4),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: isMobile || isCompact ? 10 : 12,
            color: iconColor,
          ),
        ),
        SizedBox(width: isMobile ? 6 : 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile || isCompact ? 9 : 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile || isCompact ? 11 : 12,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
