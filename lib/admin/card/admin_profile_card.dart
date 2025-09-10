import 'package:flutter/material.dart';
import '../modal/admin_modal.dart';
import '../services/admin_service.dart';

/// AdminProfileTable widget for displaying admin information in a table format
class AdminProfileTable extends StatelessWidget {
  final Map<String, dynamic> admin;
  final int index;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;
  final TextEditingController searchController;
  final List<Map<String, dynamic>> admins;
  final Function(List<Map<String, dynamic>>) updateFilteredAdmins;

  const AdminProfileTable({
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

    if (isMobile) {
      return _buildMobileTableRow(context);
    } else {
      return _buildDesktopTableRow(context);
    }
  }

  // Mobile table row (stacked layout)
  Widget _buildMobileTableRow(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with name and actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFullName(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Text(
                          'Administrator',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildActionButtons(context, true),
              ],
            ),
            const SizedBox(height: 12),
            // Info rows
            _buildInfoRow(
                'Email',
                admin['email_address'] ?? admin['email'] ?? 'N/A',
                Icons.email_outlined,
                Colors.blue),
            const SizedBox(height: 8),
            _buildInfoRow(
                'Contact',
                admin['phone_number'] ?? admin['contactNumber'] ?? 'N/A',
                Icons.phone_outlined,
                Colors.green),
            const SizedBox(height: 8),
            _buildInfoRow(
                'Date of Birth',
                admin['date_of_birth'] ?? admin['dateOfBirth'] ?? 'N/A',
                Icons.cake_outlined,
                Colors.purple),
            const SizedBox(height: 8),
            _buildInfoRow(
                'Status', 'Active', Icons.check_circle_outline, Colors.green),
          ],
        ),
      ),
    );
  }

  // Desktop table row
  Widget _buildDesktopTableRow(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          right: BorderSide(color: Colors.grey.shade200, width: 0.5),
          left: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Name column
            Expanded(
              flex: 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      _getInitials(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getFullName(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Text(
                            'Administrator',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Email column
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  admin['email_address'] ?? admin['email'] ?? 'N/A',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Contact column
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  admin['phone_number'] ?? admin['contactNumber'] ?? 'N/A',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Date of Birth column
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  admin['date_of_birth'] ?? admin['dateOfBirth'] ?? 'N/A',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Status column
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Actions column
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: _buildActionButtons(context, false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Info row for mobile view
  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Action buttons
  Widget _buildActionButtons(BuildContext context, bool isMobile) {
    final size = isMobile ? 32.0 : 28.0;
    final iconSize = isMobile ? 16.0 : 14.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: IconButton(
            onPressed: () => _handleEdit(context),
            icon: Icon(Icons.edit_outlined,
                size: iconSize, color: Colors.blue.shade700),
            padding: EdgeInsets.all(isMobile ? 8 : 4),
            constraints: BoxConstraints(minWidth: size, minHeight: size),
            tooltip: 'Edit Admin',
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: IconButton(
            onPressed: () => _handleDelete(context),
            icon: Icon(Icons.delete_outline,
                size: iconSize, color: Colors.red.shade700),
            padding: EdgeInsets.all(isMobile ? 8 : 4),
            constraints: BoxConstraints(minWidth: size, minHeight: size),
            tooltip: 'Delete Admin',
          ),
        ),
      ],
    );
  }

  // Get full name
  String _getFullName() {
    List<String> nameParts = [];

    final firstName = admin['first_name'] ?? admin['firstName'];
    if (firstName != null && firstName.toString().trim().isNotEmpty) {
      nameParts.add(firstName.toString().trim());
    }

    final middleName = admin['middle_name'] ?? admin['middleName'];
    if (middleName != null && middleName.toString().trim().isNotEmpty) {
      nameParts.add(middleName.toString().trim());
    }

    final lastName = admin['last_name'] ?? admin['lastName'];
    if (lastName != null && lastName.toString().trim().isNotEmpty) {
      nameParts.add(lastName.toString().trim());
    }

    String fullName = nameParts.join(' ');
    return fullName.isEmpty ? 'Unknown Admin' : fullName;
  }

  // Get initials for avatar
  String _getInitials() {
    final firstName = admin['first_name'] ?? admin['firstName'] ?? '';
    final lastName = admin['last_name'] ?? admin['lastName'] ?? '';

    String firstInitial =
        firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';

    return '$firstInitial$lastInitial';
  }

  // Handle edit functionality
  void _handleEdit(BuildContext context) {
    AdminModal.showEditAdminModal(
      context,
      admin,
      (updatedAdmin) {
        final adminIndex = admins.indexWhere((a) => a['id'] == admin['id']);
        if (adminIndex != -1) {
          admins[adminIndex] = updatedAdmin;
        }

        onEdit(updatedAdmin);
        _updateFilteredList();

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                Navigator.of(context).pop();

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
                  final adminId = admin['id'];
                  final success = await AdminService.deleteAdmin(adminId);

                  if (!context.mounted) return;

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('$firstName $lastName deleted successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    onDelete(index);
                    _updateFilteredList();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete admin'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;

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
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Update filtered admins list
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
}
