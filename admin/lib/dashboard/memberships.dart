import 'package:flutter/material.dart';
import '../sidenav.dart';

class MembershipsPage extends StatefulWidget {
  const MembershipsPage({super.key});

  @override
  State<MembershipsPage> createState() => _MembershipsPageState();
}

class _MembershipsPageState extends State<MembershipsPage> {
  // Sample data for memberships with expiration dates
  List<Map<String, dynamic>> _memberships = [
    {
      'name': 'Alice Johnson',
      'contactNumber': '+1 123-456-7890',
      'membershipType': 'Monthly',
      'expirationDate': DateTime.now().add(const Duration(days: 30)),
    },
    {
      'name': 'Bob Smith',
      'contactNumber': '+1 234-567-8901',
      'membershipType': 'Half Month',
      'expirationDate': DateTime.now().add(const Duration(days: 15)),
    },
    {
      'name': 'Charlie Brown',
      'contactNumber': '+1 345-678-9012',
      'membershipType': 'Daily',
      'expirationDate': DateTime.now().add(const Duration(days: 1)),
    },
    {
      'name': 'Diana Prince',
      'contactNumber': '+1 456-789-0123',
      'membershipType': 'Monthly',
      'expirationDate': DateTime.now().add(const Duration(days: 30)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _sortMembershipsByExpiration();
  }

  void _sortMembershipsByExpiration() {
    _memberships.sort((a, b) {
      final DateTime dateA = a['expirationDate'] as DateTime;
      final DateTime dateB = b['expirationDate'] as DateTime;
      return dateA.compareTo(dateB);
    });
  }

  String _getRemainingTime(DateTime expirationDate) {
    final now = DateTime.now();
    final difference = expirationDate.difference(now);

    if (difference.inDays < 0) {
      return 'Expired';
    } else if (difference.inDays == 0) {
      return 'Expires today';
    } else if (difference.inDays == 1) {
      return '1 day remaining';
    } else {
      return '${difference.inDays} days remaining';
    }
  }

  Color _getMembershipTypeColor(String membershipType) {
    switch (membershipType) {
      case 'Daily':
        return Colors.orange;
      case 'Half Month':
        return Colors.blue;
      case 'Monthly':
        return Colors.green;
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const SideNav(),
      appBar: AppBar(
        title: const Text('Membership Management'),
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
                _buildHeaderCell('Membership Type', flex: 3, isBold: true),
                _buildHeaderCell('Time Remaining', flex: 3, isBold: true),
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
                final membership = _memberships[index];
                final expirationDate = membership['expirationDate'] as DateTime;
                final remainingTime = _getRemainingTime(expirationDate);
                final membershipType = membership['membershipType'] as String;

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: remainingTime == 'Expired'
                        ? Colors.red.shade50
                        : Colors.white,
                  ),
                  child: Row(
                    children: [
                      _buildCell(membership['name'] ?? '', flex: 3),
                      _buildCell(membership['contactNumber'] ?? '', flex: 3),
                      _buildCell(
                        membershipType,
                        flex: 3,
                        color: _getMembershipTypeColor(membershipType),
                      ),
                      _buildCell(
                        remainingTime,
                        flex: 3,
                        color: remainingTime == 'Expired'
                            ? Colors.red
                            : Colors.black87,
                      ),
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

  Widget _buildCell(String text, {int flex = 1, Color? color}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: color ?? Colors.black87,
        ),
      ),
    );
  }
}
