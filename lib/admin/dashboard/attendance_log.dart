import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../pdf/export_attendance_log.dart';
import '../../services/attendance_service.dart';
import '../../services/unified_auth_state.dart';
import '../sidenav.dart';

class AttendanceLogPage extends StatefulWidget {
  const AttendanceLogPage({super.key});

  @override
  State<AttendanceLogPage> createState() => _AttendanceLogPageState();
}

class _AttendanceDisplayRow {
  const _AttendanceDisplayRow({
    required this.customerId,
    required this.customerName,
    required this.status,
    this.attendanceId,
    this.date,
    this.timeIn,
    this.timeOut,
    this.sessionDuration,
    this.verifyingAdminName,
  });

  final int? attendanceId;
  final int customerId;
  final String customerName;
  final String status;
  final DateTime? date;
  final DateTime? timeIn;
  final DateTime? timeOut;
  final Duration? sessionDuration;
  final String? verifyingAdminName;

  Duration? get duration =>
      sessionDuration ??
      ((timeIn != null && timeOut != null)
          ? timeOut!.difference(timeIn!)
          : null);

  String get statusLabel {
    if (status.isEmpty) return 'Unknown';
    return status.toUpperCase() == 'IN' ? 'Timed In' : 'Timed Out';
  }
}

class _AttendanceLogPageState extends State<AttendanceLogPage> {
  List<AttendanceRecord> _attendanceRecords = [];
  List<_AttendanceDisplayRow> _filteredRecords = [];
  bool _isLoading = true;
  bool _isExporting = false;
  String? _errorMessage;
  String _statusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  DateTime? _selectedDayFilter;
  static const double _drawerWidth = 280;
  bool _navCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<AttendanceSnapshot>? _attendanceSubscription;
  Timer? _dateRefreshTimer;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadAttendanceRecords();
    _attendanceSubscription = AttendanceService.updates.listen((_) {
      if (!mounted) return;
      _loadAttendanceRecords();
    });
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _attendanceSubscription?.cancel();
    _dateRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await AttendanceService.fetchRecords(
        // Fetch records broadly; month range is applied locally.
        date: null,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (!mounted) return;
      setState(() {
        _attendanceRecords = records;
        _isLoading = false;
      });
      _filterRecords();
    } on AttendanceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('_loadAttendanceRecords error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading attendance records.';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportAttendanceReportPdf() async {
    if (_filteredRecords.isEmpty || _isExporting) return;

    setState(() => _isExporting = true);
    try {
      final List<List<String>> rows =
          _filteredRecords
              .map(
                (record) => [
                  record.customerName,
                  record.customerId.toString(),
                  _formatDate(record.date),
                  _formatTime(record.timeIn),
                  _formatTime(record.timeOut),
                  _formatDuration(record.duration),
                  record.verifyingAdminName?.trim().isNotEmpty == true
                      ? record.verifyingAdminName!.trim()
                      : '-',
                  record.statusLabel,
                ],
              )
              .toList();

      await exportAttendanceLogPdf(context: context, rows: rows);
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _filterRecords() {
    final List<_AttendanceDisplayRow> displayRows = _expandRecordsForDisplay(
      _attendanceRecords,
    );
    final String q = _searchQuery.trim().toLowerCase();
    List<_AttendanceDisplayRow> filtered =
        displayRows.where((record) {
          final String customerName = record.customerName.toLowerCase();
          final String customerId = record.customerId.toString();
          final String adminName =
              (record.verifyingAdminName ?? '').toLowerCase();
          final String status = record.statusLabel.toLowerCase();

          if (q.isEmpty) return true;
          return customerName.contains(q) ||
              customerId.contains(q) ||
              adminName.contains(q) ||
              status.contains(q);
        }).toList();

    if (_statusFilter != 'All') {
      filtered =
          filtered
              .where((record) => record.status.toUpperCase() == _statusFilter)
              .toList();
    }

    // Default filter is whole month, with optional exact-day override.
    if (_selectedDate != null) {
      filtered =
          filtered.where((record) {
            final DateTime? recordDate = record.date;
            if (recordDate == null) return false;
            if (_selectedDayFilter != null) {
              return recordDate.year == _selectedDayFilter!.year &&
                  recordDate.month == _selectedDayFilter!.month &&
                  recordDate.day == _selectedDayFilter!.day;
            }
            return recordDate.year == _selectedDate!.year &&
                recordDate.month == _selectedDate!.month;
          }).toList();
    }

    setState(() {
      _filteredRecords = filtered;
    });
  }

  Widget _buildStatusFilterHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _statusFilter == 'All'
              ? 'Status'
              : _statusFilter == 'IN'
              ? 'Time In'
              : 'Time Out',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
          textAlign: TextAlign.center,
        ),
        PopupMenuButton<String>(
          tooltip: 'Filter status',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          onSelected: (value) {
            _statusFilter = value;
            _filterRecords();
          },
          itemBuilder:
              (context) => const [
                PopupMenuItem(value: 'All', child: Text('All')),
                PopupMenuItem(value: 'IN', child: Text('Time In')),
                PopupMenuItem(value: 'OUT', child: Text('Time Out')),
              ],
        ),
      ],
    );
  }

  List<_AttendanceDisplayRow> _expandRecordsForDisplay(
    List<AttendanceRecord> records,
  ) {
    final List<_AttendanceDisplayRow> rows = [];

    for (final AttendanceRecord record in records) {
      final bool hasTimeIn = record.timeIn != null;
      final bool hasTimeOut = record.timeOut != null;

      if (hasTimeIn) {
        rows.add(
          _AttendanceDisplayRow(
            attendanceId: record.attendanceId,
            customerId: record.customerId,
            customerName: record.customerName,
            status: 'IN',
            date: record.timeIn ?? record.date,
            timeIn: record.timeIn,
            timeOut: record.timeOut,
            sessionDuration: record.duration,
            verifyingAdminName: record.verifyingAdminName,
          ),
        );
      }

      if (hasTimeOut) {
        rows.add(
          _AttendanceDisplayRow(
            attendanceId: record.attendanceId,
            customerId: record.customerId,
            customerName: record.customerName,
            status: 'OUT',
            date: record.timeOut ?? record.date,
            timeIn: record.timeIn,
            timeOut: record.timeOut,
            sessionDuration: record.duration,
            verifyingAdminName: record.verifyingAdminName,
          ),
        );
      }

      if (!hasTimeIn && !hasTimeOut) {
        rows.add(
          _AttendanceDisplayRow(
            attendanceId: record.attendanceId,
            customerId: record.customerId,
            customerName: record.customerName,
            status: record.status,
            date: record.date,
            timeIn: record.timeIn,
            timeOut: record.timeOut,
            sessionDuration: record.duration,
            verifyingAdminName: record.verifyingAdminName,
          ),
        );
      }
    }

    return rows;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedDayFilter = picked;
      });
      _loadAttendanceRecords();
      _scheduleMidnightRefresh();
    }
  }

  void _setWholeMonthFilter() {
    if (_selectedDate == null) return;
    setState(() {
      _selectedDayFilter = null;
    });
    _filterRecords();
  }

  void _scheduleMidnightRefresh() {
    _dateRefreshTimer?.cancel();
    final DateTime now = DateTime.now();
    final DateTime nextMidnight = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final Duration delay = nextMidnight.difference(now);
    _dateRefreshTimer = Timer(delay, () {
      if (!mounted) return;
      // Clear search query when date changes automatically
      _searchController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _selectedDayFilter = null;
        _searchQuery = '';
      });
      _loadAttendanceRecords();
      _scheduleMidnightRefresh();
    });
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final int rawHour = dateTime.hour;
    final int hour12 = rawHour % 12 == 0 ? 12 : rawHour % 12;
    final String period = rawHour >= 12 ? 'PM' : 'AM';
    final String hour = hour12.toString();
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$month/$day/$year';
  }

  String _formatMonthYear(DateTime? date) {
    if (date == null) return 'Month';
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$month/$year';
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  Widget _buildExportPdfButton({bool compact = false}) {
    if (_isExporting) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return ElevatedButton.icon(
      onPressed:
          _isLoading || _filteredRecords.isEmpty
              ? null
              : _exportAttendanceReportPdf,
      icon: Icon(Icons.picture_as_pdf, size: compact ? 16 : 18),
      label: Text('Export PDF', style: TextStyle(fontSize: compact ? 12 : 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.red.shade200,
        disabledForegroundColor: Colors.white70,
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 8 : 10,
        ),
      ),
    );
  }

  Widget _buildStatusChip(_AttendanceDisplayRow record) {
    final bool isClockIn = record.statusLabel.toLowerCase().contains('in');
    final Color badgeColor =
        isClockIn ? Colors.green.shade600 : Colors.red.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        record.statusLabel,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _handleMyQrTap() async {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final adminData = unifiedAuthState.adminData;
    if (adminData == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Admin data unavailable.')),
      );
      return;
    }

    String payload;
    try {
      payload = AttendanceService.buildAdminQrPayload(adminData);
    } on AttendanceException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    final String adminName = [adminData['first_name'], adminData['last_name']]
        .whereType<String>()
        .where((segment) => segment.trim().isNotEmpty)
        .join(' ');

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AdminQrModal(adminName: adminName, payload: payload),
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
            // Desktop sidebar - hidden on mobile
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
                child: Column(
                  children: [
                    const SizedBox.shrink(),
                    Expanded(child: _buildBody(isMobile)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isMobile) {
    // Build header and search bar that should always be visible
    Widget buildHeader() {
      if (isMobile) {
        return Column(
          children: [
            // Header row with menu button, title, and actions
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.transparent,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Open Menu',
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    icon: const Icon(Icons.menu),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Attendance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  // Date picker button
                  OutlinedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _selectedDayFilter != null
                          ? _formatDate(_selectedDayFilter)
                          : _formatMonthYear(_selectedDate),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  if (_selectedDayFilter != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.filter_alt_off, size: 20),
                      tooltip: 'Use whole month',
                      onPressed: _setWholeMonthFilter,
                    ),
                  ],
                  if (unifiedAuthState.isAdminLoggedIn) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.qr_code_2, size: 20),
                      onPressed: _handleMyQrTap,
                      tooltip: 'My QR',
                    ),
                  ],
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh',
                    onPressed: _loadAttendanceRecords,
                  ),
                ],
              ),
            ),
            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _filterRecords();
                        },
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 18,
                            color: Colors.black54,
                          ),
                          suffixIcon:
                              _searchQuery.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                      _filterRecords();
                                    },
                                  )
                                  : null,
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
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildExportPdfButton(compact: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      } else {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: _navCollapsed ? 'Open Sidebar' : 'Close Sidebar',
                    onPressed:
                        () => setState(() => _navCollapsed = !_navCollapsed),
                    icon: Icon(_navCollapsed ? Icons.menu : Icons.chevron_left),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Time In/Out Log',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // Date picker
                  OutlinedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _selectedDayFilter != null
                          ? _formatDate(_selectedDayFilter)
                          : _selectedDate != null
                          ? _formatMonthYear(_selectedDate)
                          : 'Select Month',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  if (_selectedDayFilter != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _setWholeMonthFilter,
                      icon: const Icon(Icons.filter_alt_off, size: 18),
                      label: const Text('Whole Month'),
                    ),
                  ],
                  const SizedBox(width: 8),
                  if (unifiedAuthState.isAdminLoggedIn)
                    OutlinedButton.icon(
                      onPressed: _handleMyQrTap,
                      icon: const Icon(Icons.qr_code_2, size: 18),
                      label: const Text('My QR'),
                    ),
                  if (unifiedAuthState.isAdminLoggedIn)
                    const SizedBox(width: 8),
                  // Refresh button
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: _loadAttendanceRecords,
                  ),
                ],
              ),
            ),
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  SizedBox(
                    width: 560,
                    height: 42,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText:
                            'Search by customer name, ID, time in, or time out...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _searchQuery.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                    _filterRecords();
                                  },
                                )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _filterRecords();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildExportPdfButton(),
                ],
              ),
            ),
          ],
        );
      }
    }

    // Build content area based on state
    Widget buildContent() {
      if (_isLoading) {
        return const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading attendance records...'),
              ],
            ),
          ),
        );
      }

      if (_errorMessage != null) {
        return Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading attendance records',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadAttendanceRecords,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      if (_filteredRecords.isEmpty) {
        return Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No attendance records found',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedDate != null
                      ? _selectedDayFilter != null
                          ? 'for ${_formatDate(_selectedDayFilter)}'
                          : 'for ${_formatMonthYear(_selectedDate)}'
                      : '',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        );
      }

      // Show records list/table
      if (isMobile) {
        return Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children:
                _filteredRecords.map((record) {
                  final DateTime? timeIn = record.timeIn;
                  final DateTime? timeOut = record.timeOut;
                  final DateTime? date = record.date;
                  final Duration? duration = record.duration;

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
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.customerName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: ${record.customerId}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusChip(record),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  'Date',
                                  _formatDate(date),
                                  Icons.calendar_today,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInfoCard(
                                  'Time In',
                                  _formatTime(timeIn),
                                  Icons.login,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  'Time Out',
                                  _formatTime(timeOut),
                                  Icons.logout,
                                  Colors.red,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInfoCard(
                                  'Duration',
                                  _formatDuration(duration),
                                  Icons.access_time,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          if (record.verifyingAdminName != null &&
                              record.verifyingAdminName!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified_user,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Verified by: ${record.verifyingAdminName}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        );
      } else {
        return Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Customer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Date',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Time In',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Time Out',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Duration',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Verified By',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Center(child: _buildStatusFilterHeader()),
                        ),
                      ],
                    ),
                  ),
                  // Table rows
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredRecords.length,
                    separatorBuilder:
                        (context, index) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final _AttendanceDisplayRow record =
                          _filteredRecords[index];
                      final DateTime? timeIn = record.timeIn;
                      final DateTime? timeOut = record.timeOut;
                      final DateTime? date = record.date;
                      final Duration? duration = record.duration;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        color:
                            index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record.customerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'ID: ${record.customerId}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _formatDate(date),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _formatTime(timeIn),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _formatTime(timeOut),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _formatDuration(duration),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                record.verifyingAdminName ?? '—',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(child: _buildStatusChip(record)),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return Column(children: [buildHeader(), buildContent()]);
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
}

class _AdminQrModal extends StatelessWidget {
  const _AdminQrModal({required this.adminName, required this.payload});

  final String adminName;
  final String payload;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    final double qrSize = isMobile ? 260.0 : 360.0;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isMobile ? 420 : 620),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Spacer(),
                  const Expanded(
                    flex: 3,
                    child: Text(
                      'Admin QR Code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                ],
              ),
              if (adminName.trim().isNotEmpty) ...[
                Text(
                  adminName,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isMobile ? 10 : 14),
              ],
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: QrImageView(
                    data: payload,
                    version: QrVersions.auto,
                    size: qrSize,
                    gapless: true,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 20),
                child: Text(
                  'Display this QR code so members can record attendance.',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 15,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
