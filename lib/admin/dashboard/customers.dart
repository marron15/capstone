import 'package:flutter/material.dart';
import '../sidenav.dart';
import '../modal/customers_signup_modal.dart';
import '../modal/customer_view_edit_modal.dart';
import '../services/api_service.dart';
import '../excel/excel_import.dart';

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
  bool _showArchived = false;
  List<Map<String, dynamic>> _archivedCustomers = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _membershipFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _confirmAndArchive(Map<String, dynamic> customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Archive customer?'),
            content: Text(
              'This will archive ${customer['name'] ?? 'this customer'}. Archived customers can be restored later.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text('Archive'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid customer ID')));
        return;
      }

      setState(() => _isLoading = true);
      final res = await ApiService.archiveCustomer(id: id);
      if (res['success'] == true) {
        // Move customer from active to archived list locally
        setState(() {
          _customers.removeWhere(
            (c) => c['customerId'] == customer['customerId'],
          );
          _archivedCustomers.add(customer);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${customer['name'] ?? 'Customer'} has been archived',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to archive customer'),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _showArchivedCustomers() {
    setState(() {
      _showArchived = !_showArchived;
    });
  }

  // Returns the list currently visible, filtered by search
  List<Map<String, dynamic>> _getVisibleCustomers() {
    final List<Map<String, dynamic>> source =
        _showArchived ? _archivedCustomers : _customers;
    final String q = _searchQuery.trim().toLowerCase();
    final List<Map<String, dynamic>> filtered =
        source.where((c) {
          final String name =
              (c['name'] ?? c['fullName'] ?? '').toString().toLowerCase();
          final String contact =
              (c['contactNumber'] ?? c['phone_number'] ?? '')
                  .toString()
                  .toLowerCase();
          final bool matchesSearch =
              q.isEmpty || name.contains(q) || contact.contains(q);
          if (!matchesSearch) return false;
          if (_membershipFilter == 'All') return true;
          final String type =
              (c['membershipType'] ?? c['membership_type'] ?? '')
                  .toString()
                  .toLowerCase();
          if (_membershipFilter == 'Daily') return type == 'daily';
          if (_membershipFilter == 'Monthly')
            return type == 'monthly' || type.isEmpty;
          // Half Month check allows minor variations
          return type.replaceAll(' ', '') == 'halfmonth' ||
              (type.startsWith('half') && type.contains('month'));
        }).toList();

    // Sort by soonest expiration when viewing All
    if (_membershipFilter == 'All') {
      filtered.sort((a, b) {
        final DateTime aExp = a['expirationDate'] as DateTime;
        final DateTime bExp = b['expirationDate'] as DateTime;
        return aExp.compareTo(bExp);
      });
    }

    return filtered;
  }

  Future<void> _restoreCustomer(Map<String, dynamic> customer) async {
    final dynamic idVal = customer['customerId'];
    final int id = idVal is int ? idVal : int.tryParse(idVal.toString()) ?? -1;
    if (id <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid customer ID')));
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService.restoreCustomer(id: id);
    if (res['success'] == true) {
      // Move customer from archived to active list locally
      setState(() {
        _archivedCustomers.removeWhere(
          (c) => c['customerId'] == customer['customerId'],
        );
        _customers.add(customer);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${customer['name'] ?? 'Customer'} has been restored'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to restore customer')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadCustomers() async {
    debugPrint('_loadCustomers: Starting to load customers...');
    debugPrint('_loadCustomers: Current customers count: ${_customers.length}');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load active customers only (with passwords for admin editing)
      debugPrint(
        '_loadCustomers: Calling API to get active customers with passwords...',
      );
      final result = await ApiService.getCustomersByStatusWithPasswords(
        status: 'active',
      );
      debugPrint('_loadCustomers: API result: $result');

      if (result['success'] == true && result['data'] != null) {
        List<Map<String, dynamic>> loadedCustomers = [];

        for (var customerData in result['data']) {
          // Convert API customer data to customer format
          final customer = _convertCustomerData(customerData);
          loadedCustomers.add(customer);
        }

        debugPrint(
          '_loadCustomers: Loaded ${loadedCustomers.length} active customers',
        );
        debugPrint(
          '_loadCustomers: First customer name: ${loadedCustomers.isNotEmpty ? loadedCustomers.first['name'] : 'No customers'}',
        );

        // Load archived customers
        debugPrint('_loadCustomers: Loading archived customers...');
        // Backend marks archived customers as "inactive"
        final archivedResult = await ApiService.getCustomersByStatus(
          status: 'inactive',
        );
        List<Map<String, dynamic>> loadedArchivedCustomers = [];

        if (archivedResult['success'] == true &&
            archivedResult['data'] != null) {
          for (var customerData in archivedResult['data']) {
            // Convert API customer data to customer format
            final customer = _convertCustomerData(customerData);
            loadedArchivedCustomers.add(customer);
          }
          debugPrint(
            '_loadCustomers: Loaded ${loadedArchivedCustomers.length} archived customers',
          );
        }

        if (mounted) {
          setState(() {
            _customers = loadedCustomers;
            _archivedCustomers = loadedArchivedCustomers;
            _isLoading = false;
          });

          _sortCustomersByExpiration();
          debugPrint('_loadCustomers: Customer lists updated successfully');
          debugPrint(
            '_loadCustomers: Final active customers count: ${_customers.length}',
          );
          debugPrint(
            '_loadCustomers: Final archived customers count: ${_archivedCustomers.length}',
          );
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
    // Normalize membership type from various possible fields
    String normalizeMembershipType(String? raw) {
      final String val = (raw ?? '').trim().toLowerCase();
      if (val.isEmpty) return '';
      if (val == 'daily') return 'Daily';
      if (val.replaceAll(' ', '') == 'halfmonth') return 'Half Month';
      if (val == 'monthly') return 'Monthly';
      // Some APIs might return like "half month 1" or variants
      if (val.startsWith('half') && val.contains('month')) return 'Half Month';
      return 'Monthly';
    }

    // Prefer nested membership field if present
    final Map<String, dynamic>? membership =
        customerData['membership'] is Map<String, dynamic>
            ? customerData['membership'] as Map<String, dynamic>
            : null;

    final String membershipType = normalizeMembershipType(
      membership?['membership_type'] ??
          customerData['membership_type'] ??
          customerData['status'],
    );

    DateTime expirationDate;
    DateTime startDate;

    // Parse dates from any available keys
    String? expirationRaw =
        (membership?['expiration_date'] ?? customerData['expiration_date'])
            ?.toString();
    String? startRaw =
        (membership?['start_date'] ?? customerData['start_date'])?.toString();

    try {
      expirationDate =
          expirationRaw != null && expirationRaw.isNotEmpty
              ? DateTime.parse(expirationRaw)
              : DateTime.now().add(const Duration(days: 30));
    } catch (e) {
      expirationDate = DateTime.now().add(const Duration(days: 30));
    }

    try {
      startDate =
          startRaw != null && startRaw.isNotEmpty
              ? DateTime.parse(startRaw)
              : DateTime.now();
    } catch (e) {
      startDate = DateTime.now();
    }

    return {
      'name':
          '${customerData['first_name'] ?? ''} ${customerData['last_name'] ?? ''}'
              .trim(),
      'contactNumber': customerData['phone_number'] ?? 'Not provided',
      'membershipType': membershipType,
      'expirationDate': expirationDate,
      'startDate': startDate,
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
      // Pass through any nested membership for downstream use
      'membership': membership,
      'membership_type': membershipType,
      'start_date': startRaw,
      'expiration_date': expirationRaw,
      'status': customerData['status'],
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

  String _formatExpirationDate(DateTime expirationDate) {
    final String dd = expirationDate.day.toString().padLeft(2, '0');
    final String mm = expirationDate.month.toString().padLeft(2, '0');
    final String yyyy = expirationDate.year.toString().padLeft(4, '0');
    return '$mm/$dd/$yyyy';
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
        final data = result['customerData'] as Map<String, dynamic>;
        // UI-only insertion so table updates immediately; backend can sync later
        setState(() {
          _customers.add({
            'name': data['name'] ?? '',
            'contactNumber': data['contactNumber'] ?? 'Not provided',
            'membershipType': data['membershipType'] ?? 'Monthly',
            'expirationDate': data['expirationDate'] as DateTime,
            'startDate': data['startDate'] as DateTime? ?? DateTime.now(),
            'email': data['email'] ?? '',
            'fullName': data['fullName'] ?? '',
            'birthdate': data['birthdate'],
            'address': data['address'],
            'emergencyContactName': data['emergencyContactName'],
            'emergencyContactPhone': data['emergencyContactPhone'],
            'customerId': data['customerId'],
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      drawer: const SideNav(),
      appBar: AppBar(
        title: const Center(child: Text('Customer Management')),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        actions: const [],
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
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
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
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

    if (_customers.isEmpty && _archivedCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
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

    if (_showArchived && _archivedCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No archived customers',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Archived customers will appear here',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showArchivedCustomers,
              icon: const Icon(Icons.people),
              label: const Text('View Active Customers'),
            ),
          ],
        ),
      );
    }

    if (!_showArchived && _customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No active customers',
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
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showArchivedCustomers,
                        icon: Icon(
                          _showArchived ? Icons.people : Icons.archive,
                          size: 20,
                        ),
                        label: Text(
                          _showArchived
                              ? 'Active Customers'
                              : 'Archived Customers',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _showArchived ? Colors.green : Colors.grey[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            () => exportCustomersToExcel(
                              context,
                              _getVisibleCustomers(),
                            ),
                        icon: const Icon(Icons.download, size: 20),
                        label: const Text('Export'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ..._getVisibleCustomers().map((customer) {
                      final expirationDate =
                          customer['expirationDate'] as DateTime;
                      final startDate = customer['startDate'] as DateTime;
                      final formattedExpiry = _formatExpirationDate(
                        expirationDate,
                      );
                      final formattedStart = _formatExpirationDate(startDate);
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
                            horizontal: 16,
                            vertical: 18,
                          ),
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
                                      fontSize: 16,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      // Show customer view/edit modal
                                      final result =
                                          await CustomerViewEditModal.showCustomerModal(
                                            context,
                                            customer,
                                          );
                                      if (result == true && mounted) {
                                        setState(
                                          () {},
                                        ); // UI-only immediate update
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.blue.shade50,
                                      foregroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    child: const Text('View'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                customer['contactNumber'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'Membership: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    membershipType,
                                    style: TextStyle(
                                      color: _getMembershipTypeColor(
                                        membershipType,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                children: [
                                  Text(
                                    'Membership Start: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                formattedStart,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                children: [
                                  Text(
                                    'Membership Expiration: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                formattedExpiry,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      // Show customer view/edit modal
                                      final result =
                                          await CustomerViewEditModal.showCustomerModal(
                                            context,
                                            customer,
                                          );
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
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    child: const Text('View'),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!_showArchived) ...[
                                    TextButton(
                                      onPressed:
                                          () => _confirmAndArchive(customer),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.orange.shade50,
                                        foregroundColor: Colors.orange,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: const Text('Archive'),
                                    ),
                                  ] else ...[
                                    TextButton(
                                      onPressed:
                                          () => _restoreCustomer(customer),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.green.shade50,
                                        foregroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: const Text('Restore'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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
              // Top controls styled like the reference design
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Title
                        Text(
                          _showArchived ? 'Archived Customers' : 'Customers',
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
                        // Search box (fixed width)
                        SizedBox(
                          width: 560,
                          height: 42,
                          child: TextField(
                            controller: _searchController,
                            onChanged:
                                (val) => setState(() {
                                  _searchQuery = val;
                                }),
                            style: const TextStyle(color: Colors.black87),
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
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.black26,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Export button (Excel icon + text)
                        OutlinedButton.icon(
                          onPressed:
                              () => exportCustomersToExcel(
                                context,
                                _getVisibleCustomers(),
                              ),
                          icon: const Icon(
                            Icons.table_chart_rounded,
                            color: Colors.teal,
                            size: 20,
                          ),
                          label: const Text('Export'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Colors.black26),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Styled dropdown (membership filter for now)
                        DropdownButtonHideUnderline(
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black26),
                            ),
                            child: DropdownButton<String>(
                              value: _membershipFilter,
                              items: const [
                                DropdownMenuItem(
                                  value: 'All',
                                  child: Text('All'),
                                ),
                                DropdownMenuItem(
                                  value: 'Daily',
                                  child: Text('Daily'),
                                ),
                                DropdownMenuItem(
                                  value: 'Half Month',
                                  child: Text('Half Month'),
                                ),
                                DropdownMenuItem(
                                  value: 'Monthly',
                                  child: Text('Monthly'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() {
                                  _membershipFilter = val;
                                });
                              },
                              style: const TextStyle(color: Colors.black87),
                              icon: const Icon(Icons.arrow_drop_down),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // View archives pill button
                        OutlinedButton.icon(
                          onPressed: _showArchivedCustomers,
                          icon: Icon(
                            _showArchived ? Icons.people : Icons.archive,
                            size: 18,
                          ),
                          label: Text(
                            _showArchived ? 'View Active' : 'View Archives',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Colors.black26),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // New customer pill button
                        ElevatedButton.icon(
                          onPressed: _showAddCustomerModal,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New Customer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 1,
                            side: const BorderSide(color: Colors.black26),
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
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
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
                        // Header Row (match admin_profile.dart styling)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Name',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Contact Number',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Membership Type',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Membership Start Date',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Membership Expiration Date',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: Text(
                                  'Actions',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Data Rows
                        ..._getVisibleCustomers().map((customer) {
                          final expirationDate =
                              customer['expirationDate'] as DateTime;
                          final startDate = customer['startDate'] as DateTime;
                          final formattedExpiry = _formatExpirationDate(
                            expirationDate,
                          );
                          final formattedStart = _formatExpirationDate(
                            startDate,
                          );
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
                                        vertical: 14,
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        customer['name'] ?? '',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        customer['contactNumber'] ?? '',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        membershipType,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _getMembershipTypeColor(
                                            membershipType,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        formattedStart,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        formattedExpiry,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 160,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // View/Edit icon button styled like admin table
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue.shade200,
                                            ),
                                          ),
                                          child: IconButton(
                                            onPressed: () async {
                                              debugPrint(
                                                'Desktop: Opening customer modal for: ${customer['name']}',
                                              );
                                              final result =
                                                  await CustomerViewEditModal.showCustomerModal(
                                                    context,
                                                    customer,
                                                  );
                                              debugPrint(
                                                'Desktop: Modal result: $result',
                                              );
                                              if (result == true && mounted) {
                                                setState(() {});
                                              }
                                            },
                                            icon: Icon(
                                              Icons.edit_outlined,
                                              size: 14,
                                              color: Colors.blue.shade700,
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(
                                              minWidth: 28,
                                              minHeight: 28,
                                            ),
                                            tooltip: 'View / Edit',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (!_showArchived) ...[
                                          // Archive icon button
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.orange.shade200,
                                              ),
                                            ),
                                            child: IconButton(
                                              onPressed:
                                                  () => _confirmAndArchive(
                                                    customer,
                                                  ),
                                              icon: Icon(
                                                Icons.archive_outlined,
                                                size: 14,
                                                color: Colors.orange.shade700,
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(
                                                minWidth: 28,
                                                minHeight: 28,
                                              ),
                                              tooltip: 'Archive',
                                            ),
                                          ),
                                        ] else ...[
                                          // Restore icon button
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.green.shade200,
                                              ),
                                            ),
                                            child: IconButton(
                                              onPressed:
                                                  () => _restoreCustomer(
                                                    customer,
                                                  ),
                                              icon: Icon(
                                                Icons
                                                    .settings_backup_restore_rounded,
                                                size: 14,
                                                color: Colors.green.shade700,
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(
                                                minWidth: 28,
                                                minHeight: 28,
                                              ),
                                              tooltip: 'Restore',
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Divider(height: 1, color: Colors.grey.shade200),
                            ],
                          );
                        }),
                      ],
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
