import 'package:flutter/material.dart';
import '../sidenav.dart';
import '../modal/customers_signup_modal.dart';
import '../modal/customer_view_edit_modal.dart';
import '../services/api_service.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  // Data loaded from database
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _confirmAndDelete(Map<String, dynamic> customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text(
            'This will permanently delete ${customer['name'] ?? 'this customer'}. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final dynamic idVal = customer['customerId'];
      final int id =
          idVal is int ? idVal : int.tryParse(idVal.toString()) ?? -1;
      if (id <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid customer ID')),
        );
        return;
      }

      setState(() => _isLoading = true);
      final res = await ApiService.deleteCustomer(id: id);
      if (res['success'] == true) {
        await _loadCustomers();
      } else {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res['message'] ?? 'Failed to delete customer')),
        );
      }
    }
  }

  // Force refresh the customer list
  Future<void> _refreshCustomerList() async {
    debugPrint('_refreshCustomerList: Starting forced refresh...');

    // Clear current data first
    if (mounted) {
      setState(() {
        _customers = [];
        _isLoading = true;
      });
    }

    // Reload customers from API
    await _loadCustomers();

    // Force additional UI rebuild
    if (mounted) {
      setState(() {
        debugPrint('_refreshCustomerList: Forcing UI rebuild...');
      });
    }
    debugPrint('_refreshCustomerList: Refresh completed');
  }

  // Force complete UI rebuild
  void _forceRebuild() {
    if (mounted) {
      setState(() {
        debugPrint('_forceRebuild: Forcing complete UI rebuild...');
      });
    }
  }

  Future<void> _loadCustomers() async {
    debugPrint('_loadCustomers: Starting to load customers...');
    debugPrint('_loadCustomers: Current customers count: ${_customers.length}');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint(
          '_loadCustomers: Calling API to get all customers with passwords...');
      final result = await ApiService.getAllCustomersWithPasswords();
      debugPrint('_loadCustomers: API result: $result');

      if (result['success'] == true && result['data'] != null) {
        List<Map<String, dynamic>> loadedCustomers = [];

        for (var customerData in result['data']) {
          // Convert API customer data to customer format
          final customer = _convertCustomerData(customerData);
          loadedCustomers.add(customer);
        }

        debugPrint(
            '_loadCustomers: Loaded ${loadedCustomers.length} customers');
        debugPrint(
            '_loadCustomers: First customer name: ${loadedCustomers.isNotEmpty ? loadedCustomers.first['name'] : 'No customers'}');

        if (mounted) {
          setState(() {
            _customers = loadedCustomers;
            _isLoading = false;
          });

          _sortCustomersByExpiration();
          debugPrint('_loadCustomers: Customer list updated successfully');
          debugPrint(
              '_loadCustomers: Final customers count: ${_customers.length}');
        }
      } else {
        debugPrint('_loadCustomers: API failed: ${result['message']}');
        if (mounted) {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to load customers';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('_loadCustomers: Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading customers: $e';
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _convertCustomerData(Map<String, dynamic> customerData) {
    // Convert customer data from the API
    String membershipType = customerData['membership_type'] ?? 'Monthly';
    DateTime expirationDate;

    try {
      expirationDate = DateTime.parse(customerData['expiration_date']);
    } catch (e) {
      expirationDate = DateTime.now().add(const Duration(days: 30));
    }

    return {
      'name':
          '${customerData['first_name'] ?? ''} ${customerData['last_name'] ?? ''}'
              .trim(),
      'contactNumber': customerData['phone_number'] ?? 'Not provided',
      'membershipType': membershipType,
      'expirationDate': expirationDate,
      'email': customerData['email'] ?? '',
      'fullName':
          '${customerData['first_name'] ?? ''} ${customerData['last_name'] ?? ''}'
              .trim(),
      'birthdate': customerData['birthdate'],
      'emergencyContactName': customerData['emergency_contact_name'] ?? '',
      'emergencyContactPhone': customerData['emergency_contact_number'] ?? '',
      'customerId': customerData['customer_id'] ?? customerData['id'],
      'createdAt':
          customerData['customer_created_at'] ?? customerData['created_at'],
      // Include original API data for the modal
      'first_name': customerData['first_name'],
      'last_name': customerData['last_name'],
      'middle_name': customerData['middle_name'],
      'phone_number': customerData['phone_number'],
      'emergency_contact_name': customerData['emergency_contact_name'],
      'emergency_contact_number': customerData['emergency_contact_number'],
      // Address information (if available)
      'address_details': customerData['address_details'],
      'address': customerData['address'],
      // Include password for admin editing
      'password': customerData['password'],
    };
  }

  void _sortCustomersByExpiration() {
    if (_customers.isNotEmpty) {
      _customers.sort((a, b) {
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

  void _showAddCustomerModal() {
    showDialog(
      context: context,
      builder: (context) => const AdminSignUpModal(),
    ).then((result) {
      if (result != null && result['success'] == true) {
        // Reload the entire list from the database to ensure consistency
        _loadCustomers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const SideNav(),
      appBar: AppBar(
        title: const Center(child: Text('Customer Management')),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF36454F),
        actions: const [],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141E30), Color(0xFF232526)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _buildBody(),
      ),
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
            Text('Loading customers...'),
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
              'Error loading customers',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            // Removed retry button - no refresh functionality needed
          ],
        ),
      );
    }

    if (_customers.isEmpty) {
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
              'No customers found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first customer to get started',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddCustomerModal,
              icon: const Icon(Icons.person_add),
              label: const Text('Add First Customer'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile layout: vertical cards for each customer
          return Column(
            children: [
              // Add Customer button for mobile
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _showAddCustomerModal,
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text('Add New Customer'),
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
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ..._customers.map((customer) {
                      final expirationDate =
                          customer['expirationDate'] as DateTime;
                      final remainingTime = _getRemainingTime(expirationDate);
                      final membershipType =
                          customer['membershipType'] as String;
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
                                    customer['name'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      // Show customer view/edit modal
                                      final result = await CustomerViewEditModal
                                          .showCustomerModal(context, customer);
                                      if (result == true) {
                                        // Refresh the list if customer was updated
                                        await _refreshCustomerList();
                                        _forceRebuild(); // Force additional UI rebuild
                                      }
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
                                customer['contactNumber'] ?? '',
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
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      // Show customer view/edit modal
                                      final result = await CustomerViewEditModal
                                          .showCustomerModal(context, customer);
                                      if (result == true) {
                                        // Refresh the list if customer was updated
                                        await _loadCustomers();
                                        // Force UI refresh
                                        if (mounted) {
                                          setState(() {});
                                        }
                                      }
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
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () =>
                                        _confirmAndDelete(customer),
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.red.shade50,
                                      foregroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                    child: const Text('Delete'),
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
            ],
          );
        } else {
          // Desktop/tablet layout: table
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add Customer button for desktop
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Customers List',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddCustomerModal,
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Add New Customer'),
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
                                    width: 160,
                                    child: Text('Actions',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          const Divider(height: 24, color: Colors.black26),
                          // Data Rows
                          ..._customers.map((customer) {
                            final expirationDate =
                                customer['expirationDate'] as DateTime;
                            final remainingTime =
                                _getRemainingTime(expirationDate);
                            final membershipType =
                                customer['membershipType'] as String;
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          child: Text(customer['name'] ?? ''),
                                        )),
                                    Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          child: Text(
                                              customer['contactNumber'] ?? ''),
                                        )),
                                    Expanded(
                                      flex: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
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
                                        padding: const EdgeInsets.symmetric(
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
                                      width: 160,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () async {
                                              // Show customer view/edit modal
                                              debugPrint(
                                                  'Desktop: Opening customer modal for: ${customer['name']}');
                                              final result =
                                                  await CustomerViewEditModal
                                                      .showCustomerModal(
                                                          context, customer);
                                              debugPrint(
                                                  'Desktop: Modal result: $result');
                                              if (result == true) {
                                                // Refresh the list if customer was updated
                                                debugPrint(
                                                    'Desktop: Customer was updated, refreshing list...');
                                                await _refreshCustomerList();
                                                _forceRebuild(); // Force additional UI rebuild
                                                debugPrint(
                                                    'Desktop: Customer list refreshed successfully');
                                              } else {
                                                debugPrint(
                                                    'Desktop: No changes made or modal was cancelled');
                                              }
                                            },
                                            style: TextButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blue.shade50,
                                              foregroundColor: Colors.blue,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                            ),
                                            child: const Text('View'),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () =>
                                                _confirmAndDelete(customer),
                                            style: TextButton.styleFrom(
                                              backgroundColor:
                                                  Colors.red.shade50,
                                              foregroundColor: Colors.red,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
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
    );
  }
}
