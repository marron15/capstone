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
  bool _showExpiredOnly = false;
  bool _showNotExpiredOnly = false;
  static const double _drawerWidth = 280;
  bool _navCollapsed = false;

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

    // Expired-only filter (applied after membership/search filters)
    List<Map<String, dynamic>> result = filtered;
    if (_showExpiredOnly) {
      final DateTime now = DateTime.now();
      final DateTime todayOnly = DateTime(now.year, now.month, now.day);
      result =
          filtered.where((c) {
            final DateTime exp = c['expirationDate'] as DateTime;
            return exp.isBefore(todayOnly);
          }).toList();
    } else if (_showNotExpiredOnly) {
      final DateTime now = DateTime.now();
      final DateTime todayOnly = DateTime(now.year, now.month, now.day);
      result =
          filtered.where((c) {
            final DateTime exp = c['expirationDate'] as DateTime;
            return !exp.isBefore(todayOnly);
          }).toList();
    }

    // Sort by soonest expiration when viewing All
    if (_membershipFilter == 'All') {
      result.sort((a, b) {
        final DateTime aExp = a['expirationDate'] as DateTime;
        final DateTime bExp = b['expirationDate'] as DateTime;
        return aExp.compareTo(bExp);
      });
    }

    return result;
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
    // Start loading customers

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load active customers only (with passwords for admin editing)
      // Fetch active customers with passwords for admin editing
      final result = await ApiService.getCustomersByStatusWithPasswords(
        status: 'active',
      );
      // Avoid logging the entire result payload

      if (result['success'] == true && result['data'] != null) {
        List<Map<String, dynamic>> loadedCustomers = [];

        for (var customerData in result['data']) {
          // Convert API customer data to customer format
          final customer = _convertCustomerData(customerData);
          loadedCustomers.add(customer);
        }

        // Loaded active customers count

        // Load archived customers
        // Loading archived customers
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
          // Loaded archived customers count
        }

        if (mounted) {
          setState(() {
            _customers = loadedCustomers;
            _archivedCustomers = loadedArchivedCustomers;
            _isLoading = false;
          });

          _sortCustomersByExpiration();
        }
      } else {
        debugPrint('_loadCustomers failed: ${result['message']}');
        if (mounted) {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to load customers';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('_loadCustomers error: $e');
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

  // Header cell with dropdown for membership filter
  Widget _buildMembershipHeader() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Membership Type',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: 'Filter membership type',
            icon: const Icon(Icons.arrow_drop_down, size: 18),
            onSelected: (val) => setState(() => _membershipFilter = val),
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: 'All', child: Text('All')),
                  PopupMenuItem(value: 'Daily', child: Text('Daily')),
                  PopupMenuItem(value: 'Half Month', child: Text('Half Month')),
                  PopupMenuItem(value: 'Monthly', child: Text('Monthly')),
                ],
          ),
        ],
      ),
    );
  }

  // Header cell with dropdown for expiration filter
  Widget _buildExpirationHeader() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Expiration Date',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: 'Filter expiration',
            icon: const Icon(Icons.arrow_drop_down, size: 18),
            onSelected:
                (val) => setState(() {
                  if (val == 'all') {
                    _showExpiredOnly = false;
                    _showNotExpiredOnly = false;
                  } else if (val == 'expired') {
                    _showExpiredOnly = true;
                    _showNotExpiredOnly = false;
                  } else if (val == 'notExpired') {
                    _showExpiredOnly = false;
                    _showNotExpiredOnly = true;
                  }
                }),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'all',
                    child: Row(
                      children: const [
                        Icon(Icons.event_available, size: 18),
                        SizedBox(width: 8),
                        Text('All Dates'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'expired',
                    child: Row(
                      children: const [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Text('Expired Only'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'notExpired',
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle, size: 18, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Not Expired Only'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
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

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerModal() {
    showDialog(
      context: context,
      builder: (context) => const AdminSignUpModal(),
    ).then((result) {
      if (result != null && result['success'] == true) {
        final data = result['customerData'] as Map<String, dynamic>;

        // Show enhanced success modal
        _showCustomerSuccessModal(data);

        // Refresh the customer list from the server
        _loadCustomers();
      }
    });
  }

  void _showCustomerSuccessModal(Map<String, dynamic> customerData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CustomerSuccessModal(customerData: customerData),
    );
  }

  @override
  Widget build(BuildContext context) {
    // No-op: fixed sidenav layout; no header-driven responsiveness required here

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: _navCollapsed ? 0 : _drawerWidth,
              child: SideNav(
                width: _drawerWidth,
                onClose: () => setState(() => _navCollapsed = true),
              ),
            ),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: const BoxDecoration(color: Colors.white),
                child: Column(
                  children: [
                    const SizedBox.shrink(),
                    Expanded(child: _buildBody()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
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

    // Always render the table shell; even when there are no customers

    // Keep header visible for archives even when empty

    // Keep header visible for active view even when empty

    return isMobile
        ? Column(
          children: [
            // Action buttons for mobile - matching admin_profile.dart pattern
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // First row with Export and View Archives buttons
                  Row(
                    children: [
                      // Export
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              () => exportCustomersToExcel(
                                context,
                                _getVisibleCustomers(),
                              ),
                          icon: const Icon(Icons.table_view, size: 16),
                          label: const Text('Export'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ).copyWith(
                            side: WidgetStateProperty.resolveWith(
                              (states) => BorderSide(
                                color:
                                    states.contains(WidgetState.hovered)
                                        ? const Color(0xFFFFA812)
                                        : Colors.black26,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // View Archives toggle
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showArchivedCustomers,
                          icon: Icon(
                            _showArchived ? Icons.people : Icons.archive,
                            size: 16,
                          ),
                          label: Text(
                            _showArchived ? 'View Active' : 'View Archives',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ).copyWith(
                            side: WidgetStateProperty.resolveWith(
                              (states) => BorderSide(
                                color:
                                    states.contains(WidgetState.hovered)
                                        ? const Color(0xFFFFA812)
                                        : Colors.black26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Second row with New Customer button
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showAddCustomerModal,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New Customer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ).copyWith(
                            side: WidgetStateProperty.resolveWith(
                              (states) => BorderSide(
                                color:
                                    states.contains(WidgetState.hovered)
                                        ? const Color(0xFFFFA812)
                                        : Colors.black26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Mobile filters
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Expired-only toggle
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          () => setState(() {
                            _showExpiredOnly = !_showExpiredOnly;
                          }),
                      icon: Icon(
                        Icons.warning_amber_rounded,
                        color: _showExpiredOnly ? Colors.red : Colors.orange,
                        size: 16,
                      ),
                      label: Text(
                        _showExpiredOnly ? 'All Dates' : 'Expired Only',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(
                          color: _showExpiredOnly ? Colors.red : Colors.black26,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Membership filter dropdown
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black26),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _membershipFilter,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text(
                                'All',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Daily',
                              child: Text(
                                'Daily',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Half Month',
                              child: Text(
                                'Half Month',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Monthly',
                              child: Text(
                                'Monthly',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() {
                              _membershipFilter = val;
                            });
                          },
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                          icon: const Icon(Icons.arrow_drop_down, size: 16),
                        ),
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
                    final DateTime _nowM = DateTime.now();
                    final DateTime _todayOnlyM = DateTime(
                      _nowM.year,
                      _nowM.month,
                      _nowM.day,
                    );
                    final bool _isExpiredM = expirationDate.isBefore(
                      _todayOnlyM,
                    );
                    final membershipType = customer['membershipType'] as String;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row with name and actions
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getMembershipTypeColor(
                                            membershipType,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: _getMembershipTypeColor(
                                              membershipType,
                                            ).withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          membershipType,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _getMembershipTypeColor(
                                              membershipType,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Action buttons
                                Row(
                                  children: [
                                    // View button
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                        ),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: Colors.blue,
                                          size: 18,
                                        ),
                                        onPressed: () async {
                                          final result =
                                              await CustomerViewEditModal.showCustomerModal(
                                                context,
                                                customer,
                                              );
                                          if (result == true && mounted) {
                                            setState(() {});
                                          }
                                        },
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        tooltip: 'View / Edit',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Archive/Restore button
                                    Container(
                                      decoration: BoxDecoration(
                                        color:
                                            _showArchived
                                                ? Colors.green.shade50
                                                : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              _showArchived
                                                  ? Colors.green.shade200
                                                  : Colors.orange.shade200,
                                        ),
                                      ),
                                      child: IconButton(
                                        onPressed:
                                            _showArchived
                                                ? () =>
                                                    _restoreCustomer(customer)
                                                : () => _confirmAndArchive(
                                                  customer,
                                                ),
                                        icon: Icon(
                                          _showArchived
                                              ? Icons.restore_outlined
                                              : Icons.archive_outlined,
                                          size: 18,
                                          color:
                                              _showArchived
                                                  ? Colors.green
                                                  : Colors.orange,
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        tooltip:
                                            _showArchived
                                                ? 'Restore Customer'
                                                : 'Archive Customer',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Info grid - 2 cards centered for good balance
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Contact card
                                Expanded(
                                  flex: 1,
                                  child: _buildInfoCard(
                                    'Contact',
                                    customer['contactNumber'] ?? 'N/A',
                                    Icons.phone_outlined,
                                    Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Status card
                                Expanded(
                                  flex: 1,
                                  child: _buildInfoCard(
                                    'Status',
                                    _isExpiredM ? 'Expired' : 'Active',
                                    _isExpiredM
                                        ? Icons.warning_outlined
                                        : Icons.check_circle_outline,
                                    _isExpiredM ? Colors.red : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Membership details
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Start Date:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        formattedStart,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Expiration:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        formattedExpiry,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              _isExpiredM
                                                  ? Colors.red
                                                  : Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
        )
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top controls styled like the reference design
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip:
                            _navCollapsed ? 'Open Sidebar' : 'Close Sidebar',
                        onPressed:
                            () =>
                                setState(() => _navCollapsed = !_navCollapsed),
                        icon: Icon(
                          _navCollapsed ? Icons.menu : Icons.chevron_left,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                        ).copyWith(
                          side: WidgetStateProperty.resolveWith(
                            (states) => BorderSide(
                              color:
                                  states.contains(WidgetState.hovered)
                                      ? const Color(0xFFFFA812)
                                      : Colors.black26,
                            ),
                          ),
                        ),
                      ),
                      // Membership/Expiration filters have been moved into table headers
                      const SizedBox(width: 12),
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
                        ).copyWith(
                          side: WidgetStateProperty.resolveWith(
                            (states) => BorderSide(
                              color:
                                  states.contains(WidgetState.hovered)
                                      ? const Color(0xFFFFA812)
                                      : Colors.black26,
                            ),
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
                        ).copyWith(
                          side: WidgetStateProperty.resolveWith(
                            (states) => BorderSide(
                              color:
                                  states.contains(WidgetState.hovered)
                                      ? const Color(0xFFFFA812)
                                      : Colors.black26,
                            ),
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
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: const Text(
                                'Name',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: const Text(
                                'Contact Number',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(flex: 3, child: _buildMembershipHeader()),
                            Expanded(
                              flex: 3,
                              child: const Text(
                                'Membership Start Date',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Expanded(flex: 3, child: _buildExpirationHeader()),
                            SizedBox(
                              width: 160,
                              child: const Text(
                                'Actions',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
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
                        final formattedStart = _formatExpirationDate(startDate);
                        final DateTime nowDate = DateTime.now();
                        final DateTime todayOnly = DateTime(
                          nowDate.year,
                          nowDate.month,
                          nowDate.day,
                        );
                        final bool isExpired = expirationDate.isBefore(
                          todayOnly,
                        );
                        final membershipType =
                            customer['membershipType'] as String;
                        return Column(
                          children: [
                            Container(
                              color: isExpired ? Colors.red.shade50 : null,
                              child: Row(
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
                                        style: const TextStyle(fontSize: 16),
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
                                      child: _buildPhoneNumberButton(
                                        customer['contactNumber'] ?? 'N/A',
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
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          membershipType,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _getMembershipTypeColor(
                                              membershipType,
                                            ),
                                            fontSize: 14,
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
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          formattedStart,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
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
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              formattedExpiry,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color:
                                                    isExpired
                                                        ? Colors.red
                                                        : Colors.black87,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (isExpired) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.red.shade300,
                                                ),
                                              ),
                                              child: const Text(
                                                'Expired',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
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
                                              // Open customer modal
                                              final result =
                                                  await CustomerViewEditModal.showCustomerModal(
                                                    context,
                                                    customer,
                                                  );
                                              // Modal result handled below
                                              if (result == true && mounted) {
                                                setState(() {});
                                              }
                                            },
                                            icon: Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color: Colors.blue.shade700,
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(
                                              minWidth: 36,
                                              minHeight: 36,
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
                                                size: 18,
                                                color: Colors.orange.shade700,
                                              ),
                                              padding: const EdgeInsets.all(8),
                                              constraints: const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36,
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
                                                size: 18,
                                                color: Colors.green.shade700,
                                              ),
                                              padding: const EdgeInsets.all(8),
                                              constraints: const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36,
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

  // Build styled phone number button for desktop view
  Widget _buildPhoneNumberButton(String phoneNumber) {
    if (phoneNumber == 'N/A' || phoneNumber.isEmpty) {
      return Center(
        child: Text(
          'N/A',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E8), // Light green background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.phone,
              size: 16,
              color: const Color(0xFF2E7D32), // Darker green icon
            ),
            const SizedBox(width: 6),
            Text(
              phoneNumber,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2E7D32), // Darker green text
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerSuccessModal extends StatefulWidget {
  final Map<String, dynamic> customerData;

  const _CustomerSuccessModal({required this.customerData});

  @override
  State<_CustomerSuccessModal> createState() => _CustomerSuccessModalState();
}

class _CustomerSuccessModalState extends State<_CustomerSuccessModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _iconController;
  late Animation<double> _iconScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Icon animation controller
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    // Start animations
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _iconController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated success icon
                ScaleTransition(
                  scale: _iconScaleAnimation,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.shade100,
                      border: Border.all(
                        color: Colors.green.shade300,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title with animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Customer Added Successfully!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),

                // Success message
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Customer "${widget.customerData['name'] ?? 'Unknown'}" has been registered in the database with ${widget.customerData['membershipType'] ?? 'Monthly'} membership.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // Customer details card
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Column(
                      children: [
                        // Login credentials
                        _buildInfoRow(
                          icon: Icons.check_circle_outline,
                          iconColor: Colors.green.shade600,
                          text:
                              widget.customerData['email'] != null &&
                                      widget.customerData['email']
                                          .toString()
                                          .isNotEmpty
                                  ? 'The customer can now log in using their email and password.'
                                  : 'The customer can now log in using their contact number and password.',
                          textColor: Colors.green.shade700,
                          isBold: true,
                        ),
                        const SizedBox(height: 12),

                        // Email (only show if provided)
                        if (widget.customerData['email'] != null &&
                            widget.customerData['email']
                                .toString()
                                .isNotEmpty) ...[
                          _buildInfoRow(
                            icon: Icons.email_outlined,
                            iconColor: Colors.blue.shade600,
                            text: 'Email: ${widget.customerData['email']}',
                            textColor: Colors.black87,
                          ),
                        ],
                        if (widget.customerData['email'] != null &&
                            widget.customerData['email'].toString().isNotEmpty)
                          const SizedBox(height: 8),

                        // Password
                        _buildInfoRow(
                          icon: Icons.key_outlined,
                          iconColor: Colors.orange.shade600,
                          text: 'Password: [As set during registration]',
                          textColor: Colors.black87,
                        ),

                        // Membership info
                        if (widget.customerData['membershipType'] != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            icon: Icons.card_membership,
                            iconColor: Colors.purple.shade600,
                            text:
                                'Membership: ${widget.customerData['membershipType']}',
                            textColor: Colors.black87,
                            isBold: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // OK button with animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
