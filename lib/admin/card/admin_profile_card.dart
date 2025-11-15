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
  final VoidCallback recomputeFilters;
  final VoidCallback? onRefresh;

  const AdminProfileTable({
    super.key,
    required this.admin,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.searchController,
    required this.admins,
    required this.updateFilteredAdmins,
    required this.recomputeFilters,
    this.onRefresh,
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

  Widget _buildIdChip(String idText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F0FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Text(
        '#$idText',
        style: const TextStyle(
          color: Color(0xFF1976D2),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _extractDigits(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int codeUnit in input.codeUnits) {
      if (codeUnit >= 48 && codeUnit <= 57) {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  String _formatPhoneDisplay(String input) {
    final String digits = _extractDigits(input);
    if (digits.isEmpty) return 'N/A';
    final String part1 = digits.substring(0, digits.length.clamp(0, 4));
    final String part2 =
        digits.length > 4 ? digits.substring(4, digits.length.clamp(4, 7)) : '';
    final String part3 =
        digits.length > 7
            ? digits.substring(7, digits.length.clamp(7, 11))
            : '';
    final List<String> parts =
        [part1, part2, part3].where((p) => p.isNotEmpty).toList();
    return parts.join(' ');
  }

  // Mobile table row (stacked layout)
  Widget _buildMobileTableRow(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with name and actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ID chip
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'ID: ' +
                              (admin['id'] ??
                                      admin['admin_id'] ??
                                      admin['adminId'] ??
                                      '0')
                                  .toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _getFullName(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Text(
                          'Administrator',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionButtons(context, true),
              ],
            ),
            const SizedBox(height: 20),
            // Info grid - 2 cards centered for good balance
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Contact card
                Expanded(
                  flex: 1,
                  child: _buildInfoCard(
                    'Contact',
                    _formatPhoneDisplay(
                      (admin['phone_number'] ?? admin['contactNumber'] ?? '')
                          .toString(),
                    ),
                    Icons.phone_outlined,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                // Status card
                Expanded(
                  flex: 1,
                  child: _buildInfoCard(
                    'Status',
                    (admin['status'] ?? 'active').toString().toLowerCase() ==
                            'inactive'
                        ? 'Inactive'
                        : 'Active',
                    (admin['status'] ?? 'active').toString().toLowerCase() ==
                            'inactive'
                        ? Icons.archive_outlined
                        : Icons.check_circle_outline,
                    (admin['status'] ?? 'active').toString().toLowerCase() ==
                            'inactive'
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
              ],
            ),
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
            // ID column
            SizedBox(
              width: 80,
              child: Center(
                child: _buildIdChip(
                  (admin['id'] ?? admin['admin_id'] ?? admin['adminId'] ?? '0')
                      .toString(),
                ),
              ),
            ),
            // Name column
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          _getInitials(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getFullName(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
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
                    ],
                  ),
                ),
              ),
            ),
            // Contact column
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildPhoneNumberButton(
                  _formatPhoneDisplay(
                    (admin['phone_number'] ?? admin['contactNumber'] ?? '')
                        .toString(),
                  ),
                ),
              ),
            ),
            // Email column
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  admin['email_address'] ?? admin['email'] ?? 'N/A',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (admin['status'] ?? 'active')
                                      .toString()
                                      .toLowerCase() ==
                                  'inactive'
                              ? Colors.orange.shade50
                              : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            (admin['status'] ?? 'active')
                                        .toString()
                                        .toLowerCase() ==
                                    'inactive'
                                ? Colors.orange.shade200
                                : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color:
                                (admin['status'] ?? 'active')
                                            .toString()
                                            .toLowerCase() ==
                                        'inactive'
                                    ? Colors.orange.shade600
                                    : Colors.green.shade600,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (admin['status'] ?? 'active')
                                      .toString()
                                      .toLowerCase() ==
                                  'inactive'
                              ? 'Inactive'
                              : 'Active',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                (admin['status'] ?? 'active')
                                            .toString()
                                            .toLowerCase() ==
                                        'inactive'
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700,
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
                child: Center(child: _buildActionButtons(context, false)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Info card for mobile view (balanced layout)
  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 80, // Increased height to prevent overflow
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Action buttons
  Widget _buildActionButtons(BuildContext context, bool isMobile) {
    final size = isMobile ? 40.0 : 36.0;
    final iconSize = isMobile ? 20.0 : 18.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => _handleEdit(context),
            icon: Icon(
              Icons.edit_outlined,
              size: iconSize,
              color: Colors.blue.shade700,
            ),
            padding: const EdgeInsets.all(8),
            constraints: BoxConstraints(minWidth: size, minHeight: size),
            tooltip: 'Edit Admin',
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color:
                (admin['status'] ?? 'active').toString().toLowerCase() ==
                        'inactive'
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  (admin['status'] ?? 'active').toString().toLowerCase() ==
                          'inactive'
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: ((admin['status'] ?? 'active')
                                .toString()
                                .toLowerCase() ==
                            'inactive'
                        ? Colors.green
                        : Colors.orange)
                    .withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => _handleArchiveRestore(context),
            icon: Icon(
              (admin['status'] ?? 'active').toString().toLowerCase() ==
                      'inactive'
                  ? Icons.settings_backup_restore_rounded
                  : Icons.archive_outlined,
              size: iconSize,
              color:
                  (admin['status'] ?? 'active').toString().toLowerCase() ==
                          'inactive'
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
            ),
            padding: const EdgeInsets.all(8),
            constraints: BoxConstraints(minWidth: size, minHeight: size),
            tooltip:
                (admin['status'] ?? 'active').toString().toLowerCase() ==
                        'inactive'
                    ? 'Restore Admin'
                    : 'Archive Admin',
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
    AdminModal.showEditAdminModal(context, admin, (updatedAdmin) {
      final adminIndex = admins.indexWhere((a) => a['id'] == admin['id']);
      if (adminIndex != -1) {
        admins[adminIndex] = updatedAdmin;
      }

      onEdit(updatedAdmin);
      recomputeFilters();

      final firstName =
          updatedAdmin['first_name'] ?? updatedAdmin['firstName'] ?? 'Admin';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$firstName updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  // Handle archive/restore functionality
  void _handleArchiveRestore(BuildContext context) {
    final firstName = admin['first_name'] ?? admin['firstName'] ?? 'Unknown';
    final lastName = admin['last_name'] ?? admin['lastName'] ?? 'Admin';
    final bool isInactive =
        (admin['status'] ?? 'active').toString().toLowerCase() == 'inactive';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isInactive
                    ? Icons.settings_backup_restore_rounded
                    : Icons.archive_outlined,
                color:
                    isInactive ? Colors.green.shade600 : Colors.orange.shade600,
              ),
              const SizedBox(width: 12),
              Text(isInactive ? 'Restore Admin' : 'Archive Admin'),
            ],
          ),
          content: Text(
            isInactive
                ? 'Restore $firstName $lastName to active?'
                : 'Archive $firstName $lastName? You can restore this later.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Store original status for rollback if needed
                final String originalStatus = admin['status'] ?? 'active';

                // Update UI instantly (optimistic update)
                admin['status'] = isInactive ? 'active' : 'inactive';

                // Update the admin in the parent list immediately
                final adminIndex = admins.indexWhere(
                  (a) => a['id'] == admin['id'],
                );
                if (adminIndex != -1) {
                  admins[adminIndex] = Map<String, dynamic>.from(admin);
                }

                // Trigger UI update immediately
                onEdit(admin);
                recomputeFilters();

                // Show success message immediately
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isInactive
                            ? '$firstName $lastName restored successfully!'
                            : '$firstName $lastName archived successfully!',
                      ),
                      backgroundColor:
                          isInactive ? Colors.green : Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }

                // Make API call in the background
                try {
                  final adminId = admin['id'];
                  final bool success =
                      isInactive
                          ? await AdminService.restoreAdmin(adminId)
                          : await AdminService.deleteAdmin(adminId);

                  if (!context.mounted) return;

                  if (!success) {
                    // Rollback on failure
                    admin['status'] = originalStatus;
                    final adminIndex = admins.indexWhere(
                      (a) => a['id'] == admin['id'],
                    );
                    if (adminIndex != -1) {
                      admins[adminIndex] = Map<String, dynamic>.from(admin);
                    }
                    onEdit(admin);
                    recomputeFilters();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isInactive
                              ? 'Failed to restore admin'
                              : 'Failed to archive admin',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    // Refresh the admin list from API in the background to sync
                    if (onRefresh != null) {
                      onRefresh!();
                    }
                  }
                } catch (e) {
                  if (!context.mounted) return;

                  // Rollback on error
                  admin['status'] = originalStatus;
                  final adminIndex = admins.indexWhere(
                    (a) => a['id'] == admin['id'],
                  );
                  if (adminIndex != -1) {
                    admins[adminIndex] = Map<String, dynamic>.from(admin);
                  }
                  onEdit(admin);
                  recomputeFilters();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isInactive ? Colors.green.shade600 : Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(isInactive ? 'Restore' : 'Archive'),
            ),
          ],
        );
      },
    );
  }

  // Build styled phone number button for desktop view
  Widget _buildPhoneNumberButton(String phoneNumber) {
    if (phoneNumber == 'N/A' || phoneNumber.isEmpty) {
      return Center(
        child: Text(
          'N/A',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E8), // Light green background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.phone,
              size: 16,
              color: const Color(0xFF2E7D32), // Darker green icon
            ),
            const SizedBox(width: 6),
            Text(
              phoneNumber,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2E7D32), // Darker green text
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Filtering recomputed in parent via recomputeFilters
}
