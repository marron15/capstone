import 'package:flutter/material.dart';
import '../sidenav.dart';
import '../pdf/pdf_stats_export.dart';
import '../services/api_service.dart';
import '../services/admin_service.dart';
import '../services/refresh_service.dart';
import '../../services/attendance_service.dart';
import '../statistics/new_week_members.dart';
import '../statistics/new_members_month.dart';
import '../statistics/total_memberships.dart';
import '../statistics/new_members_today.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Simple filter UI state removed per request
  final ScrollController _kpiController = ScrollController();
  final ScrollController _tableScrollController = ScrollController();
  String _startsView = 'Week';
  String _kpiPeriodFilter = 'Daily'; // Daily | This Week | This Month
  final List<bool> _periodSelected = [true, false, false]; // Daily, Week, Month

  void _syncPeriodSelection() {
    _periodSelected[0] = _kpiPeriodFilter == 'Daily';
    _periodSelected[1] = _kpiPeriodFilter == 'This Week';
    _periodSelected[2] = _kpiPeriodFilter == 'This Month';
  }

  void _setGlobalPeriod(String period) {
    if (!mounted || _isDisposed) return;
    if (mounted && !_isDisposed) {
      setState(() {
        _kpiPeriodFilter = period;
        _syncPeriodSelection();
        if (period == 'Daily') _startsView = 'Day';
        if (period == 'This Week') _startsView = 'Week';
        if (period == 'This Month') _startsView = 'Month';
      });
    }
  }

  // Date helpers for filtering
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isThisWeek(DateTime d, DateTime now) {
    final int weekday = now.weekday; // 1..7 Mon..Sun
    final DateTime startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: weekday - 1));
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));
    return !d.isBefore(startOfWeek) && d.isBefore(endOfWeek);
  }

  bool _isThisMonth(DateTime d, DateTime now) {
    return d.year == now.year && d.month == now.month;
  }

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
  int reservationsAddedDay = 0,
      reservationsAddedWeek = 0,
      reservationsAddedMonth = 0;
  int reservationsPendingDay = 0,
      reservationsPendingWeek = 0,
      reservationsPendingMonth = 0;
  int reservationsAcceptedDay = 0,
      reservationsAcceptedWeek = 0,
      reservationsAcceptedMonth = 0;
  int reservationsDeclinedDay = 0,
      reservationsDeclinedWeek = 0,
      reservationsDeclinedMonth = 0;

  // KPI: added this day/week/month
  int adminsAddedDay = 0, adminsAddedWeek = 0, adminsAddedMonth = 0;
  int trainersAddedDay = 0, trainersAddedWeek = 0, trainersAddedMonth = 0;
  int customersAddedDay = 0, customersAddedWeek = 0, customersAddedMonth = 0;
  int productsAddedDay = 0, productsAddedWeek = 0, productsAddedMonth = 0;
  // Attendance KPI
  int timeInDay = 0, timeInWeek = 0, timeInMonth = 0;
  int timeOutDay = 0, timeOutWeek = 0, timeOutMonth = 0;
  Map<String, int> membershipTotals = const {};
  List<Map<String, dynamic>> _reservations = [];

  // Customer table data
  List<Map<String, dynamic>> _customers = [];
  String _membershipFilter = 'All';
  bool _showExpiredOnly = false;
  bool _showNotExpiredOnly = false;

  // Manual refresh only - no auto refresh timer
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    WidgetsBinding.instance.addObserver(this);

    // Register with refresh service
    RefreshService().registerRefreshCallback(_refreshData);

    _loadOverallReport();
    _loadCustomers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Removed automatic refresh to prevent setState after disposal
    // Focus widget handles refresh when returning from other pages
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted && !_isDisposed) {
      // Refresh data when app becomes active again
      // Use a small delay to ensure widget is fully mounted
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_isDisposed) {
          _refreshData();
        }
      });
    }
  }

  // Add a method to manually refresh data (can be called from other pages)
  void refreshCustomerData() {
    if (mounted && !_isDisposed) {
      _refreshData();
    }
  }

  Future<void> _loadOverallReport() async {
    if (!mounted || _isDisposed) return;

    if (mounted && !_isDisposed) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

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
        ApiService.getReservedProducts(),
        AttendanceService.fetchRecords(), // Fetch all attendance records
      ]);

      // Check if widget is still mounted after async operations
      if (!mounted || _isDisposed) return;

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
      final List<Map<String, dynamic>> reservations =
          (futures[7] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList();
      
      // Fetch attendance records
      final List<AttendanceRecord> attendanceRecords = futures[8] as List<AttendanceRecord>;

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

      // Compute added this day/week/month for each entity using created_at or similar fields
      DateTime? _parseCreatedAt(Map m) {
        String? raw =
            (m['customer_created_at'] ??
                    m['created_at'] ??
                    m['createdAt'] ??
                    m['date_created'] ??
                    m['createdDate'] ??
                    m['added_at'])
                ?.toString();
        return raw != null && raw.isNotEmpty ? DateTime.tryParse(raw) : null;
      }

      bool _isSameDay(DateTime a, DateTime b) {
        return a.year == b.year && a.month == b.month && a.day == b.day;
      }

      bool _isThisWeek(DateTime d, DateTime now) {
        final int weekday = now.weekday; // 1=Mon..7=Sun
        final DateTime startOfWeek = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: weekday - 1));
        final DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));
        return !d.isBefore(startOfWeek) && d.isBefore(endOfWeek);
      }

      bool _isThisMonth(DateTime d, DateTime now) {
        return d.year == now.year && d.month == now.month;
      }

      int _countAdded(Iterable items, DateTime now, String period) {
        int c = 0;
        for (final dynamic item in items) {
          if (item is! Map) continue;
          final DateTime? dt = _parseCreatedAt(item);
          if (dt == null) continue;
          if (period == 'Day' && _isSameDay(dt, now))
            c++;
          else if (period == 'Week' && _isThisWeek(dt, now))
            c++;
          else if (period == 'Month' && _isThisMonth(dt, now))
            c++;
        }
        return c;
      }

      final DateTime nowTs = DateTime.now();

      adminsAddedDay = _countAdded(admins, nowTs, 'Day');
      adminsAddedWeek = _countAdded(admins, nowTs, 'Week');
      adminsAddedMonth = _countAdded(admins, nowTs, 'Month');

      trainersAddedDay = _countAdded(trainers, nowTs, 'Day');
      trainersAddedWeek = _countAdded(trainers, nowTs, 'Week');
      trainersAddedMonth = _countAdded(trainers, nowTs, 'Month');

      // Customers: count by membership start_date instead of created_at
      // to match table and charts logic
      DateTime? _parseStartDate(Map m) {
        final dynamic membership = m['membership'];
        String? raw =
            (membership is Map ? membership['start_date'] : null)?.toString() ??
            m['start_date']?.toString() ??
            m['membership_start_date']?.toString();
        if (raw == null || raw.isEmpty) return null;
        return DateTime.tryParse(raw);
      }

      int _countByStart(Iterable items, DateTime now, String period) {
        int c = 0;
        for (final dynamic item in items) {
          if (item is! Map) continue;
          final DateTime? dt = _parseStartDate(item);
          if (dt == null) continue;
          if (period == 'Day' && _isSameDay(dt, now))
            c++;
          else if (period == 'Week' && _isThisWeek(dt, now))
            c++;
          else if (period == 'Month' && _isThisMonth(dt, now))
            c++;
        }
        return c;
      }

      // Customers data may be nested inside data arrays
      final Iterable custAll = [...activeCust, ...archivedCust];
      customersAddedDay = _countByStart(custAll, nowTs, 'Day');
      customersAddedWeek = _countByStart(custAll, nowTs, 'Week');
      customersAddedMonth = _countByStart(custAll, nowTs, 'Month');

      productsAddedDay = _countAdded(
        [...prodActive, ...prodInactive],
        nowTs,
        'Day',
      );
      productsAddedWeek = _countAdded(
        [...prodActive, ...prodInactive],
        nowTs,
        'Week',
      );
      productsAddedMonth = _countAdded(
        [...prodActive, ...prodInactive],
        nowTs,
        'Month',
      );
      Map<String, int> _countReservationsByStatus(String period) {
        final DateTime now = nowTs;
        int total = 0, pending = 0, accepted = 0, declined = 0;
        for (final reservation in reservations) {
          final DateTime? createdAt = _extractReservationDate(reservation);
          if (createdAt == null) continue;
          bool matches = false;
          if (period == 'Day') {
            matches = _isSameDay(createdAt, now);
          } else if (period == 'Week') {
            matches = _isThisWeek(createdAt, now);
          } else {
            matches = _isThisMonth(createdAt, now);
          }
          if (!matches) continue;
          total++;
          final String status = _reservationStatus(reservation);
          if (status == 'accepted') {
            accepted++;
          } else if (status == 'declined') {
            declined++;
          } else {
            pending++;
          }
        }
        return {
          'total': total,
          'pending': pending,
          'accepted': accepted,
          'declined': declined,
        };
      }

      final Map<String, int> reservationDayCounts = _countReservationsByStatus(
        'Day',
      );
      final Map<String, int> reservationWeekCounts = _countReservationsByStatus(
        'Week',
      );
      final Map<String, int> reservationMonthCounts =
          _countReservationsByStatus('Month');

      reservationsAddedDay = reservationDayCounts['total'] ?? 0;
      reservationsPendingDay = reservationDayCounts['pending'] ?? 0;
      reservationsAcceptedDay = reservationDayCounts['accepted'] ?? 0;
      reservationsDeclinedDay = reservationDayCounts['declined'] ?? 0;

      reservationsAddedWeek = reservationWeekCounts['total'] ?? 0;
      reservationsPendingWeek = reservationWeekCounts['pending'] ?? 0;
      reservationsAcceptedWeek = reservationWeekCounts['accepted'] ?? 0;
      reservationsDeclinedWeek = reservationWeekCounts['declined'] ?? 0;

      reservationsAddedMonth = reservationMonthCounts['total'] ?? 0;
      reservationsPendingMonth = reservationMonthCounts['pending'] ?? 0;
      reservationsAcceptedMonth = reservationMonthCounts['accepted'] ?? 0;
      reservationsDeclinedMonth = reservationMonthCounts['declined'] ?? 0;

      // Count Time In and Time Out by period
      int _countTimeIn(Iterable<AttendanceRecord> records, DateTime now, String period) {
        int count = 0;
        for (final record in records) {
          final DateTime? timeIn = record.timeIn;
          if (timeIn == null) continue;
          
          if (period == 'Day' && _isSameDay(timeIn, now)) {
            count++;
          } else if (period == 'Week' && _isThisWeek(timeIn, now)) {
            count++;
          } else if (period == 'Month' && _isThisMonth(timeIn, now)) {
            count++;
          }
        }
        return count;
      }
      
      int _countTimeOut(Iterable<AttendanceRecord> records, DateTime now, String period) {
        int count = 0;
        for (final record in records) {
          final DateTime? timeOut = record.timeOut;
          if (timeOut == null) continue;
          
          if (period == 'Day' && _isSameDay(timeOut, now)) {
            count++;
          } else if (period == 'Week' && _isThisWeek(timeOut, now)) {
            count++;
          } else if (period == 'Month' && _isThisMonth(timeOut, now)) {
            count++;
          }
        }
        return count;
      }
      
      timeInDay = _countTimeIn(attendanceRecords, nowTs, 'Day');
      timeInWeek = _countTimeIn(attendanceRecords, nowTs, 'Week');
      timeInMonth = _countTimeIn(attendanceRecords, nowTs, 'Month');
      
      timeOutDay = _countTimeOut(attendanceRecords, nowTs, 'Day');
      timeOutWeek = _countTimeOut(attendanceRecords, nowTs, 'Week');
      timeOutMonth = _countTimeOut(attendanceRecords, nowTs, 'Month');

      // Final check before setState
      if (!mounted || _isDisposed) return;

      if (mounted && !_isDisposed) {
        setState(() {
          _reservations =
              reservations.map((reservation) {
                final DateTime? createdAt = _extractReservationDate(
                  reservation,
                );
                return {...reservation, 'createdAt': createdAt};
              }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _errorMessage = 'Failed to load report: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    // Refresh both overall report and customers when returning from other pages
    if (!mounted || _isDisposed) return;
    try {
      await Future.wait([_loadOverallReport(), _loadCustomers()]);
    } catch (e) {
      // Silently handle errors if widget is disposed
      if (mounted && !_isDisposed) {
        debugPrint('Error refreshing data: $e');
      }
    }
  }

  Future<void> _loadCustomers() async {
    if (!mounted || _isDisposed) return;
    try {
      final result = await ApiService.getCustomersByStatusWithPasswords(
        status: 'active',
      );

      if (!mounted || _isDisposed) return;

      if (result['success'] == true && result['data'] != null) {
        List<Map<String, dynamic>> loadedCustomers = [];

        for (var customerData in result['data']) {
          final customer = _convertCustomerData(customerData);
          loadedCustomers.add(customer);
        }

        if (mounted && !_isDisposed) {
          setState(() {
            _customers = loadedCustomers;
          });
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        debugPrint('_loadCustomers error: $e');
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

  DateTime? _extractReservationDate(Map<String, dynamic> reservation) {
    final dynamic raw = reservation['createdAt'] ?? reservation['created_at'];
    if (raw is DateTime) return raw;
    if (raw == null) return null;
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  List<Map<String, dynamic>> _filterReservationsByPeriod(String period) {
    final DateTime now = DateTime.now();
    return _reservations.where((reservation) {
      final DateTime? createdAt = _extractReservationDate(reservation);
      if (createdAt == null) return false;
      if (period == 'Daily') return _isSameDay(createdAt, now);
      if (period == 'This Week') return _isThisWeek(createdAt, now);
      return _isThisMonth(createdAt, now);
    }).toList();
  }

  String _reservationStatus(Map<String, dynamic> reservation) {
    return (reservation['status'] ?? 'pending').toString().toLowerCase();
  }

  String _formatReservationStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      default:
        return 'Pending';
    }
  }

  String _composeReservationCustomerName(Map<String, dynamic> reservation) {
    final String firstName =
        (reservation['first_name'] ?? '').toString().trim();
    final String lastName = (reservation['last_name'] ?? '').toString().trim();
    final String combined = '$firstName $lastName'.trim();
    if (combined.isNotEmpty) return combined;
    final String fallback =
        (reservation['customer_name'] ?? reservation['customerName'] ?? '')
            .toString()
            .trim();
    return fallback.isNotEmpty ? fallback : 'Customer';
  }

  String _formatReservationTimestamp(DateTime date) {
    final String mm = date.month.toString().padLeft(2, '0');
    final String dd = date.day.toString().padLeft(2, '0');
    final String yyyy = date.year.toString();
    final String hh = date.hour.toString().padLeft(2, '0');
    final String min = date.minute.toString().padLeft(2, '0');
    return '$mm/$dd/$yyyy $hh:$min';
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

    // Apply global period filter using membership startDate
    final DateTime now = DateTime.now();
    if (_kpiPeriodFilter == 'Daily') {
      result =
          result.where((c) {
            final DateTime start = c['startDate'] as DateTime;
            return _isSameDay(start, now);
          }).toList();
    } else if (_kpiPeriodFilter == 'This Week') {
      result =
          result.where((c) {
            final DateTime start = c['startDate'] as DateTime;
            return _isThisWeek(start, now);
          }).toList();
    } else if (_kpiPeriodFilter == 'This Month') {
      result =
          result.where((c) {
            final DateTime start = c['startDate'] as DateTime;
            return _isThisMonth(start, now);
          }).toList();
    }
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
    final bool isMobile = _isMobile(context);
    return Container(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isMobile ? 'Type' : 'Membership Type',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 12 : 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: isMobile ? 2 : 4),
            PopupMenuButton<String>(
              tooltip: 'Filter membership type',
              icon: Icon(Icons.arrow_drop_down, size: isMobile ? 16 : 18),
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
    final bool isMobile = _isMobile(context);
    return Container(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isMobile ? 'Exp Date' : 'Expiration Date',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 12 : 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: isMobile ? 2 : 4),
            PopupMenuButton<String>(
              tooltip: 'Filter expiration',
              icon: Icon(Icons.arrow_drop_down, size: isMobile ? 16 : 18),
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
  Widget _buildPhoneNumberButton(String phoneNumber, bool isMobile) {
    if (phoneNumber == 'N/A' ||
        phoneNumber.isEmpty ||
        phoneNumber == 'Not provided') {
      return Center(
        child: Text(
          'N/A',
          style: TextStyle(
            fontSize: isMobile ? 12 : 16,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: isMobile ? 6 : 8,
        ),
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
              size: isMobile ? 14 : 16,
              color: const Color(0xFF2E7D32), // Darker green icon
            ),
            SizedBox(width: isMobile ? 4 : 6),
            Flexible(
              child: Text(
                phoneNumber,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 14,
                  color: const Color(0xFF2E7D32), // Darker green text
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(bool isMobile) {
    return SizedBox(
      height: isMobile ? 36 : 40,
      child: ElevatedButton.icon(
        onPressed: () => _promptExportPeriod(context),
        icon: Icon(
          Icons.picture_as_pdf,
          color: Colors.red.shade700,
          size: isMobile ? 18 : 18,
        ),
        label: Text(isMobile ? 'PDF' : 'Export PDF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18),
          minimumSize: Size(isMobile ? 72 : 150, isMobile ? 36 : 40),
          maximumSize: Size(
            isMobile ? double.infinity : 200,
            isMobile ? 36 : 40,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodToggleButtons(bool isMobile) {
    return ToggleButtons(
      isSelected: _periodSelected,
      onPressed: (index) {
        if (index == 0) _setGlobalPeriod('Daily');
        if (index == 1) _setGlobalPeriod('This Week');
        if (index == 2) _setGlobalPeriod('This Month');
      },
      borderRadius: BorderRadius.circular(18),
      constraints: BoxConstraints(
        minHeight: isMobile ? 40 : 36,
        minWidth: isMobile ? 80 : 110,
      ),
      selectedColor: Colors.white,
      color: Colors.black87,
      fillColor: Colors.black87,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 8),
          child: Text('Daily', style: TextStyle(fontSize: isMobile ? 12 : 14)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 8),
          child: Text(
            'This Week',
            style: TextStyle(fontSize: isMobile ? 12 : 14),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 8),
          child: Text(
            'This Month',
            style: TextStyle(fontSize: isMobile ? 12 : 14),
          ),
        ),
      ],
    );
  }

  // Export report for a specific period without mutating on-screen filters
  Future<void> _exportOverallReportForPeriod(
    BuildContext context,
    String period,
  ) async {
    final List<Map<String, dynamic>> reservationsForExport =
        _filterReservationsByPeriod(period);
    final int pendingReservations =
        reservationsForExport
            .where((r) => _reservationStatus(r) == 'pending')
            .length;
    final int acceptedReservations =
        reservationsForExport
            .where((r) => _reservationStatus(r) == 'accepted')
            .length;
    final int declinedReservations =
        reservationsForExport
            .where((r) => _reservationStatus(r) == 'declined')
            .length;

    // Get Time In and Time Out values based on period
    int timeInValue = 0;
    int timeOutValue = 0;
    if (period == 'Daily') {
      timeInValue = timeInDay;
      timeOutValue = timeOutDay;
    } else if (period == 'This Week') {
      timeInValue = timeInWeek;
      timeOutValue = timeOutWeek;
    } else if (period == 'This Month') {
      timeInValue = timeInMonth;
      timeOutValue = timeOutMonth;
    }

    final rows = <List<dynamic>>[
      ['Section', 'Metric', 'Value'],
      ['Products', 'Active', productsActive],
      ['Products', 'Archived', productsArchived],
      ['Admins', 'Active', adminsActive],
      ['Admins', 'Archived', adminsArchived],
      ['Customers', 'Active', customersActive],
      ['Customers', 'Archived', customersArchived],
      ['Customers', 'Expired (of Active)', customersExpired],
      ['Customers', 'Total Active Customers', customersActive],
      ['Trainers', 'Active', trainersActive],
      ['Trainers', 'Archived', trainersArchived],
      ['Attendance', 'Time In ($period)', timeInValue],
      ['Attendance', 'Time Out ($period)', timeOutValue],
      ['Memberships', 'Daily', membershipTotals['Daily'] ?? 0],
      ['Memberships', 'Half Month', membershipTotals['Half Month'] ?? 0],
      ['Memberships', 'Monthly', membershipTotals['Monthly'] ?? 0],
      ['Reservations', 'Requests ($period)', reservationsForExport.length],
      ['Reservations', 'Pending', pendingReservations],
      ['Reservations', 'Accepted', acceptedReservations],
      ['Reservations', 'Declined', declinedReservations],
    ];

    // Prepare customers filtered by selected export period (without changing UI state)
    List<Map<String, dynamic>> customersForExport =
        _customers
            .where(
              (c) =>
                  (c['status'] ?? 'active').toString().toLowerCase() ==
                  'active',
            )
            .toList();

    DateTime now = DateTime.now();
    if (period == 'Daily') {
      customersForExport =
          customersForExport
              .where((c) => _isSameDay(c['startDate'] as DateTime, now))
              .toList();
    } else if (period == 'This Week') {
      customersForExport =
          customersForExport
              .where((c) => _isThisWeek(c['startDate'] as DateTime, now))
              .toList();
    } else if (period == 'This Month') {
      customersForExport =
          customersForExport
              .where((c) => _isThisMonth(c['startDate'] as DateTime, now))
              .toList();
    }

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
      ...customersForExport.map((c) {
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

    final reservationTableRows = <List<dynamic>>[
      [
        'Reservation ID',
        'Product',
        'Customer',
        'Quantity',
        'Requested At',
        'Status',
      ],
      ...reservationsForExport.map((reservation) {
        final String id = '#${reservation['id'] ?? 'N/A'}';
        final String product =
            (reservation['product_name'] ?? reservation['productName'] ?? 'N/A')
                .toString();
        final String customer = _composeReservationCustomerName(reservation);
        final String qty =
            (reservation['quantity'] ?? reservation['qty'] ?? 0).toString();
        final DateTime? requestedAt = _extractReservationDate(reservation);
        final String requestedAtLabel =
            requestedAt != null
                ? _formatReservationTimestamp(requestedAt)
                : 'N/A';
        final String statusLabel = _formatReservationStatusLabel(
          _reservationStatus(reservation),
        );
        return [id, product, customer, qty, requestedAtLabel, statusLabel];
      }),
    ];

    // Prepare Today memberships data for Daily
    Map<String, int>? todayMemberships;
    if (period == 'Daily') {
      final DateTime now = DateTime.now();
      int daily = 0, halfMonth = 0, monthly = 0, expired = 0;
      for (final c in customersForExport) {
        final DateTime start = c['startDate'] as DateTime;
        if (_isSameDay(start, now)) {
          final String type = (c['membershipType'] ?? '').toString();
          if (type == 'Daily')
            daily++;
          else if (type == 'Half Month')
            halfMonth++;
          else
            monthly++;
          if (c['isExpired'] == true) expired++;
        }
      }
      todayMemberships = {
        'Daily': daily,
        'Half Month': halfMonth,
        'Monthly': monthly,
        'Expired': expired,
      };
    }

    // Decide which charts to include based on selected period
    Map<String, int>? weeklyMemberships;
    Map<String, int>? monthlyMemberships;
    if (period == 'This Week') {
      try {
        weeklyMemberships = await ApiService.getNewMembersThisWeek();
      } catch (e) {
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
    } else if (period == 'This Month') {
      try {
        monthlyMemberships = await ApiService.getNewMembersThisMonth();
      } catch (e) {
        monthlyMemberships = {'1': 0, '2': 0, '3': 0, '4': 0};
      }
    }

    await exportStatsToPDF(
      context,
      title: 'Statistics Report ($period)',
      rows: rows,
      customerTableRows: customerTableRows,
      reservationTableRows:
          reservationTableRows.length > 1 ? reservationTableRows : null,
      todayMemberships: todayMemberships,
      weeklyMemberships: weeklyMemberships,
      monthlyMemberships: monthlyMemberships,
      membershipTotals: membershipTotals,
      expiredMemberships: customersExpired,
    );
  }

  Future<void> _promptExportPeriod(BuildContext context) async {
    final String initial = _kpiPeriodFilter; // remember current UI selection
    String selected = initial;

    final String? confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return AlertDialog(
              title: const Text('Select export period'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: RadioGroup<String>(
                groupValue: selected,
                onChanged: (value) {
                  if (value == null) return;
                  setLocalState(() => selected = value);
                },
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      RadioListTile<String>(
                        value: 'Daily',
                        title: Text('Daily'),
                        secondary: Icon(Icons.today_rounded),
                        dense: true,
                      ),
                      RadioListTile<String>(
                        value: 'This Week',
                        title: Text('This Week'),
                        secondary: Icon(Icons.calendar_view_week_rounded),
                        dense: true,
                      ),
                      RadioListTile<String>(
                        value: 'This Month',
                        title: Text('This Month'),
                        secondary: Icon(Icons.calendar_month_rounded),
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(selected),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == null) return; // cancelled
    await _exportOverallReportForPeriod(context, confirmed);
  }

  Widget _buildCustomerTable(bool isMobile) {
    // Build header row content
    Widget headerRow = Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 12 : 18,
        horizontal: isMobile ? 8 : 16,
      ),
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
      child:
          isMobile
              ? Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: const Text(
                      'Customer ID',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: const Text(
                      'Name',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: const Text(
                      'Contact',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  SizedBox(width: 110, child: _buildMembershipHeader()),
                  SizedBox(
                    width: 120,
                    child: const Text(
                      'Start Date',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  SizedBox(width: 120, child: _buildExpirationHeader()),
                ],
              )
              : Row(
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
    );

    // Build data rows
    List<Widget> dataRows =
        _getVisibleCustomers().map((customer) {
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
                child:
                    isMobile
                        ? Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 4,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    '#${customer['customerId'] ?? 'N/A'}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 4,
                                ),
                                child: Text(
                                  customer['name'] ?? '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 130,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 4,
                                ),
                                child: _buildPhoneNumberButton(
                                  customer['contactNumber'] ?? 'N/A',
                                  isMobile,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 4,
                                ),
                                child: Text(
                                  membershipType,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _getMembershipTypeColor(
                                      membershipType,
                                    ),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 4,
                                ),
                                child: Text(
                                  formattedStart,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        formattedExpiry,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color:
                                              isExpired
                                                  ? Colors.red
                                                  : Colors.black87,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isExpired) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.red.shade300,
                                          ),
                                        ),
                                        child: const Text(
                                          'Exp',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 10,
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
                        )
                        : Row(
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
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
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
                                  isMobile,
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
        }).toList();

    // Wrap everything in a single scroll view on mobile
    if (isMobile) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: SingleChildScrollView(
          controller: _tableScrollController,
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [headerRow, ...dataRows],
          ),
        ),
      );
    }

    // Desktop layout - no scroll view needed
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(children: [headerRow, ...dataRows]),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);

    // Unregister from refresh service
    RefreshService().unregisterRefreshCallback(_refreshData);

    _kpiController.dispose();
    _tableScrollController.dispose();
    super.dispose();
  }

  // Helper method to check if screen is mobile
  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = _isMobile(context);
    return Focus(
      onFocusChange: (hasFocus) {
        // Refresh data when this page gains focus (e.g., returning from customers.dart)
        if (hasFocus && mounted && !_isDisposed) {
          // Use a small delay to ensure widget is fully mounted
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && !_isDisposed) {
              _refreshData();
            }
          });
        }
      },
      child: Scaffold(
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
              // Desktop sidebar - hidden on mobile
              if (!isMobile)
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
                  padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isMobile)
                            IconButton(
                              tooltip: 'Open Menu',
                              onPressed:
                                  () => _scaffoldKey.currentState?.openDrawer(),
                              icon: const Icon(Icons.menu),
                            )
                          else
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
                          SizedBox(width: isMobile ? 4 : 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Statistics Report',
                                        style: TextStyle(
                                          fontSize: isMobile ? 20 : 28,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isMobile) _buildExportButton(isMobile),
                                  ],
                                ),
                                SizedBox(height: isMobile ? 12 : 12),
                                if (isMobile)
                                  SizedBox(
                                    width: double.infinity,
                                    child: Center(
                                      child: _buildPeriodToggleButtons(isMobile),
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      _buildExportButton(isMobile),
                                      const Spacer(),
                                      _buildPeriodToggleButtons(isMobile),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 8 : 8),
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
                                      periodFilter: _kpiPeriodFilter,
                                      groups: [
                                        _KpiGroup(
                                          title: 'Admins',
                                          tiles: [
                                            _KpiTile(
                                              label: 'Admins Added This Day',
                                              value: adminsAddedDay,
                                              color: const Color(0xFF2E7D32),
                                            ),
                                            _KpiTile(
                                              label: 'Admins Added This Week',
                                              value: adminsAddedWeek,
                                              color: const Color(0xFF1565C0),
                                            ),
                                            _KpiTile(
                                              label: 'Admins Added This Month',
                                              value: adminsAddedMonth,
                                              color: const Color(0xFF6A1B9A),
                                            ),
                                          ],
                                        ),
                                        _KpiGroup(
                                          title: 'Trainers',
                                          tiles: [
                                            _KpiTile(
                                              label: 'Trainers Added This Day',
                                              value: trainersAddedDay,
                                              color: const Color(0xFF2E7D32),
                                            ),
                                            _KpiTile(
                                              label: 'Trainers Added This Week',
                                              value: trainersAddedWeek,
                                              color: const Color(0xFF1565C0),
                                            ),
                                            _KpiTile(
                                              label:
                                                  'Trainers Added This Month',
                                              value: trainersAddedMonth,
                                              color: const Color(0xFF6A1B9A),
                                            ),
                                          ],
                                        ),
                                        _KpiGroup(
                                          title: 'Customers',
                                          tiles: [
                                            _KpiTile(
                                              label: 'Customers Added This Day',
                                              value: customersAddedDay,
                                              color: const Color(0xFF2E7D32),
                                            ),
                                            _KpiTile(
                                              label:
                                                  'Customers Added This Week',
                                              value: customersAddedWeek,
                                              color: const Color(0xFF1565C0),
                                            ),
                                            _KpiTile(
                                              label:
                                                  'Customers Added This Month',
                                              value: customersAddedMonth,
                                              color: const Color(0xFF6A1B9A),
                                            ),
                                          ],
                                        ),
                                        _KpiGroup(
                                          title: 'Products',
                                          tiles: [
                                            _KpiTile(
                                              label: 'Products Added This Day',
                                              value: productsAddedDay,
                                              color: const Color(0xFF2E7D32),
                                            ),
                                            _KpiTile(
                                              label: 'Products Added This Week',
                                              value: productsAddedWeek,
                                              color: const Color(0xFF1565C0),
                                            ),
                                            _KpiTile(
                                              label:
                                                  'Products Added This Month',
                                              value: productsAddedMonth,
                                              color: const Color(0xFF6A1B9A),
                                            ),
                                          ],
                                        ),
                                        _KpiGroup(
                                          title: 'Time In',
                                          tiles: [
                                            _KpiTile(
                                              label: 'Time In This Day',
                                              value: timeInDay,
                                              color: const Color(0xFF2E7D32),
                                            ),
                                            _KpiTile(
                                              label: 'Time In This Week',
                                              value: timeInWeek,
                                              color: const Color(0xFF1565C0),
                                            ),
                                            _KpiTile(
                                              label: 'Time In This Month',
                                              value: timeInMonth,
                                              color: const Color(0xFF6A1B9A),
                                            ),
                                          ],
                                        ),
                                        _KpiGroup(
                                          title: 'Time Out',
                                          tiles: [
                                            _KpiTile(
                                              label: 'Time Out This Day',
                                              value: timeOutDay,
                                              color: const Color(0xFFD32F2F),
                                            ),
                                            _KpiTile(
                                              label: 'Time Out This Week',
                                              value: timeOutWeek,
                                              color: const Color(0xFFD32F2F),
                                            ),
                                            _KpiTile(
                                              label: 'Time Out This Month',
                                              value: timeOutMonth,
                                              color: const Color(0xFFD32F2F),
                                            ),
                                          ],
                                        ),
                                        _KpiGroup(
                                          title: 'Total Customers',
                                          tiles: [
                                            _KpiTile(
                                              label: 'Total Active Customers',
                                              value: customersActive,
                                              color: const Color(0xFF2E7D32),
                                            ),
                                            _KpiTile(
                                              label: 'Total Active Customers',
                                              value: customersActive,
                                              color: const Color(0xFF1565C0),
                                            ),
                                            _KpiTile(
                                              label: 'Total Active Customers',
                                              value: customersActive,
                                              color: const Color(0xFF6A1B9A),
                                            ),
                                          ],
                                        ),
                                        _KpiGroup(
                                          title: 'Reserved Products',
                                          tiles: [
                                            // Pending reservations
                                            _KpiTile(
                                              label:
                                                  'Pending Reservations Today',
                                              value: reservationsPendingDay,
                                              color: const Color(0xFFF57C00),
                                            ),
                                            _KpiTile(
                                              label:
                                                  'Pending Reservations This Week',
                                              value: reservationsPendingWeek,
                                              color: const Color(0xFFF57C00),
                                            ),
                                            _KpiTile(
                                              label:
                                                  'Pending Reservations This Month',
                                              value: reservationsPendingMonth,
                                              color: const Color(0xFFF57C00),
                                            ),
                                            // Accepted reservations
                                            _KpiTile(
                                              label:
                                                  'Accepted Reservations Today',
                                              value: reservationsAcceptedDay,
                                              color: const Color(0xFF2E7D32),
                                            ),
                                            _KpiTile(
                                              label:
                                                  'Accepted Reservations This Week',
                                              value: reservationsAcceptedWeek,
                                              color: const Color(0xFF2E7D32),
                                            ),
                                            _KpiTile(
                                              label:
                                                  'Accepted Reservations This Month',
                                              value: reservationsAcceptedMonth,
                                              color: const Color(0xFF2E7D32),
                                            ),
                                            // Declined reservations
                                            _KpiTile(
                                              label:
                                                  'Declined Reservations Today',
                                              value: reservationsDeclinedDay,
                                              color: const Color(0xFFD32F2F),
                                            ),
                                            _KpiTile(
                                              label:
                                                  'Declined Reservations This Week',
                                              value: reservationsDeclinedWeek,
                                              color: const Color(0xFFD32F2F),
                                            ),
                                            _KpiTile(
                                              label:
                                                  'Declined Reservations This Month',
                                              value: reservationsDeclinedMonth,
                                              color: const Color(0xFFD32F2F),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Customer table
                                    _buildCustomerTable(isMobile),
                                    const SizedBox(height: 16),
                                    // Charts area
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final bool isMobile =
                                            MediaQuery.of(context).size.width <
                                            768;
                                        // Full-width first chart to occupy space
                                        return Wrap(
                                          spacing: isMobile ? 12 : 24,
                                          runSpacing: isMobile ? 12 : 24,
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
                                                  padding: EdgeInsets.all(
                                                    isMobile ? 12.0 : 16.0,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Flexible(
                                                            child: Text(
                                                              _kpiPeriodFilter ==
                                                                      'Daily'
                                                                  ? 'New Memberships Today'
                                                                  : (_startsView ==
                                                                          'Week'
                                                                      ? 'New Memberships this Week'
                                                                      : 'New Memberships this Month'),
                                                              style: TextStyle(
                                                                fontSize:
                                                                    isMobile
                                                                        ? 16
                                                                        : 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          // Chart filter removed; controlled by global filter
                                                        ],
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            isMobile ? 6 : 8,
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            isMobile
                                                                ? 200
                                                                : 260,
                                                        child: () {
                                                          if (_kpiPeriodFilter ==
                                                              'Daily') {
                                                            // Compute today's counts by membership type from loaded customers
                                                            final DateTime now =
                                                                DateTime.now();
                                                            int d = 0,
                                                                h = 0,
                                                                m = 0,
                                                                e = 0;
                                                            for (final c
                                                                in _customers) {
                                                              final DateTime
                                                              start =
                                                                  c['startDate']
                                                                      as DateTime;
                                                              if (_isSameDay(
                                                                start,
                                                                now,
                                                              )) {
                                                                final String
                                                                type =
                                                                    (c['membershipType'] ??
                                                                            '')
                                                                        .toString();
                                                                if (type ==
                                                                    'Daily')
                                                                  d++;
                                                                else if (type ==
                                                                    'Half Month')
                                                                  h++;
                                                                else
                                                                  m++;
                                                                if (c['isExpired'] ==
                                                                    true)
                                                                  e++;
                                                              }
                                                            }
                                                            return NewMembersTodayBarGraph(
                                                              daily: d,
                                                              halfMonth: h,
                                                              monthly: m,
                                                              expired: e,
                                                            );
                                                          }
                                                          return _startsView ==
                                                                  'Week'
                                                              ? NewMembersBarGraph(
                                                                customers:
                                                                    _customers,
                                                              )
                                                              : NewMembersMonthBarGraph(
                                                                customers:
                                                                    _customers,
                                                              );
                                                        }(),
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

// Grouped KPI ribbon (2x2 grid layout for main groups)
class _KpiGroup {
  final String title;
  final List<_KpiTile> tiles; // expects Day, Week, Month in order
  const _KpiGroup({required this.title, required this.tiles});
}

class _KpiRibbonGroups extends StatelessWidget {
  final List<_KpiGroup> groups;
  final ScrollController? controller;
  final String periodFilter; // Daily | This Week | This Month
  // filter callback removed
  const _KpiRibbonGroups({
    required this.groups,
    this.controller,
    this.periodFilter = 'Daily',
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    Widget tile(_KpiTile t) {
      return Container(
        width: isMobile ? double.infinity : 220,
        constraints: isMobile ? BoxConstraints(minHeight: 80) : null,
        margin: EdgeInsets.only(
          right: isMobile ? 0 : 0,
          bottom: isMobile ? 10 : 12,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 14,
          vertical: isMobile ? 10 : 10,
        ),
        decoration: BoxDecoration(
          color: t.color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.color.withAlpha(64)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: isMobile ? 8 : 10,
                  height: isMobile ? 8 : 10,
                  decoration: BoxDecoration(
                    color: t.color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.value.toString(),
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: isMobile ? 2 : 3),
                      Text(
                        t.label,
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 11,
                          color: Colors.black54,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Separate main groups from Reserved Products
    final List<_KpiGroup> mainGroups =
        groups.where((g) => g.title != 'Reserved Products').toList();
    final _KpiGroup? reservedProductsGroup = groups.firstWhere(
      (g) => g.title == 'Reserved Products',
      orElse: () => _KpiGroup(title: 'Reserved Products', tiles: []),
    );

    // Helper to get selected tile for a group based on period
    Widget buildGroupTile(_KpiGroup g) {
      int index = 0; // Daily
      if (periodFilter == 'This Week')
        index = 1;
      else if (periodFilter == 'This Month')
        index = 2;
      final _KpiTile selected =
          (index >= 0 && index < g.tiles.length)
              ? g.tiles[index]
              : g.tiles.first;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: isMobile ? 20 : 20, // Fixed height for title + bottom padding
            child: Padding(
              padding: EdgeInsets.only(
                left: isMobile ? 0 : 4,
                bottom: isMobile ? 6 : 6,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  g.title,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          tile(selected),
        ],
      );
    }

    // Build Reserved Products section with all 3 status tiles
    Widget? buildReservedProductsSection() {
      if (reservedProductsGroup == null || reservedProductsGroup.tiles.isEmpty)
        return null;

      int periodIndex = 0; // Daily
      if (periodFilter == 'This Week')
        periodIndex = 1;
      else if (periodFilter == 'This Month')
        periodIndex = 2;

      // Tiles are arranged as: Pending(0,1,2), Accepted(3,4,5), Declined(6,7,8)
      final int pendingIndex = periodIndex;
      final int acceptedIndex = periodIndex + 3;
      final int declinedIndex = periodIndex + 6;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: isMobile ? 20 : 20, // Fixed height for title + bottom padding
            child: Padding(
              padding: EdgeInsets.only(
                left: isMobile ? 0 : 4,
                bottom: isMobile ? 6 : 6,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  reservedProductsGroup.title,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
            children: [
              if (pendingIndex < reservedProductsGroup.tiles.length)
                tile(reservedProductsGroup.tiles[pendingIndex]),
              SizedBox(height: isMobile ? 10 : 12),
              if (acceptedIndex < reservedProductsGroup.tiles.length)
                tile(reservedProductsGroup.tiles[acceptedIndex]),
              SizedBox(height: isMobile ? 10 : 12),
              if (declinedIndex < reservedProductsGroup.tiles.length)
                tile(reservedProductsGroup.tiles[declinedIndex]),
            ],
          ),
        ],
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main groups in grid - organized from most to least tiles
                  if (mainGroups.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Column 1: Customers column (4 tiles - most)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              buildGroupTile(mainGroups[2]), // Customers
                              if (mainGroups.length >= 5) ...[
                                SizedBox(height: 12),
                                buildGroupTile(mainGroups[4]), // Time In
                              ],
                              if (mainGroups.length >= 6) ...[
                                SizedBox(height: 12),
                                buildGroupTile(mainGroups[5]), // Time Out
                              ],
                              if (mainGroups.length >= 7) ...[
                                SizedBox(height: 12),
                                buildGroupTile(mainGroups[6]), // Total Customers
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        // Column 2: Products and Reserved Products (1 + 3 tiles)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              buildGroupTile(mainGroups[3]), // Products
                              if (buildReservedProductsSection() != null) ...[
                                SizedBox(height: 12),
                                buildReservedProductsSection()!,
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        // Column 3: Trainers and Admins (2 tiles)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              buildGroupTile(mainGroups[1]), // Trainers
                              SizedBox(height: 12),
                              buildGroupTile(mainGroups[0]), // Admins
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Column 1: Customers column (4 tiles - most)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        buildGroupTile(mainGroups[2]), // Customers
                        if (mainGroups.length >= 5) ...[
                          SizedBox(height: 16),
                          buildGroupTile(mainGroups[4]), // Time In
                        ],
                        if (mainGroups.length >= 6) ...[
                          SizedBox(height: 16),
                          buildGroupTile(mainGroups[5]), // Time Out
                        ],
                        if (mainGroups.length >= 7) ...[
                          SizedBox(height: 16),
                          buildGroupTile(mainGroups[6]), // Total Customers
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  // Column 2: Products and Reserved Products (1 + 3 tiles)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        buildGroupTile(mainGroups[3]), // Products
                        if (buildReservedProductsSection() != null) ...[
                          SizedBox(height: 16),
                          buildReservedProductsSection()!,
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  // Column 3: Trainers and Admins (2 tiles)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        buildGroupTile(mainGroups[1]), // Trainers
                        SizedBox(height: 16),
                        buildGroupTile(mainGroups[0]), // Admins
                      ],
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
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    return SizedBox(
      width: width,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: isMobile ? 6 : 8),
              SizedBox(height: isMobile ? 200 : 260, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// Removed _MiniMetric (replaced by donut chart)
