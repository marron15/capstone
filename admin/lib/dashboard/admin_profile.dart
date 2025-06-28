import 'package:flutter/material.dart';
import '../modal/admin_modal.dart';
import '../sidenav.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  // Pre-filled data for the admin profiles table
  final List<Map<String, dynamic>> _admins = [];

  List<Map<String, dynamic>> _filteredAdmins = [];

  TextEditingController searchController = TextEditingController();

  // Add a new admin to the list
  void _addAdmin(Map<String, dynamic> admin) {
    setState(() {
      _admins.add(admin);
      // Update _filteredAdmins to reflect the new admin and current search
      final query = searchController.text.toLowerCase();
      if (query.isEmpty) {
        _filteredAdmins = List.from(_admins);
      } else {
        _filteredAdmins = _admins.where((admin) {
          return admin['firstName'].toLowerCase().contains(query) ||
              admin['lastName'].toLowerCase().contains(query) ||
              admin['email'].toLowerCase().contains(query) ||
              admin['contactNumber'].toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // Remove an admin from the list
  void _removeAdmin(int index) {
    if (index >= 0 && index < _admins.length) {
      setState(() {
        _admins.removeAt(index);
      });
    }
  }

  void _filterAdmins(String query) {
    setState(() {
      _filteredAdmins = _admins.where((admin) {
        final lowerQuery = query.toLowerCase();
        return admin['firstName'].toLowerCase().contains(lowerQuery) ||
            admin['lastName'].toLowerCase().contains(lowerQuery) ||
            admin['email'].toLowerCase().contains(lowerQuery) ||
            admin['contactNumber'].toLowerCase().contains(lowerQuery);
      }).toList();
    });
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
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.blue,
            child: Row(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      prefixIcon:
                          Icon(Icons.search, color: Colors.grey, size: 20),
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
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        color: Colors.blue[50],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Row(
                          children: [
                            Expanded(
                                flex: 2,
                                child: Text('First Name',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                flex: 2,
                                child: Text('Last Name',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                flex: 3,
                                child: Text('Email',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                flex: 3,
                                child: Text('Contact Number',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                flex: 2,
                                child: Text('Password',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            SizedBox(
                                width: 80,
                                child: Text('Actions',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.black26),
                      // Data Rows
                      ..._filteredAdmins.asMap().entries.map((entry) {
                        int index = entry.key;
                        var admin = entry.value;
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    flex: 2, child: Text(admin['firstName'])),
                                Expanded(
                                    flex: 2, child: Text(admin['lastName'])),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    admin['email'],
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ),
                                Expanded(
                                    flex: 3,
                                    child: Text(admin['contactNumber'])),
                                Expanded(
                                    flex: 2, child: Text(admin['password'])),
                                SizedBox(
                                  width: 80,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () {
                                          AdminModal.showEditAdminModal(
                                            context,
                                            admin,
                                            (updatedAdmin) {
                                              setState(() {
                                                _admins[index] = updatedAdmin;
                                                // Also update _filteredAdmins to reflect the change
                                                final query = searchController
                                                    .text
                                                    .toLowerCase();
                                                if (query.isEmpty) {
                                                  _filteredAdmins =
                                                      List.from(_admins);
                                                } else {
                                                  _filteredAdmins =
                                                      _admins.where((admin) {
                                                    return admin['firstName']
                                                            .toLowerCase()
                                                            .contains(query) ||
                                                        admin['lastName']
                                                            .toLowerCase()
                                                            .contains(query) ||
                                                        admin['email']
                                                            .toLowerCase()
                                                            .contains(query) ||
                                                        admin['contactNumber']
                                                            .toLowerCase()
                                                            .contains(query);
                                                  }).toList();
                                                }
                                              });
                                            },
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title:
                                                    const Text('Delete Admin'),
                                                content: const Text(
                                                    'Are you sure you want to delete this admin?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _admins.removeAt(index);
                                                        // Update _filteredAdmins to reflect the change
                                                        final query =
                                                            searchController
                                                                .text
                                                                .toLowerCase();
                                                        if (query.isEmpty) {
                                                          _filteredAdmins =
                                                              List.from(
                                                                  _admins);
                                                        } else {
                                                          _filteredAdmins =
                                                              _admins.where(
                                                                  (admin) {
                                                            return admin[
                                                                        'firstName']
                                                                    .toLowerCase()
                                                                    .contains(
                                                                        query) ||
                                                                admin['lastName']
                                                                    .toLowerCase()
                                                                    .contains(
                                                                        query) ||
                                                                admin['email']
                                                                    .toLowerCase()
                                                                    .contains(
                                                                        query) ||
                                                                admin['contactNumber']
                                                                    .toLowerCase()
                                                                    .contains(
                                                                        query);
                                                          }).toList();
                                                        }
                                                      });
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('Delete',
                                                        style: TextStyle(
                                                            color: Colors.red)),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 1, color: Colors.black12),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
