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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            // Mobile layout: vertical cards for each membership
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._memberships.map((membership) {
                  final expirationDate =
                      membership['expirationDate'] as DateTime;
                  final remainingTime = _getRemainingTime(expirationDate);
                  final membershipType = membership['membershipType'] as String;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                membership['name'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              TextButton(
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
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            membership['contactNumber'] ?? '',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Membership: ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13)),
                              Text(
                                membershipType,
                                style: TextStyle(
                                    color:
                                        _getMembershipTypeColor(membershipType),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text('Time left: ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13)),
                              Text(
                                remainingTime,
                                style: TextStyle(
                                  color: remainingTime == 'Expired'
                                      ? Colors.red
                                      : Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            );
          } else {
            // Desktop/tablet layout: table
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 28),
                        child: Column(
                          children: [
                            // Header Row
                            Container(
                              color: Colors.blue[50],
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: const Row(
                                children: [
                                  Expanded(
                                      flex: 3,
                                      child: Text('Name',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 3,
                                      child: Text('Contact Number',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 3,
                                      child: Text('Membership Type',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 3,
                                      child: Text('Time Remaining',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  SizedBox(
                                      width: 100,
                                      child: Text('View Profile',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),
                            const Divider(height: 24, color: Colors.black26),
                            // Data Rows
                            ..._memberships.map((membership) {
                              final expirationDate =
                                  membership['expirationDate'] as DateTime;
                              final remainingTime =
                                  _getRemainingTime(expirationDate);
                              final membershipType =
                                  membership['membershipType'] as String;
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 14),
                                            child:
                                                Text(membership['name'] ?? ''),
                                          )),
                                      Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 14),
                                            child: Text(
                                                membership['contactNumber'] ??
                                                    ''),
                                          )),
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 14),
                                          child: Text(
                                            membershipType,
                                            style: TextStyle(
                                                color: _getMembershipTypeColor(
                                                    membershipType)),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 14),
                                          child: Text(
                                            remainingTime,
                                            style: TextStyle(
                                              color: remainingTime == 'Expired'
                                                  ? Colors.red
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: TextButton(
                                          onPressed: () {
                                            // TODO: Implement view profile functionality
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor:
                                                Colors.blue.shade50,
                                            foregroundColor: Colors.blue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                          ),
                                          child: const Text('View'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                      height: 18, color: Colors.black12),
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
            );
          }
        },
      ),
    );
  }
}
