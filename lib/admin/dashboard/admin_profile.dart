import 'package:flutter/material.dart';
import '../excel/excel_admin_export.dart';
import '../modal/admin_modal.dart';
import '../sidenav.dart';
import 'package:capstone/admin/card/admin_profile_card.dart'
    show AdminProfileTable;
import '../services/admin_service.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  // Admin data from API
  final List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _filteredAdmins = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showArchived = false;
  static const double _drawerWidth = 280;
  bool _navCollapsed = false;

  TextEditingController searchController = TextEditingController();

  Widget _buildArchiveEmpty({
    required String title,
    required String helper,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.black.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              helper,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.people_outline, size: 18),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFF3FF),
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  // Load admins from API
  Future<void> _loadAdmins() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final admins = await AdminService.getAllAdmins();
      setState(() {
        _admins.clear();
        _admins.addAll(admins);
        _updateFilteredAdmins();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load admins: $e';
        _isLoading = false;
      });
    }
  }

  // Add a new admin to the list
  Future<void> _addAdmin(Map<String, dynamic> admin) async {
    // Show success first for instant feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Admin ${admin['first_name'] ?? admin['firstName']} added successfully!',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // Immediately refresh from backend to reflect canonical data (e.g., img_url)
    setState(() {
      _isLoading = true;
    });
    await _loadAdmins();
  }

  // Remove an admin from the list
  Future<void> _removeAdmin(int index) async {
    if (index >= 0 && index < _admins.length) {
      final admin = _admins[index];
      final adminId = admin['id'];

      if (adminId != null) {
        final success = await AdminService.deleteAdmin(adminId);

        // Check if widget is still mounted before using context
        if (!mounted) return;

        if (success) {
          setState(() {
            _admins.removeAt(index);
            _updateFilteredAdmins();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Admin ${admin['first_name'] ?? admin['firstName']} deleted successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete admin'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Update an admin in the list
  void _updateAdmin(Map<String, dynamic> updatedAdmin) {
    setState(() {
      // Find and update the admin in the list
      final index = _admins.indexWhere(
        (admin) => admin['id'] == updatedAdmin['id'],
      );
      if (index != -1) {
        _admins[index] = updatedAdmin;
        _updateFilteredAdmins();
      }
    });
  }

  // Filter admins based on search query
  void _filterAdmins(String query) {
    setState(() {
      _updateFilteredAdmins();
    });
  }

  // Update filtered admins list
  void _updateFilteredAdmins() {
    final query = searchController.text.toLowerCase();

    // 1) Start from status-filtered list via toggle
    final List<Map<String, dynamic>> statusScoped =
        _admins.where((admin) {
          final String status =
              (admin['status'] ?? 'active').toString().toLowerCase().trim();
          return _showArchived ? status == 'inactive' : status != 'inactive';
        }).toList();

    // 2) Apply search filter on top
    if (query.isEmpty) {
      _filteredAdmins = statusScoped;
    } else {
      _filteredAdmins =
          statusScoped.where((admin) {
            final firstName =
                (admin['first_name'] ?? admin['firstName'] ?? '')
                    .toString()
                    .toLowerCase();
            final middleName =
                (admin['middle_name'] ?? admin['middleName'] ?? '')
                    .toString()
                    .toLowerCase();
            final lastName =
                (admin['last_name'] ?? admin['lastName'] ?? '')
                    .toString()
                    .toLowerCase();
            final phone =
                (admin['phone_number'] ?? admin['contactNumber'] ?? '')
                    .toString()
                    .toLowerCase();
            final dateOfBirth =
                (admin['date_of_birth'] ?? admin['dateOfBirth'] ?? '')
                    .toString()
                    .toLowerCase();

            return firstName.contains(query) ||
                middleName.contains(query) ||
                lastName.contains(query) ||
                phone.contains(query) ||
                dateOfBirth.contains(query);
          }).toList();
    }
  }

  // Recompute filters and trigger UI update
  void _recomputeFilters() {
    setState(() {
      _updateFilteredAdmins();
    });
  }

  // Update filtered admins from external source (like AdminProfileTable)
  void _setFilteredAdmins(List<Map<String, dynamic>> filteredList) {
    setState(() {
      _filteredAdmins = filteredList;
    });
  }

  // Refresh admins from API
  Future<void> _refreshAdmins() async {
    await _loadAdmins();
  }

  // Export admins to Excel
  Future<void> _exportAdmins() async {
    await exportAdminsToExcel(context, _filteredAdmins);
  }

  // Table layout for desktop
  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Name & Role',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Date of Birth',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table rows
          ..._filteredAdmins.asMap().entries.map((entry) {
            int index = entry.key;
            var admin = entry.value;
            return AdminProfileTable(
              admin: admin,
              index: index,
              onEdit: _updateAdmin,
              onDelete: _removeAdmin,
              searchController: searchController,
              admins: _admins,
              updateFilteredAdmins: _setFilteredAdmins,
              recomputeFilters: _recomputeFilters,
            );
          }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    const Color hoverAccent = Color(0xFFFFA812);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: _navCollapsed ? 0 : _drawerWidth,
              child: SideNav(
                width: _drawerWidth,
                onClose: () => setState(() => _navCollapsed = true),
              ),
            ),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: const BoxDecoration(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox.shrink(),
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.transparent,
                      child:
                          isMobile
                              ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // First row with Export and View Archives buttons
                                  Row(
                                    children: [
                                      // Export
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _exportAdmins,
                                          icon: const Icon(
                                            Icons.table_view,
                                            size: 16,
                                          ),
                                          label: const Text('Export'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black87,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ).copyWith(
                                            side:
                                                WidgetStateProperty.resolveWith(
                                                  (states) => BorderSide(
                                                    color:
                                                        states.contains(
                                                              WidgetState
                                                                  .hovered,
                                                            )
                                                            ? hoverAccent
                                                            : Colors.black26,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // View Archives toggle
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _showArchived = !_showArchived;
                                              _updateFilteredAdmins();
                                            });
                                          },
                                          icon: Icon(
                                            _showArchived
                                                ? Icons.people
                                                : Icons.archive,
                                            size: 16,
                                          ),
                                          label: Text(
                                            _showArchived
                                                ? 'View Active'
                                                : 'View Archives',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black87,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ).copyWith(
                                            side:
                                                WidgetStateProperty.resolveWith(
                                                  (states) => BorderSide(
                                                    color:
                                                        states.contains(
                                                              WidgetState
                                                                  .hovered,
                                                            )
                                                            ? hoverAccent
                                                            : Colors.black26,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Second row with New Admin button
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            AdminModal.showAddAdminModal(
                                              context,
                                              _addAdmin,
                                            );
                                          },
                                          icon: const Icon(Icons.add, size: 16),
                                          label: const Text('New Admin'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.blue,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ).copyWith(
                                            side:
                                                WidgetStateProperty.resolveWith(
                                                  (states) => BorderSide(
                                                    color:
                                                        states.contains(
                                                              WidgetState
                                                                  .hovered,
                                                            )
                                                            ? hoverAccent
                                                            : Colors.black26,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                              : Column(
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip:
                                            _navCollapsed
                                                ? 'Open Sidebar'
                                                : 'Close Sidebar',
                                        onPressed:
                                            () => setState(
                                              () =>
                                                  _navCollapsed =
                                                      !_navCollapsed,
                                            ),
                                        icon: Icon(
                                          _navCollapsed
                                              ? Icons.menu
                                              : Icons.chevron_left,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Admin Profiles',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      // Search box (match customers.dart styling)
                                      SizedBox(
                                        width: 560,
                                        height: 42,
                                        child: TextField(
                                          controller: searchController,
                                          onChanged: _filterAdmins,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Search',
                                            prefixIcon: const Icon(
                                              Icons.search,
                                              size: 20,
                                              color: Colors.black54,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.black26,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 0,
                                                ),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Export button styled like customers page
                                      OutlinedButton.icon(
                                        onPressed: _exportAdmins,
                                        icon: const Icon(
                                          Icons.table_chart_rounded,
                                          color: Colors.teal,
                                          size: 20,
                                        ),
                                        label: const Text('Export'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.black87,
                                          side: const BorderSide(
                                            color: Colors.black26,
                                          ),
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                        ).copyWith(
                                          side: WidgetStateProperty.resolveWith(
                                            (states) => BorderSide(
                                              color:
                                                  states.contains(
                                                        WidgetState.hovered,
                                                      )
                                                      ? hoverAccent
                                                      : Colors.black26,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      // View archives pill button
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _showArchived = !_showArchived;
                                            _updateFilteredAdmins();
                                          });
                                        },
                                        icon: Icon(
                                          _showArchived
                                              ? Icons.people
                                              : Icons.archive,
                                          size: 18,
                                        ),
                                        label: Text(
                                          _showArchived
                                              ? 'View Active'
                                              : 'View Archives',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.black87,
                                          side: const BorderSide(
                                            color: Colors.black26,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                        ).copyWith(
                                          side: WidgetStateProperty.resolveWith(
                                            (states) => BorderSide(
                                              color:
                                                  states.contains(
                                                        WidgetState.hovered,
                                                      )
                                                      ? hoverAccent
                                                      : Colors.black26,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // New Admin pill button
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          AdminModal.showAddAdminModal(
                                            context,
                                            _addAdmin,
                                          );
                                        },
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('New Admin'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black87,
                                          elevation: 1,
                                          side: const BorderSide(
                                            color: Colors.black26,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                        ).copyWith(
                                          side: WidgetStateProperty.resolveWith(
                                            (states) => BorderSide(
                                              color:
                                                  states.contains(
                                                        WidgetState.hovered,
                                                      )
                                                      ? hoverAccent
                                                      : Colors.black26,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                    ),
                    Expanded(
                      child:
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _errorMessage != null
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: Colors.red[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error loading admins',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.red[300],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _refreshAdmins,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                              : SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child:
                                    _filteredAdmins.isEmpty
                                        ? (_showArchived
                                            ? _buildArchiveEmpty(
                                              title: 'No archived admins',
                                              helper:
                                                  'Archived admins will appear here',
                                              actionLabel: 'View Active Admins',
                                              onAction: () {
                                                setState(
                                                  () => _showArchived = false,
                                                );
                                                _updateFilteredAdmins();
                                              },
                                            )
                                            : Card(
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  48,
                                                ),
                                                child: Column(
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .admin_panel_settings_outlined,
                                                      size: 64,
                                                      color: Colors.white70,
                                                    ),
                                                    const SizedBox(height: 16),
                                                    const Text(
                                                      'No admins found',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        color: Colors.white70,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      searchController
                                                              .text
                                                              .isNotEmpty
                                                          ? 'Try adjusting your search criteria'
                                                          : 'Add your first admin to get started',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white60,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ))
                                        : isMobile
                                        ? Column(
                                          children:
                                              _filteredAdmins
                                                  .asMap()
                                                  .entries
                                                  .map((entry) {
                                                    int index = entry.key;
                                                    var admin = entry.value;
                                                    return AdminProfileTable(
                                                      admin: admin,
                                                      index: index,
                                                      onEdit: _updateAdmin,
                                                      onDelete: _removeAdmin,
                                                      searchController:
                                                          searchController,
                                                      admins: _admins,
                                                      updateFilteredAdmins:
                                                          _setFilteredAdmins,
                                                      recomputeFilters:
                                                          _recomputeFilters,
                                                    );
                                                  })
                                                  .toList(),
                                        )
                                        : (_showArchived &&
                                                _filteredAdmins.isEmpty
                                            ? _buildArchiveEmpty(
                                              title: 'No archived admins',
                                              helper:
                                                  'Archived admins will appear here',
                                              actionLabel: 'View Active Admins',
                                              onAction: () {
                                                setState(
                                                  () => _showArchived = false,
                                                );
                                                _updateFilteredAdmins();
                                              },
                                            )
                                            : _buildDesktopTable()),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
