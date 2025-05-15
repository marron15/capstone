import 'package:flutter/material.dart';
import '../modal/admin_modal.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  // Pre-filled data for the admin profiles table
  List<Map<String, dynamic>> _admins = [
    {
      'firstName': 'John',
      'lastName': 'Doe',
      'email': 'john.doe@example.com',
      'contactNumber': '+1 123-456-7890',
      'password': '********'
    },
    {
      'firstName': 'Jane',
      'lastName': 'Smith',
      'email': 'jane.smith@example.com',
      'contactNumber': '+1 234-567-8901',
      'password': '********'
    },
    {
      'firstName': 'Michael',
      'lastName': 'Johnson',
      'email': 'michael.j@example.com',
      'contactNumber': '+1 345-678-9012',
      'password': '********'
    },
    {
      'firstName': 'Emily',
      'lastName': 'Williams',
      'email': 'emily.w@example.com',
      'contactNumber': '+1 456-789-0123',
      'password': '********'
    },
    {
      'firstName': 'Robert',
      'lastName': 'Brown',
      'email': 'robert.b@example.com',
      'contactNumber': '+1 567-890-1234',
      'password': '********'
    },
    {
      'firstName': 'Sarah',
      'lastName': 'Davis',
      'email': 'sarah.d@example.com',
      'contactNumber': '+1 678-901-2345',
      'password': '********'
    },
    {
      'firstName': 'David',
      'lastName': 'Miller',
      'email': 'david.m@example.com',
      'contactNumber': '+1 789-012-3456',
      'password': '********'
    },
    {
      'firstName': 'Jennifer',
      'lastName': 'Wilson',
      'email': 'jennifer.w@example.com',
      'contactNumber': '+1 890-123-4567',
      'password': '********'
    },
    {
      'firstName': 'James',
      'lastName': 'Taylor',
      'email': 'james.t@example.com',
      'contactNumber': '+1 901-234-5678',
      'password': '********'
    },
    {
      'firstName': 'Lisa',
      'lastName': 'Anderson',
      'email': 'lisa.a@example.com',
      'contactNumber': '+1 012-345-6789',
      'password': '********'
    },
  ];

  // Index of highlighted rows
  final List<int> _highlightedRows = [2, 4, 6]; // Michael, Robert, David

  TextEditingController searchController = TextEditingController();

  // Add a new admin to the list
  void _addAdmin(Map<String, dynamic> admin) {
    setState(() {
      _admins.add(admin);
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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Admin Profiles'),
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.black12, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                _buildHeaderCell('First Name', flex: 3),
                _buildHeaderCell('Last Name', flex: 3),
                _buildHeaderCell('Email', flex: 5),
                _buildHeaderCell('Contact Number', flex: 3),
                _buildHeaderCell('Password', flex: 2),
                _buildHeaderCell('Actions', flex: 2),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _admins.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, thickness: 1, color: Colors.black12),
              itemBuilder: (context, index) {
                bool isHighlighted = _highlightedRows.contains(index);
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      _buildCell(_admins[index]['firstName'],
                          flex: 3, isHighlighted: isHighlighted),
                      _buildCell(_admins[index]['lastName'],
                          flex: 3, isHighlighted: isHighlighted),
                      _buildEmailCell(_admins[index]['email'], flex: 5),
                      _buildCell(_admins[index]['contactNumber'],
                          flex: 3, isHighlighted: isHighlighted),
                      _buildPasswordCell(_admins[index]['password'], flex: 2),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 18, color: Colors.blue),
                              onPressed: () {
                                // Edit admin functionality would go here
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 18, color: Colors.red),
                              onPressed: () {
                                _removeAdmin(index);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCell(String text, {int flex = 1, bool isHighlighted = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: isHighlighted ? Colors.black87 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEmailCell(String email, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        email,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildPasswordCell(String password, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        password,
        style: const TextStyle(
          fontSize: 14,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
