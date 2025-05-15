import 'package:flutter/material.dart';
import '../sidenav.dart';

class MembershipsPage extends StatefulWidget {
  const MembershipsPage({super.key});

  @override
  State<MembershipsPage> createState() => _MembershipsPageState();
}

class _MembershipsPageState extends State<MembershipsPage> {
  // Sample data for memberships
  List<Map<String, String>> _memberships = [
    {
      'name': 'Alice Johnson',
      'contactNumber': '+1 123-456-7890',
      'duration': '1 Month',
    },
    {
      'name': 'Bob Smith',
      'contactNumber': '+1 234-567-8901',
      'duration': '3 Months',
    },
    {
      'name': 'Charlie Brown',
      'contactNumber': '+1 345-678-9012',
      'duration': '6 Months',
    },
    {
      'name': 'Diana Prince',
      'contactNumber': '+1 456-789-0123',
      'duration': '1 Year',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const SideNav(),
      appBar: AppBar(
        title: const Text('Memberships'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F2),
              border: Border(
                bottom: BorderSide(color: Colors.black12, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                _buildHeaderCell('Name', flex: 3),
                _buildHeaderCell('Contact Number', flex: 3),
                _buildHeaderCell('Membership Duration', flex: 3, isBold: true),
                _buildHeaderCell('View Profile', flex: 2, isBold: true),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _memberships.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, thickness: 1, color: Colors.black12),
              itemBuilder: (context, index) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      _buildCell(_memberships[index]['name'] ?? '', flex: 3),
                      _buildCell(_memberships[index]['contactNumber'] ?? '',
                          flex: 3),
                      _buildCell(_memberships[index]['duration'] ?? '',
                          flex: 3),
                      Expanded(
                        flex: 2,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement view profile functionality
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue.shade50,
                            foregroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: const Text('View'),
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

  Widget _buildHeaderCell(String text, {int flex = 1, bool isBold = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }
}
