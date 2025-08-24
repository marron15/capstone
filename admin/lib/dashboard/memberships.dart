import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../sidenav.dart';
import '../modal/membership_signup_modal.dart';
import '../debug/api_test_page.dart';
import '../services/api_service.dart';

class MembershipsPage extends StatefulWidget {
  const MembershipsPage({super.key});

  @override
  State<MembershipsPage> createState() => _MembershipsPageState();
}

class _MembershipsPageState extends State<MembershipsPage> {
  // Data loaded from database
  List<Map<String, dynamic>> _memberships = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMemberships();
  }

  Future<void> _loadMemberships() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getAllUsers();

      if (result['success'] == true && result['data'] != null) {
        List<Map<String, dynamic>> loadedMemberships = [];

        for (var userData in result['data']) {
          // Convert API user data to membership format
          final membership = _convertUserToMembership(userData);
          loadedMemberships.add(membership);
        }

        setState(() {
          _memberships = loadedMemberships;
          _isLoading = false;
        });

        _sortMembershipsByExpiration();
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load members';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading members: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _convertUserToMembership(Map<String, dynamic> userData) {
    // Generate a default membership type and expiration date
    // In a real app, this would come from a membership table
    String membershipType = 'Monthly'; // Default
    DateTime expirationDate = DateTime.now().add(const Duration(days: 30));

    // Try to extract from user data if available
    if (userData['membership_type'] != null) {
      membershipType = userData['membership_type'];
    }
    if (userData['expiration_date'] != null) {
      try {
        expirationDate = DateTime.parse(userData['expiration_date']);
      } catch (e) {
        // Keep default if parsing fails
      }
    }

    return {
      'name': userData['full_name'] ??
          '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}',
      'contactNumber': userData['phone_number'] ?? 'Not provided',
      'membershipType': membershipType,
      'expirationDate': expirationDate,
      'email': userData['email'] ?? '',
      'fullName': userData['full_name'] ??
          '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}',
      'birthdate': userData['birthdate'],
      'emergencyContactName': userData['emergency_contact_name'] ?? '',
      'emergencyContactPhone': userData['emergency_contact_number'] ?? '',
      'userId': userData['user_id'],
      'createdAt': userData['created_at'],
    };
  }

  void _sortMembershipsByExpiration() {
    if (_memberships.isNotEmpty) {
      _memberships.sort((a, b) {
        final DateTime dateA = a['expirationDate'] as DateTime;
        final DateTime dateB = b['expirationDate'] as DateTime;
        return dateA.compareTo(dateB);
      });
    }
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

  void _showAddMemberModal() {
    showDialog(
      context: context,
      builder: (context) => const AdminSignUpModal(),
    ).then((result) {
      if (result != null && result['success'] == true) {
        // Reload the entire list from the database to ensure consistency
        _loadMemberships();
      }
    });
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
        actions: [
          // Refresh button
          IconButton(
            onPressed: _isLoading ? null : _loadMemberships,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          // Debug button - only visible in debug mode
          if (kDebugMode)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApiTestPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.bug_report),
                tooltip: 'API Tests',
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _showAddMemberModal,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add Member'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading members...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
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
              'Error loading members',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMemberships,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_memberships.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No members found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first member to get started',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddMemberModal,
              icon: const Icon(Icons.person_add),
              label: const Text('Add First Member'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile layout: vertical cards for each membership
          return Column(
            children: [
              // Add Member button for mobile
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _showAddMemberModal,
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text('Add New Member'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadMemberships,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ..._memberships.map((membership) {
                        final expirationDate =
                            membership['expirationDate'] as DateTime;
                        final remainingTime = _getRemainingTime(expirationDate);
                        final membershipType =
                            membership['membershipType'] as String;
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      membership['name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // TODO: Implement view profile functionality
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.blue.shade50,
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
                                          color: _getMembershipTypeColor(
                                              membershipType),
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
                  ),
                ),
              ),
            ],
          );
        } else {
          // Desktop/tablet layout: table
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add Member button for desktop
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Members List',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddMemberModal,
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Add New Member'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadMemberships,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const AlwaysScrollableScrollPhysics(),
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
              ),
            ],
          );
        }
      },
    );
  }
}
