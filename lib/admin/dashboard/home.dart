import 'package:flutter/material.dart';
import '../sidenav.dart';
import '../pdf/pdf_stats_export.dart';
import '../services/api_service.dart';
import '../services/admin_service.dart';
import '../services/refresh_service.dart';
import '../statistics/new_week_members.dart';
import '../statistics/new_members_month.dart';
import '../statistics/total_memberships.dart';
import '../../PH phone number valid/phone_formatter.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage>
    with WidgetsBindingObserver {
  static const double _drawerWidth = 280;
  bool _navCollapsed = false;
  // Drawer state no longer needed (side nav is fixed)
  bool _isLoading = true;
  String? _errorMessage;

  // Simple filter UI state removed per request
  final ScrollController _kpiController = ScrollController();
  String _startsView = 'Week';

  // Overall counts
  int productsActive = 0;
  int productsArchived = 0;
  int adminsActive = 0;
  int adminsArchived = 0;
  int customersActive = 0;
  int customersArchived = 0;
  int customersExpired = 0;
  int trainersActive = 0;
  int trainersArchived = 0;
  Map<String, int> membershipTotals = const {};

  // Customer table data
  List<Map<String, dynamic>> _customers = [];
  String _membershipFilter = 'All';
  bool _showExpiredOnly = false;
  bool _showNotExpiredOnly = false;

  // Manual refresh only - no auto refresh timer

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Register with refresh service
    RefreshService().registerRefreshCallback(_refreshData);

    _loadOverallReport();
    _loadCustomers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning from other pages (like customers.dart)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app becomes active again
      _refreshData();
    }
  }

  // Add a method to manually refresh data (can be called from other pages)
  void refreshCustomerData() {
    if (mounted) {
      _refreshData();
    }
  }

  Future<void> _loadOverallReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch in parallel
      final futures = await Future.wait([
        ApiService.getProductsByStatus('active'),
        ApiService.getProductsByStatus('inactive'),
        AdminService.getAllAdmins(),
        ApiService.getCustomersByStatusWithPasswords(status: 'active'),
        ApiService.getCustomersByStatus(status: 'inactive'),
        ApiService.getAllTrainers(),
        ApiService.getMembershipTotals(),
      ]);

      final List<Map<String, dynamic>> prodActive =
          List<Map<String, dynamic>>.from(futures[0] as List);
      final List<Map<String, dynamic>> prodInactive =
          List<Map<String, dynamic>>.from(futures[1] as List);

      final List<Map<String, dynamic>> admins = List<Map<String, dynamic>>.from(
        futures[2] as List,
      );

      final Map<String, dynamic> customersActiveRes =
          futures[3] as Map<String, dynamic>;
      final Map<String, dynamic> customersInactiveRes =
          futures[4] as Map<String, dynamic>;

      final List<Map<String, String>> trainers = List<Map<String, String>>.from(
        futures[5] as List,
      );

      final Map<String, int> memTotals = Map<String, int>.from(
        futures[6] as Map<String, int>,
      );

      // Compute counts
      productsActive = prodActive.length;
      productsArchived = prodInactive.length;

      // Admins: treat status === 'inactive' as archived if present
      adminsActive =
          admins.where((a) {
            final String s = (a['status'] ?? '').toString().toLowerCase();
            return s != 'inactive';
          }).length;
      adminsArchived = admins.length - adminsActive;

      final List<dynamic> activeCust =
          (customersActiveRes['data'] as List<dynamic>? ?? const []);
      final List<dynamic> archivedCust =
          (customersInactiveRes['data'] as List<dynamic>? ?? const []);
      customersActive = activeCust.length;
      customersArchived = archivedCust.length;

      // Expired among active customers (based on expiration_date)
      final DateTime now = DateTime.now();
      final DateTime todayOnly = DateTime(now.year, now.month, now.day);
      int expired = 0;
      for (final dynamic c in activeCust) {
        if (c is! Map<String, dynamic>) continue;
        final String? expRaw = c['expiration_date']?.toString();
        if (expRaw == null || expRaw.isEmpty) continue;
        final DateTime? exp = DateTime.tryParse(expRaw);
        if (exp != null && exp.isBefore(todayOnly)) expired++;
      }
      customersExpired = expired;

      // Trainers status-based counts
      trainersActive =
          trainers
              .where((t) => (t['status'] ?? '').toLowerCase() != 'inactive')
              .length;
      trainersArchived = trainers.length - trainersActive;

      membershipTotals = memTotals;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load report: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    // Refresh both overall report and customers when returning from other pages
    await Future.wait([_loadOverallReport(), _loadCustomers()]);
  }

  Future<void> _loadCustomers() async {
    try {
      final result = await ApiService.getCustomersByStatusWithPasswords(
        status: 'active',
      );

      if (result['success'] == true && result['data'] != null) {
        List<Map<String, dynamic>> loadedCustomers = [];

        for (var customerData in result['data']) {
          final customer = _convertCustomerData(customerData);
          loadedCustomers.add(customer);
        }

        if (mounted) {
          setState(() {
            _customers = loadedCustomers;
          });
        }
      }
    } catch (e) {
      debugPrint('_loadCustomers error: $e');
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
      if (val.startsWith('half') && val.contains('month')) return 'Half Month';
      return 'Monthly';
    }

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

    // Check if membership is expired
    final DateTime now = DateTime.now();
    final DateTime todayOnly = DateTime(now.year, now.month, now.day);
    final bool isExpired = expirationDate.isBefore(todayOnly);

    return {
      'name':
          '${customerData['first_name'] ?? ''} ${customerData['last_name'] ?? ''}'
              .trim(),
      'contactNumber': PhoneFormatter.formatWithSpaces(
        customerData['phone_number'] ?? 'Not provided',
      ),
      'membershipType': membershipType,
      'expirationDate': expirationDate,
      'startDate': startDate,
      'email': customerData['email'] ?? '',
      'fullName':
          '${customerData['first_name'] ?? ''} ${customerData['last_name'] ?? ''}'
              .trim(),
      'customerId': customerData['customer_id'] ?? customerData['id'],
      'isExpired': isExpired,
      'status': customerData['status'] ?? 'active',
    };
  }

  // Returns the list currently visible, filtered by search
  List<Map<String, dynamic>> _getVisibleCustomers() {
    final String q = '';
    final List<Map<String, dynamic>> filtered =
        _customers.where((c) {
          // Only show active customers (not archived)
          final String status =
              (c['status'] ?? 'active').toString().toLowerCase();
          if (status != 'active') return false;

          final String name =
              (c['name'] ?? c['fullName'] ?? '').toString().toLowerCase();
          final String contact =
              (c['contactNumber'] ?? c['phone_number'] ?? '')
                  .toString()
                  .toLowerCase();
          final String customerId =
              (c['customerId'] ?? '').toString().toLowerCase();
          final bool matchesSearch =
              q.isEmpty ||
              name.contains(q) ||
              contact.contains(q) ||
              customerId.contains(q);
          if (!matchesSearch) return false;
          if (_membershipFilter == 'All') return true;
          final String type =
              (c['membershipType'] ?? c['membership_type'] ?? '')
                  .toString()
                  .toLowerCase();
          if (_membershipFilter == 'Daily') return type == 'daily';
          if (_membershipFilter == 'Monthly')
            return type == 'monthly' || type.isEmpty;
          return type.replaceAll(' ', '') == 'halfmonth' ||
              (type.startsWith('half') && type.contains('month'));
        }).toList();

    // Expired-only filter (applied after membership/search filters)
    List<Map<String, dynamic>> result = filtered;
    if (_showExpiredOnly) {
      result =
          filtered.where((c) {
            return c['isExpired'] == true;
          }).toList();
    } else if (_showNotExpiredOnly) {
      result =
          filtered.where((c) {
            return c['isExpired'] != true;
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

  // Header cell with dropdown for membership filter
  Widget _buildMembershipHeader() {
    return Container(
      width: double.infinity,
      child: FittedBox(
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
                    PopupMenuItem(
                      value: 'Half Month',
                      child: Text('Half Month'),
                    ),
                    PopupMenuItem(value: 'Monthly', child: Text('Monthly')),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  // Header cell with dropdown for expiration filter
  Widget _buildExpirationHeader() {
    return Container(
      width: double.infinity,
      child: FittedBox(
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
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text('Not Expired Only'),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  // Build styled phone number button for desktop view
  Widget _buildPhoneNumberButton(String phoneNumber) {
    if (phoneNumber == 'N/A' ||
        phoneNumber.isEmpty ||
        phoneNumber == 'Not provided') {
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

  Future<void> _exportOverallReport(BuildContext context) async {
    final rows = <List<dynamic>>[
      ['Section', 'Metric', 'Value'],
      ['Products', 'Active', productsActive],
      ['Products', 'Archived', productsArchived],
      ['Admins', 'Active', adminsActive],
      ['Admins', 'Archived', adminsArchived],
      ['Customers', 'Active', customersActive],
      ['Customers', 'Archived', customersArchived],
      ['Customers', 'Expired (of Active)', customersExpired],
      ['Trainers', 'Active', trainersActive],
      ['Trainers', 'Archived', trainersArchived],
      ['Memberships', 'Daily', membershipTotals['Daily'] ?? 0],
      ['Memberships', 'Half Month', membershipTotals['Half Month'] ?? 0],
      ['Memberships', 'Monthly', membershipTotals['Monthly'] ?? 0],
    ];

    // Build customer table rows matching on-screen columns
    final customerTableRows = <List<dynamic>>[
      [
        'Customer ID',
        'Name',
        'Contact Number',
        'Membership Type',
        'Membership Start Date',
        'Expiration Date',
      ],
      ..._getVisibleCustomers().map((c) {
        final String id = '#${c['customerId'] ?? 'N/A'}';
        final String name = c['name'] ?? '';
        final String contact = c['contactNumber'] ?? 'N/A';
        final String membership = c['membershipType'] ?? '';
        final String start = _formatExpirationDate(c['startDate'] as DateTime);
        final String exp = _formatExpirationDate(
          c['expirationDate'] as DateTime,
        );
        final bool isExpired = c['isExpired'] == true;
        return [id, name, contact, membership, start, exp, isExpired];
      }),
    ];

    // Fetch weekly memberships data
    Map<String, int> weeklyMemberships = {};
    try {
      weeklyMemberships = await ApiService.getNewMembersThisWeek();
    } catch (e) {
      // If weekly data fails, continue with empty data
      weeklyMemberships = {
        'Monday': 0,
        'Tuesday': 0,
        'Wednesday': 0,
        'Thursday': 0,
        'Friday': 0,
        'Saturday': 0,
        'Sunday': 0,
      };
    }

    // Fetch monthly memberships data
    Map<String, int> monthlyMemberships = {};
    try {
      monthlyMemberships = await ApiService.getNewMembersThisMonth();
    } catch (e) {
      // If monthly data fails, continue with empty data
      monthlyMemberships = {'1': 0, '2': 0, '3': 0, '4': 0};
    }

    await exportStatsToPDF(
      context,
      title: 'Status Change Report',
      rows: rows,
      customerTableRows: customerTableRows,
      weeklyMemberships: weeklyMemberships,
      monthlyMemberships: monthlyMemberships,
      membershipTotals: membershipTotals,
      expiredMemberships: customersExpired,
    );
  }

  Widget _buildCustomerTable() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: const Text(
                    'Customer ID',
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
              ],
            ),
          ),
          // Data Rows
          ..._getVisibleCustomers().map((customer) {
            final expirationDate = customer['expirationDate'] as DateTime;
            final startDate = customer['startDate'] as DateTime;
            final formattedExpiry = _formatExpirationDate(expirationDate);
            final formattedStart = _formatExpirationDate(startDate);
            final bool isExpired = customer['isExpired'] == true;
            final membershipType = customer['membershipType'] as String;
            return Column(
              children: [
                Container(
                  color: isExpired ? Colors.red.shade50 : null,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 8,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              '#${customer['customerId'] ?? 'N/A'}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
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
                                color: _getMembershipTypeColor(membershipType),
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
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  formattedExpiry,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        isExpired ? Colors.red : Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (isExpired) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
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
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
              ],
            );
          }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Unregister from refresh service
    RefreshService().unregisterRefreshCallback(_refreshData);

    _kpiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        // Refresh data when this page gains focus (e.g., returning from customers.dart)
        if (hasFocus) {
          _refreshData();
        }
      },
      child: Scaffold(
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
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip:
                                _navCollapsed
                                    ? 'Open Sidebar'
                                    : 'Close Sidebar',
                            onPressed:
                                () => setState(
                                  () => _navCollapsed = !_navCollapsed,
                                ),
                            icon: Icon(
                              _navCollapsed ? Icons.menu : Icons.chevron_left,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Status Change Report',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () => _exportOverallReport(context),
                            icon: Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            label: const Text('Export PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_errorMessage != null)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadOverallReport,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // LEFT MAIN COLUMN
                              Expanded(
                                child: ListView(
                                  padding: EdgeInsets.zero,
                                  children: [
                                    // KPI ribbon
                                    _KpiRibbonGroups(
                                      controller: _kpiController,
                                      groups: [
                                        _KpiGroup(
                                          title: 'Admins',
                                          top: _KpiTile(
                                            label: 'Admins Active',
                                            value: adminsActive,
                                            color: const Color(0xFF2E7D32),
                                          ),
                                          bottom: _KpiTile(
                                            label: 'Admins Archived',
                                            value: adminsArchived,
                                            color: const Color(0xFFFB8C00),
                                          ),
                                        ),
                                        _KpiGroup(
                                          title: 'Trainers',
                                          top: _KpiTile(
                                            label: 'Trainers Active',
                                            value: trainersActive,
                                            color: const Color(0xFF2E7D32),
                                          ),
                                          bottom: _KpiTile(
                                            label: 'Trainers Archived',
                                            value: trainersArchived,
                                            color: const Color(0xFFFB8C00),
                                          ),
                                        ),
                                        _KpiGroup(
                                          title: 'Customers',
                                          top: _KpiTile(
                                            label: 'Customers Active',
                                            value: customersActive,
                                            color: const Color(0xFF2E7D32),
                                          ),
                                          bottom: _KpiTile(
                                            label: 'Customers Archived',
                                            value: customersArchived,
                                            color: const Color(0xFFFB8C00),
                                          ),
                                        ),
                                        _KpiGroup(
                                          title: 'Products',
                                          top: _KpiTile(
                                            label: 'Products Active',
                                            value: productsActive,
                                            color: const Color(0xFF2E7D32),
                                          ),
                                          bottom: _KpiTile(
                                            label: 'Products Archived',
                                            value: productsArchived,
                                            color: const Color(0xFFFB8C00),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Customer table
                                    _buildCustomerTable(),
                                    const SizedBox(height: 16),
                                    // Charts area
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        // Full-width first chart to occupy space
                                        return Wrap(
                                          spacing: 24,
                                          runSpacing: 24,
                                          children: [
                                            SizedBox(
                                              width: constraints.maxWidth,
                                              child: Card(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                elevation: 2,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    16.0,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            _startsView ==
                                                                    'Week'
                                                                ? 'New Memberships this Week'
                                                                : 'New Memberships this Month',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                          ),
                                                          const Spacer(),
                                                          PopupMenuButton<
                                                            String
                                                          >(
                                                            tooltip: 'Filter',
                                                            onSelected:
                                                                (v) => setState(
                                                                  () =>
                                                                      _startsView =
                                                                          v,
                                                                ),
                                                            itemBuilder:
                                                                (
                                                                  context,
                                                                ) => const [
                                                                  PopupMenuItem(
                                                                    value:
                                                                        'Week',
                                                                    child: Text(
                                                                      'Week',
                                                                    ),
                                                                  ),
                                                                  PopupMenuItem(
                                                                    value:
                                                                        'Month',
                                                                    child: Text(
                                                                      'Month',
                                                                    ),
                                                                  ),
                                                                ],
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .chevron_right,
                                                                  size: 18,
                                                                  color:
                                                                      Colors
                                                                          .black54,
                                                                ),
                                                                const SizedBox(
                                                                  width: 6,
                                                                ),
                                                                Text(
                                                                  _startsView,
                                                                  style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                                const Icon(
                                                                  Icons
                                                                      .arrow_drop_down,
                                                                  size: 18,
                                                                  color:
                                                                      Colors
                                                                          .black87,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      SizedBox(
                                                        height: 260,
                                                        child:
                                                            _startsView ==
                                                                    'Week'
                                                                ? const NewMembersBarGraph()
                                                                : const NewMembersMonthBarGraph(),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // removed Memberships Report pie chart
                                            _ChartCard(
                                              title: 'Membership Totals',
                                              child: MembershipsTotalBarGraph(
                                                daily:
                                                    membershipTotals['Daily'] ??
                                                    0,
                                                halfMonth:
                                                    membershipTotals['Half Month'] ??
                                                    0,
                                                monthly:
                                                    membershipTotals['Monthly'] ??
                                                    0,
                                                expired: customersExpired,
                                              ),
                                              width: constraints.maxWidth,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Old KPI card components removed in favor of the ribbon tiles above

// Redesigned components for dashboard layout

class _KpiTile {
  final String label;
  final int value;
  final Color color;
  const _KpiTile({
    required this.label,
    required this.value,
    required this.color,
  });
}

// (legacy) _KpiRibbon removed; replaced by grouped version below

class _RibbonArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RibbonArrow({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: onTap == null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withAlpha(0), Colors.white],
              begin:
                  icon == Icons.chevron_left
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
              end:
                  icon == Icons.chevron_left
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: Colors.black54),
        ),
      ),
    );
  }
}

// Grouped KPI ribbon (two stacked tiles per entity)
class _KpiGroup {
  final String title;
  final _KpiTile top;
  final _KpiTile bottom;
  const _KpiGroup({
    required this.title,
    required this.top,
    required this.bottom,
  });
}

class _KpiRibbonGroups extends StatelessWidget {
  final List<_KpiGroup> groups;
  final ScrollController? controller;
  const _KpiRibbonGroups({required this.groups, this.controller});

  @override
  Widget build(BuildContext context) {
    Widget tile(_KpiTile t) => Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.color.withAlpha(64)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: t.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.value.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                t.label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Stack(
          children: [
            Scrollbar(
              controller: controller,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: controller,
                scrollDirection: Axis.horizontal,
                child: Builder(
                  builder: (context) {
                    final double screenW = MediaQuery.of(context).size.width;
                    final double contentW =
                        (screenW - 360).clamp(300, screenW).toDouble();
                    return ConstrainedBox(
                      constraints: BoxConstraints(minWidth: contentW),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            groups
                                .map(
                                  (g) => Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 12,
                                            bottom: 4,
                                          ),
                                          child: Text(
                                            g.title,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        tile(g.top),
                                        tile(g.bottom),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _RibbonArrow(
                icon: Icons.chevron_left,
                onTap:
                    () => controller?.animateTo(
                      (controller!.offset - 260).clamp(
                        0,
                        controller!.position.maxScrollExtent,
                      ),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _RibbonArrow(
                icon: Icons.chevron_right,
                onTap:
                    () => controller?.animateTo(
                      (controller!.offset + 260).clamp(
                        0,
                        controller!.position.maxScrollExtent,
                      ),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final double width;
  const _ChartCard({
    required this.title,
    required this.child,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(height: 260, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// Removed _MiniMetric (replaced by donut chart)
