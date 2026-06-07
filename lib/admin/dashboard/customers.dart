import 'package:flutter/material.dart';
import 'dart:async';
import '../sidenav.dart';
import '../modal/customer_view_edit_modal.dart';
import '../modal/timein_timeout_history_modal.dart';
import '../modal/renew_membership_history_modal.dart';
import '../services/api_service.dart';
import '../services/refresh_service.dart';
import '../../PH phone number valid/phone_formatter.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
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
  static const TextStyle _tableHeaderTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  bool _navCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _countdownTimer;
  final Set<int> _selectedCustomerIds = {};
  static const int _pageSize = 20;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _searchController.dispose();
    super.dispose();
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
      try {
        final res = await ApiService.archiveCustomer(id: id);
        if (!mounted) return;

        if (res['success'] == true) {
          setState(() {
            _customers.removeWhere(
              (c) => c['customerId'] == customer['customerId'],
            );
            _archivedCustomers.add(customer);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${customer['name'] ?? 'Customer'} has been archived',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          RefreshService().triggerRefresh();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Failed to archive customer'),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmAndArchiveSelected() async {
    if (_selectedCustomerIds.isEmpty) return;
    final selectedCustomers =
        _customers
            .where((c) => _selectedCustomerIds.contains(_getCustomerId(c)))
            .toList();
    if (selectedCustomers.isEmpty) {
      setState(() => _selectedCustomerIds.clear());
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Archive selected members?'),
            content: Text(
              'This will archive ${selectedCustomers.length} member(s). They can be restored later.',
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

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    int successCount = 0;
    final List<String> failedNames = [];
    final Set<int> archivedIds = {};

    for (final customer in selectedCustomers) {
      final int id = _getCustomerId(customer);
      if (id <= 0) {
        failedNames.add(customer['name'] ?? 'Unknown');
        continue;
      }
      final res = await ApiService.archiveCustomer(id: id);
      if (res['success'] == true) {
        successCount += 1;
        archivedIds.add(id);
      } else {
        failedNames.add(customer['name'] ?? 'Unknown');
      }
    }

    if (mounted) {
      setState(() {
        _customers.removeWhere((c) => archivedIds.contains(_getCustomerId(c)));
        _archivedCustomers.addAll(
          selectedCustomers.where(
            (c) => archivedIds.contains(_getCustomerId(c)),
          ),
        );
        _selectedCustomerIds.removeAll(archivedIds);
        _isLoading = false;
      });
    }

    if (!mounted) return;
    if (successCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Archived $successCount member(s)${failedNames.isNotEmpty ? ' (${failedNames.length} failed)' : ''}.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      RefreshService().triggerRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failedNames.isNotEmpty
                ? 'Failed to archive: ${failedNames.join(', ')}'
                : 'Failed to archive selected members',
          ),
        ),
      );
    }
  }

  Future<void> _confirmAndRestoreSelected() async {
    if (_selectedCustomerIds.isEmpty) return;
    final selectedCustomers =
        _archivedCustomers
            .where((c) => _selectedCustomerIds.contains(_getCustomerId(c)))
            .toList();
    if (selectedCustomers.isEmpty) {
      setState(() => _selectedCustomerIds.clear());
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Restore selected members?'),
            content: Text(
              'This will restore ${selectedCustomers.length} member(s) to active.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Restore'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    int successCount = 0;
    final List<String> failedNames = [];
    final Set<int> restoredIds = {};

    for (final customer in selectedCustomers) {
      final int id = _getCustomerId(customer);
      if (id <= 0) {
        failedNames.add(customer['name'] ?? 'Unknown');
        continue;
      }
      final res = await ApiService.restoreCustomer(id: id);
      if (res['success'] == true) {
        successCount += 1;
        restoredIds.add(id);
      } else {
        failedNames.add(customer['name'] ?? 'Unknown');
      }
    }

    if (mounted) {
      setState(() {
        _archivedCustomers.removeWhere(
          (c) => restoredIds.contains(_getCustomerId(c)),
        );
        _customers.addAll(
          selectedCustomers.where(
            (c) => restoredIds.contains(_getCustomerId(c)),
          ),
        );
        _selectedCustomerIds.removeAll(restoredIds);
        _isLoading = false;
      });
    }

    if (!mounted) return;
    if (successCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restored $successCount member(s)${failedNames.isNotEmpty ? ' (${failedNames.length} failed)' : ''}.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      RefreshService().triggerRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failedNames.isNotEmpty
                ? 'Failed to restore: ${failedNames.join(', ')}'
                : 'Failed to restore selected members',
          ),
        ),
      );
    }
  }

  void _showArchivedCustomers() {
    setState(() {
      _showArchived = !_showArchived;
      _selectedCustomerIds.clear();
      _pageIndex = 0;
    });
  }

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
          // Half Month check allows minor variations
          return type.replaceAll(' ', '') == 'halfmonth' ||
              (type.startsWith('half') && type.contains('month'));
        }).toList();

    List<Map<String, dynamic>> result = filtered;
    if (_showExpiredOnly) {
      result = filtered.where(_isCustomerExpired).toList();
    } else if (_showNotExpiredOnly) {
      result = filtered.where((c) => !_isCustomerExpired(c)).toList();
    }

    result.sort(_compareCustomersByStatusAndExpiration);

    return result;
  }

  int get _customerTotalPages {
    final int count = _getVisibleCustomers().length;
    if (count == 0) return 1;
    return (count / _pageSize).ceil();
  }

  int get _safeCustomerPageIndex =>
      _pageIndex.clamp(0, _customerTotalPages - 1);

  List<Map<String, dynamic>> _getPaginatedCustomers() {
    final List<Map<String, dynamic>> visible = _getVisibleCustomers();
    if (visible.length <= _pageSize) return visible;
    final int start = _safeCustomerPageIndex * _pageSize;
    final int end = (start + _pageSize).clamp(0, visible.length);
    return visible.sublist(start, end);
  }

  void _goToCustomerPage(int page) {
    setState(() {
      _pageIndex = page.clamp(0, _customerTotalPages - 1);
    });
  }

  Widget _buildCustomersPagination({bool compact = false}) {
    final int total = _getVisibleCustomers().length;
    if (total <= _pageSize) return const SizedBox.shrink();

    final int totalPages = _customerTotalPages;
    final int page = _safeCustomerPageIndex;
    final int start = page * _pageSize + 1;
    final int end = ((page + 1) * _pageSize).clamp(0, total);
    final bool canPrev = page > 0;
    final bool canNext = page < totalPages - 1;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child:
          compact
              ? Column(
                children: [
                  Text(
                    'Showing $start–$end of $total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPaginationIconButton(
                        icon: Icons.chevron_left,
                        enabled: canPrev,
                        onPressed: () => _goToCustomerPage(page - 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '${page + 1} / $totalPages',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      _buildPaginationIconButton(
                        icon: Icons.chevron_right,
                        enabled: canNext,
                        onPressed: () => _goToCustomerPage(page + 1),
                      ),
                    ],
                  ),
                ],
              )
              : Row(
                children: [
                  Text(
                    'Showing $start–$end of $total',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  _buildPaginationIconButton(
                    icon: Icons.chevron_left,
                    enabled: canPrev,
                    onPressed: () => _goToCustomerPage(page - 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${page + 1} / $totalPages',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildPaginationIconButton(
                    icon: Icons.chevron_right,
                    enabled: canNext,
                    onPressed: () => _goToCustomerPage(page + 1),
                  ),
                ],
              ),
    );
  }

  Widget _buildPaginationIconButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: icon == Icons.chevron_left ? 'Previous page' : 'Next page',
      onPressed: enabled ? onPressed : null,
      icon: Icon(
        icon,
        size: 22,
        color: enabled ? Colors.black87 : Colors.grey.shade400,
      ),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
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
    try {
      final res = await ApiService.restoreCustomer(id: id);
      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          _archivedCustomers.removeWhere(
            (c) => c['customerId'] == customer['customerId'],
          );
          _customers.add(customer);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${customer['name'] ?? 'Customer'} has been restored',
            ),
            backgroundColor: Colors.green,
          ),
        );
        RefreshService().triggerRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to restore customer'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getCustomersByStatusWithPasswords(
        status: 'active',
      );

      if (result['success'] == true && result['data'] != null) {
        final List<Map<String, dynamic>> loadedCustomers = [];

        for (final customerData in result['data']) {
          loadedCustomers.add(_convertCustomerData(customerData));
        }

        final archivedResult = await ApiService.getCustomersByStatus(
          status: 'inactive',
        );
        final List<Map<String, dynamic>> loadedArchivedCustomers = [];

        if (archivedResult['success'] == true &&
            archivedResult['data'] != null) {
          for (final customerData in archivedResult['data']) {
            loadedArchivedCustomers.add(_convertCustomerData(customerData));
          }
        }

        if (mounted) {
          setState(() {
            _customers = loadedCustomers;
            _archivedCustomers = loadedArchivedCustomers;
            _isLoading = false;
            _selectedCustomerIds.clear();
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

      // Backward compatibility: older Daily records may be stored as date-only.
      // Treat them as 9:00 PM local closing time.
      if (membershipType == 'Daily' &&
          expirationRaw != null &&
          expirationRaw.isNotEmpty) {
        final bool hasExplicitTime =
            expirationRaw.contains(':') || expirationRaw.contains('T');
        if (!hasExplicitTime) {
          expirationDate = DateTime(
            expirationDate.year,
            expirationDate.month,
            expirationDate.day,
            21,
            0,
            0,
          );
        }
      }
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
      'birthdate': customerData['birthdate'],
      'emergencyContactName': customerData['emergency_contact_name'] ?? '',
      'emergencyContactPhone': PhoneFormatter.formatWithSpaces(
        customerData['emergency_contact_number'] ?? '',
      ),
      'customerId': customerData['customer_id'] ?? customerData['id'],
      'createdAt':
          customerData['customer_created_at'] ?? customerData['created_at'],
      'first_name': customerData['first_name'],
      'last_name': customerData['last_name'],
      'middle_name': customerData['middle_name'],
      'phone_number': customerData['phone_number'],
      'emergency_contact_name': customerData['emergency_contact_name'],
      'emergency_contact_number': customerData['emergency_contact_number'],
      'address_details': customerData['address_details'],
      'address': customerData['address'],
      'password': customerData['password'],
      'membership': membership,
      'membership_type': membershipType,
      'start_date': startRaw,
      'expiration_date': expirationRaw,
      'status': customerData['status'],
    };
  }

  bool _isCustomerExpired(Map<String, dynamic> customer) {
    final DateTime exp = customer['expirationDate'] as DateTime;
    final String membershipType = (customer['membershipType'] ?? '').toString();
    final DateTime now = DateTime.now();
    if (membershipType == 'Daily') {
      return !exp.isAfter(now);
    }
    final DateTime todayOnly = DateTime(now.year, now.month, now.day);
    return exp.isBefore(todayOnly);
  }

  int _compareCustomersByStatusAndExpiration(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final bool aExpired = _isCustomerExpired(a);
    final bool bExpired = _isCustomerExpired(b);
    if (aExpired != bExpired) {
      return aExpired ? 1 : -1;
    }

    final DateTime aExp = a['expirationDate'] as DateTime;
    final DateTime bExp = b['expirationDate'] as DateTime;
    if (aExpired) {
      return bExp.compareTo(aExp);
    }
    return aExp.compareTo(bExp);
  }

  void _sortCustomersByExpiration() {
    if (_customers.isNotEmpty) {
      _customers.sort(_compareCustomersByStatusAndExpiration);
    }
  }

  int _getCustomerId(Map<String, dynamic> customer) {
    final dynamic idVal = customer['customerId'];
    final int id = idVal is int ? idVal : int.tryParse(idVal.toString()) ?? -1;
    return id;
  }

  bool _isCustomerSelected(Map<String, dynamic> customer) {
    final int id = _getCustomerId(customer);
    if (id <= 0) return false;
    return _selectedCustomerIds.contains(id);
  }

  void _toggleCustomerSelection(Map<String, dynamic> customer) {
    final int id = _getCustomerId(customer);
    if (id <= 0) return;
    setState(() {
      if (_selectedCustomerIds.contains(id)) {
        _selectedCustomerIds.remove(id);
      } else {
        _selectedCustomerIds.add(id);
      }
    });
  }

  bool _isAllVisibleSelected() {
    final visible = _getVisibleCustomers();
    final ids = visible.map(_getCustomerId).where((id) => id > 0).toList();
    if (ids.isEmpty) return false;
    return ids.every(_selectedCustomerIds.contains);
  }

  bool _isSomeVisibleSelected() {
    final visible = _getVisibleCustomers();
    final ids = visible.map(_getCustomerId).where((id) => id > 0).toList();
    if (ids.isEmpty) return false;
    return ids.any(_selectedCustomerIds.contains) && !_isAllVisibleSelected();
  }

  void _toggleSelectAllVisible(bool? isChecked) {
    final visible = _getVisibleCustomers();
    final ids = visible.map(_getCustomerId).where((id) => id > 0).toList();
    setState(() {
      if (isChecked == true) {
        _selectedCustomerIds.addAll(ids);
      } else {
        _selectedCustomerIds.removeAll(ids);
      }
    });
  }

  String _formatExpirationDate(
    DateTime date, {
    String? membershipType,
    bool isStartDate = false,
  }) {
    final String dd = date.day.toString().padLeft(2, '0');
    final String mm = date.month.toString().padLeft(2, '0');
    final String yyyy = date.year.toString().padLeft(4, '0');

    // For Daily memberships, show only time for expiration
    if (membershipType == 'Daily' && !isStartDate) {
      final int hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final String hh = hour12.toString().padLeft(2, '0');
      final String min = date.minute.toString().padLeft(2, '0');
      final String period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hh:$min $period';
    }

    return '$mm/$dd/$yyyy';
  }

  Widget _buildMembershipHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Flexible(
          child: Text(
            'Membership',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _tableHeaderTextStyle,
          ),
        ),
        const SizedBox(width: 2),
        PopupMenuButton<String>(
          tooltip: 'Filter membership type',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          icon: const Icon(Icons.arrow_drop_down, size: 16),
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
    );
  }

  Widget _buildExpirationHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Flexible(
          child: Text(
            'Expiration',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _tableHeaderTextStyle,
          ),
        ),
        const SizedBox(width: 2),
        PopupMenuButton<String>(
          tooltip: 'Filter expiration',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          icon: const Icon(Icons.arrow_drop_down, size: 16),
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
                _pageIndex = 0;
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
                        color: Colors.red,
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
                      Text('Active Members'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildHeaderLabel(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _tableHeaderTextStyle,
    );
  }

  Widget _buildHeaderCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Center(child: child),
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

  Widget _buildSearchField({required bool compact}) {
    void onSearchChanged(String val) {
      setState(() {
        _searchQuery = val;
        _pageIndex = 0;
      });
    }

    if (compact) {
      return SizedBox(
        height: 38,
        child: TextField(
          controller: _searchController,
          onChanged: onSearchChanged,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            prefixIcon: const Icon(
              Icons.search,
              size: 18,
              color: Colors.black54,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            isDense: true,
          ),
        ),
      );
    }

    return SizedBox(
      width: 560,
      height: 42,
      child: TextField(
        controller: _searchController,
        onChanged: onSearchChanged,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black54),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black26),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      drawer:
          isMobile
              ? Drawer(
                width: _drawerWidth,
                child: SideNav(
                  width: _drawerWidth,
                  onClose: () => Navigator.of(context).pop(),
                ),
              )
              : null,
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile)
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                width: _navCollapsed ? 0 : _drawerWidth,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    maxWidth: _drawerWidth,
                    minWidth: _drawerWidth,
                    child: SideNav(
                      width: _drawerWidth,
                      onClose: () => setState(() => _navCollapsed = true),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: const BoxDecoration(color: Colors.white),
                child: Column(children: [Expanded(child: _buildBody())]),
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
          ],
        ),
      );
    }

    return isMobile
        ? Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Open Menu',
                        onPressed:
                            () => _scaffoldKey.currentState?.openDrawer(),
                        icon: const Icon(Icons.menu),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _showArchived ? 'Archived Members' : 'Members',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSearchField(compact: true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          () => setState(() {
                            _showExpiredOnly = !_showExpiredOnly;
                            _showNotExpiredOnly = false;
                            _pageIndex = 0;
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
                              _pageIndex = 0;
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
                  ..._getPaginatedCustomers().map((customer) {
                    final expirationDate =
                        customer['expirationDate'] as DateTime;
                    final startDate = customer['startDate'] as DateTime;
                    final membershipType = customer['membershipType'] as String;
                    final formattedExpiry = _formatExpirationDate(
                      expirationDate,
                      membershipType: membershipType,
                    );
                    final formattedStart = _formatExpirationDate(
                      startDate,
                      membershipType: membershipType,
                      isStartDate: true,
                    );
                    final bool _isExpiredM = _isCustomerExpired(customer);
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 220,
                                            ),
                                            child: Text(
                                              customer['name'] ?? '',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.blue.shade200,
                                              ),
                                            ),
                                            child: Text(
                                              '#${customer['customerId'] ?? 'N/A'}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
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
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                                            RefreshService().triggerRefresh();
                                          }
                                        },
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        constraints: const BoxConstraints(
                                          minWidth: 34,
                                          minHeight: 34,
                                        ),
                                        tooltip: 'View / Edit',
                                      ),
                                    ),
                                    const SizedBox(width: 6),
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
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        constraints: const BoxConstraints(
                                          minWidth: 34,
                                          minHeight: 34,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
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
                                      membershipType == 'Daily'
                                          ? Text(
                                            formattedExpiry,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  _isExpiredM
                                                      ? Colors.red
                                                      : Colors.black87,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                          : Text(
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
                  _buildCustomersPagination(compact: true),
                ],
              ),
            ),
          ],
        )
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _showArchived ? 'Archived Members' : 'Members',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildSearchField(compact: false),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed:
                            _selectedCustomerIds.isEmpty
                                ? null
                                : _showArchived
                                ? _confirmAndRestoreSelected
                                : _confirmAndArchiveSelected,
                        icon: Icon(
                          _showArchived
                              ? Icons.settings_backup_restore_rounded
                              : Icons.archive_outlined,
                          color: _showArchived ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        label: Text(
                          _selectedCustomerIds.isEmpty
                              ? _showArchived
                                  ? 'Restore Selected'
                                  : 'Archive Selected'
                              : _showArchived
                              ? 'Restore Selected (${_selectedCustomerIds.length})'
                              : 'Archive Selected (${_selectedCustomerIds.length})',
                        ),
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
                      const SizedBox(width: 12),
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
                      const Spacer(),
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
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                            SizedBox(
                              width: 48,
                              child: Center(
                                child: Checkbox(
                                  value:
                                      _isAllVisibleSelected()
                                          ? true
                                          : _isSomeVisibleSelected()
                                          ? null
                                          : false,
                                  tristate: true,
                                  onChanged: _toggleSelectAllVisible,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _buildHeaderCell(
                                      _buildHeaderLabel('ID'),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: _buildHeaderCell(
                                      _buildHeaderLabel('Name'),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: _buildHeaderCell(
                                      _buildHeaderLabel('Contact Number'),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: _buildHeaderCell(
                                      _buildMembershipHeader(),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: _buildHeaderCell(
                                      _buildHeaderLabel('Start Date'),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: _buildHeaderCell(
                                      _buildExpirationHeader(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 200,
                              child: _buildHeaderCell(
                                _buildHeaderLabel('Actions'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._getPaginatedCustomers().map((customer) {
                        final expirationDate =
                            customer['expirationDate'] as DateTime;
                        final startDate = customer['startDate'] as DateTime;
                        final membershipType =
                            customer['membershipType'] as String;
                        final formattedExpiry = _formatExpirationDate(
                          expirationDate,
                          membershipType: membershipType,
                        );
                        final formattedStart = _formatExpirationDate(
                          startDate,
                          membershipType: membershipType,
                          isStartDate: true,
                        );
                        final DateTime nowDate = DateTime.now();
                        // For Daily memberships, compare with current time including hours/minutes
                        // Expires at or after 9 PM (inclusive)
                        // For other memberships, compare with start of day
                        final bool isExpired =
                            membershipType == 'Daily'
                                ? !expirationDate.isAfter(nowDate)
                                : expirationDate.isBefore(
                                  DateTime(
                                    nowDate.year,
                                    nowDate.month,
                                    nowDate.day,
                                  ),
                                );
                        return Column(
                          children: [
                            Container(
                              color: isExpired ? Colors.red.shade50 : null,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 48,
                                    child:
                                        _selectedCustomerIds.isNotEmpty
                                            ? Center(
                                              child: Checkbox(
                                                value: _isCustomerSelected(
                                                  customer,
                                                ),
                                                onChanged:
                                                    (_) =>
                                                        _toggleCustomerSelection(
                                                          customer,
                                                        ),
                                              ),
                                            )
                                            : const SizedBox.shrink(),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap:
                                          () => _toggleCustomerSelection(
                                            customer,
                                          ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                    horizontal: 6,
                                                  ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.blue.shade200,
                                                  ),
                                                ),
                                                child: Text(
                                                  '#${customer['customerId'] ?? 'N/A'}',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 15,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                    horizontal: 6,
                                                  ),
                                              child: Text(
                                                customer['name'] ?? '',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 4,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                    horizontal: 6,
                                                  ),
                                              child: _buildPhoneNumberButton(
                                                customer['contactNumber'] ??
                                                    'N/A',
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                    horizontal: 6,
                                                  ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  membershipType,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color:
                                                        _getMembershipTypeColor(
                                                          membershipType,
                                                        ),
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                    horizontal: 6,
                                                  ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  formattedStart,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                    horizontal: 6,
                                                  ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Builder(
                                                      builder: (context) {
                                                        final expiryText =
                                                            formattedExpiry;
                                                        final bool
                                                        isExpiredText =
                                                            isExpired;
                                                        return Text(
                                                          expiryText,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            color:
                                                                isExpiredText
                                                                    ? Colors.red
                                                                    : Colors
                                                                        .black87,
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        );
                                                      },
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
                                  SizedBox(
                                    width: 200,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.purple.shade50,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.purple.shade200,
                                            ),
                                          ),
                                          child: IconButton(
                                            onPressed:
                                                () => showMemberHistoryModal(
                                                  context,
                                                  customer,
                                                ),
                                            icon: Icon(
                                              Icons.access_time,
                                              size: 18,
                                              color: Colors.purple.shade700,
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(
                                              minWidth: 36,
                                              minHeight: 36,
                                            ),
                                            tooltip: 'Time In/Out History',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.shade50,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.indigo.shade200,
                                            ),
                                          ),
                                          child: IconButton(
                                            onPressed:
                                                () =>
                                                    showRenewMembershipHistoryModal(
                                                      context,
                                                      customer,
                                                    ),
                                            icon: Icon(
                                              Icons.autorenew_rounded,
                                              size: 18,
                                              color: Colors.indigo.shade700,
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(
                                              minWidth: 36,
                                              minHeight: 36,
                                            ),
                                            tooltip: 'Renew Membership History',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
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
                                              final result =
                                                  await CustomerViewEditModal.showCustomerModal(
                                                    context,
                                                    customer,
                                                  );
                                              if (result == true && mounted) {
                                                setState(() {});
                                                RefreshService()
                                                    .triggerRefresh();
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
                      _buildCustomersPagination(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
  }

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
          color: const Color(0xFFE8F5E8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone, size: 16, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 6),
            Text(
              phoneNumber,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
