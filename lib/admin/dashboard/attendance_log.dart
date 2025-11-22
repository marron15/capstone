import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/attendance_service.dart';
import '../../services/unified_auth_state.dart';
import '../sidenav.dart';

class AttendanceLogPage extends StatefulWidget {
  const AttendanceLogPage({super.key});

  @override
  State<AttendanceLogPage> createState() => _AttendanceLogPageState();
}

class _AttendanceLogPageState extends State<AttendanceLogPage> {
  List<AttendanceRecord> _attendanceRecords = [];
  List<AttendanceRecord> _filteredRecords = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  static const double _drawerWidth = 280;
  bool _navCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<AttendanceSnapshot>? _attendanceSubscription;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadAttendanceRecords();
    _attendanceSubscription = AttendanceService.updates.listen((_) {
      if (!mounted) return;
      _loadAttendanceRecords();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _attendanceSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await AttendanceService.fetchRecords(
        date: _selectedDate,
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

  void _filterRecords() {
    final String q = _searchQuery.trim().toLowerCase();
    List<AttendanceRecord> filtered =
        _attendanceRecords.where((record) {
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

    // Filter by selected date if provided
    if (_selectedDate != null) {
      filtered = filtered.where((record) {
        final DateTime? recordDate = record.date;
        if (recordDate == null) return false;
        return recordDate.year == _selectedDate!.year &&
            recordDate.month == _selectedDate!.month &&
            recordDate.day == _selectedDate!.day;
      }).toList();
    }

    setState(() {
      _filteredRecords = filtered;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAttendanceRecords();
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$month/$day/$year';
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  Widget _buildStatusChip(AttendanceRecord record) {
    final bool isClockIn = record.statusLabel.toLowerCase().contains('in');
    final Color badgeColor =
        isClockIn ? Colors.green.shade600 : Colors.orange.shade600;
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

    final String adminName = [
      adminData['first_name'],
      adminData['last_name'],
    ]
        .whereType<String>()
        .where((segment) => segment.trim().isNotEmpty)
        .join(' ');

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AdminQrScreen(
          adminName: adminName,
          payload: payload,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Row(
        children: [
      if (!_navCollapsed)
        SizedBox(
          width: _drawerWidth,
          child: SideNav(
            width: _drawerWidth,
            onClose: () => setState(() => _navCollapsed = true),
          ),
        ),
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: Column(
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
                        if (_navCollapsed)
                          IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () => setState(() => _navCollapsed = false),
                          ),
                        const SizedBox(width: 8),
                        const Text(
                          'Attendance Log',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Date picker
                        OutlinedButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            _selectedDate != null
                                ? _formatDate(_selectedDate)
                                : 'Select Date',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
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
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by customer name, ID, time in, or time out...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
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
                  // Content
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: Colors.red.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage!,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadAttendanceRecords,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : _filteredRecords.isEmpty
                                ? Center(
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
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _selectedDate != null
                                              ? 'for ${_formatDate(_selectedDate)}'
                                              : '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
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
                                                  child: Text(
                                                    'Status',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey.shade800,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Table rows
                                          ListView.separated(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: _filteredRecords.length,
                                            separatorBuilder: (context, index) => Divider(
                                              height: 1,
                                              color: Colors.grey.shade200,
                                            ),
                                            itemBuilder: (context, index) {
                                              final AttendanceRecord record = _filteredRecords[index];
                                              final DateTime? timeIn = record.timeIn;
                                              final DateTime? timeOut = record.timeOut;
                                              final DateTime? date = record.date;
                                              final Duration? duration = record.duration;

                                              return Container(
                                                padding: const EdgeInsets.all(16),
                                                color: index % 2 == 0
                                                    ? Colors.white
                                                    : Colors.grey.shade50,
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
                                                        style: TextStyle(
                                                          color: Colors.grey.shade700,
                                                        ),
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
                                                    Expanded(
                                                      child: _buildStatusChip(record),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminQrScreen extends StatelessWidget {
  const _AdminQrScreen({
    required this.adminName,
    required this.payload,
  });

  final String adminName;
  final String payload;

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin QR Code'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (adminName.isNotEmpty)
                Text(
                  adminName,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: QrImageView(
                    data: payload,
                    version: QrVersions.auto,
                    size: 240,
                    gapless: true,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Display this QR code so members can record attendance.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SelectableText(
                payload,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: payload));
                  messenger.showSnackBar(
                    const SnackBar(content: Text('QR payload copied')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Payload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

