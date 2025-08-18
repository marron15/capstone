import 'package:flutter/material.dart';
import '../modal/admin_modal.dart';
import '../sidenav.dart';
import '../card/admin_profile_card.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  // Pre-filled data for the admin profiles
  final List<Map<String, dynamic>> _admins = [];

  List<Map<String, dynamic>> _filteredAdmins = [];

  TextEditingController searchController = TextEditingController();

  // Add a new admin to the list
  void _addAdmin(Map<String, dynamic> admin) {
    setState(() {
      _admins.add(admin);
      _updateFilteredAdmins();
    });
  }

  // Remove an admin from the list
  void _removeAdmin(int index) {
    if (index >= 0 && index < _admins.length) {
      setState(() {
        _admins.removeAt(index);
        _updateFilteredAdmins();
      });
    }
  }

  // Update an admin in the list
  void _updateAdmin(Map<String, dynamic> updatedAdmin) {
    setState(() {
      _updateFilteredAdmins();
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
    if (query.isEmpty) {
      _filteredAdmins = List.from(_admins);
    } else {
      _filteredAdmins = _admins.where((admin) {
        return admin['firstName'].toLowerCase().contains(query) ||
            (admin['middleName'] != null &&
                admin['middleName'].toLowerCase().contains(query)) ||
            admin['lastName'].toLowerCase().contains(query) ||
            admin['email'].toLowerCase().contains(query) ||
            admin['contactNumber'].toLowerCase().contains(query) ||
            (admin['dateOfBirth'] != null &&
                admin['dateOfBirth'].toLowerCase().contains(query));
      }).toList();
    }
  }

  // Update filtered admins from external source (like AdminProfileCard)
  void _setFilteredAdmins(List<Map<String, dynamic>> filteredList) {
    setState(() {
      _filteredAdmins = filteredList;
    });
  }

  // Responsive grid layout for desktop
  Widget _buildDesktopGrid() {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate optimal card width and number of columns
    const double minCardWidth = 300.0;
    const double cardSpacing = 16.0;
    const double horizontalPadding = 32.0;

    final availableWidth = screenWidth - horizontalPadding;

    // Ensure we don't divide by zero and have reasonable limits
    if (availableWidth <= minCardWidth) {
      // If screen is too narrow, use single column
      return Column(
        children: _filteredAdmins.asMap().entries.map((entry) {
          int index = entry.key;
          var admin = entry.value;
          return AdminProfileCard(
            admin: admin,
            index: index,
            onEdit: _updateAdmin,
            onDelete: _removeAdmin,
            searchController: searchController,
            admins: _admins,
            updateFilteredAdmins: _setFilteredAdmins,
          );
        }).toList(),
      );
    }

    final maxColumns = (availableWidth / (minCardWidth + cardSpacing)).floor();
    final crossAxisCount = maxColumns.clamp(1, 3);

    // Use a fixed aspect ratio that works well for most cases
    const double aspectRatio = 2.8;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: cardSpacing,
            mainAxisSpacing: cardSpacing,
          ),
          itemCount: _filteredAdmins.length,
          itemBuilder: (context, index) {
            return AdminProfileCard(
              admin: _filteredAdmins[index],
              index: index,
              onEdit: _updateAdmin,
              onDelete: _removeAdmin,
              searchController: searchController,
              admins: _admins,
              updateFilteredAdmins: _setFilteredAdmins,
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _filteredAdmins = List.from(_admins);
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
      backgroundColor: Colors.white,
      drawer: const SideNav(),
      appBar: AppBar(
        title: const Text('Admin Profiles'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: isMobile ? 100 : 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.blue,
            child: isMobile
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
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
                                  horizontal: 16, vertical: 8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 16),
                                SizedBox(width: 4),
                                Text('new admin',
                                    style: TextStyle(fontSize: 14)),
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
                            prefixIcon: Icon(Icons.search,
                                color: Colors.grey, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
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
                              horizontal: 16, vertical: 8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 16),
                            SizedBox(width: 4),
                            Text('new admin', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      const Spacer(),
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
                            prefixIcon: Icon(Icons.search,
                                color: Colors.grey, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _filteredAdmins.isEmpty
                  ? Card(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          children: [
                            Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No admins found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              searchController.text.isNotEmpty
                                  ? 'Try adjusting your search criteria'
                                  : 'Add your first admin to get started',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : isMobile
                      ? Column(
                          children:
                              _filteredAdmins.asMap().entries.map((entry) {
                            int index = entry.key;
                            var admin = entry.value;
                            return AdminProfileCard(
                              admin: admin,
                              index: index,
                              onEdit: _updateAdmin,
                              onDelete: _removeAdmin,
                              searchController: searchController,
                              admins: _admins,
                              updateFilteredAdmins: _setFilteredAdmins,
                            );
                          }).toList(),
                        )
                      : _buildDesktopGrid(),
            ),
          ),
        ],
      ),
    );
  }
}
