import 'package:flutter/material.dart';
import '../modal/admin_modal.dart';
import '../sidenav.dart';
import '../card/admin_profile_card.dart' show AdminProfileTable;
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

  TextEditingController searchController = TextEditingController();

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

    // 1) Start from status-filtered list
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
            final email =
                (admin['email_address'] ?? admin['email'] ?? '')
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
                email.contains(query) ||
                phone.contains(query) ||
                dateOfBirth.contains(query);
          }).toList();
    }
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 15,
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
                        fontSize: 15,
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
                        fontSize: 15,
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
                        fontSize: 15,
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
                        fontSize: 15,
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const SideNav(),
      appBar: AppBar(
        title: const Center(child: Text('Admin Profiles')),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF36454F),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAdmins,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141E30), Color(0xFF232526)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: isMobile ? 100 : 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.transparent,
              child:
                  isMobile
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  AdminModal.showAddAdminModal(
                                    context,
                                    _addAdmin,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'new admin',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: TextField(
                              controller: searchController,
                              onChanged: _filterAdmins,
                              decoration: const InputDecoration(
                                hintText: 'Search admins...',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      )
                      : Row(
                        children: [
                          // Add new admin (left side)
                          ElevatedButton(
                            onPressed: () {
                              AdminModal.showAddAdminModal(context, _addAdmin);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'new admin',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Archived/Active toggle to the left of search
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showArchived = !_showArchived;
                                _updateFilteredAdmins();
                              });
                            },
                            icon: Icon(
                              _showArchived ? Icons.people : Icons.archive,
                              size: 16,
                            ),
                            label: Text(
                              _showArchived
                                  ? 'Active Admins'
                                  : 'Archived Admins',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _showArchived
                                      ? Colors.green
                                      : Colors.grey[600],
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 220,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: TextField(
                              controller: searchController,
                              onChanged: _filterAdmins,
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                            ),
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
                                ? Card(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(48),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.admin_panel_settings_outlined,
                                          size: 64,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No admins found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          searchController.text.isNotEmpty
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
                                )
                                : isMobile
                                ? Column(
                                  children:
                                      _filteredAdmins.asMap().entries.map((
                                        entry,
                                      ) {
                                        int index = entry.key;
                                        var admin = entry.value;
                                        return AdminProfileTable(
                                          admin: admin,
                                          index: index,
                                          onEdit: _updateAdmin,
                                          onDelete: _removeAdmin,
                                          searchController: searchController,
                                          admins: _admins,
                                          updateFilteredAdmins:
                                              _setFilteredAdmins,
                                        );
                                      }).toList(),
                                )
                                : _buildDesktopTable(),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
