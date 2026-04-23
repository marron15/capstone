import 'package:flutter/material.dart';

import '../member_pdf/time_in_out_history_report.dart';
import '../services/attendance_service.dart';
import 'date_scope_pickers.dart';

class _HistoryEventRow {
  const _HistoryEventRow({
    required this.status,
    this.timeIn,
    this.timeOut,
    this.verifyingAdminName,
    this.platform,
  });

  final DateTime? timeIn;
  final DateTime? timeOut;
  final String status;
  final String? verifyingAdminName;
  final String? platform;
}

class TimeInOutHistoryModal extends StatefulWidget {
  const TimeInOutHistoryModal({
    super.key,
    required this.customerId,
    required this.memberName,
  });

  final int customerId;
  final String memberName;

  @override
  State<TimeInOutHistoryModal> createState() => _TimeInOutHistoryModalState();
}

class _TimeInOutHistoryModalState extends State<TimeInOutHistoryModal> {
  bool _isLoading = true;
  String? _error;
  List<AttendanceRecord> _records = [];
  List<_HistoryEventRow> _eventRows = [];
  final TimeInOutHistoryExportController _exportController =
      TimeInOutHistoryExportController();
  String _statusFilter = 'All';
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDayFilter;

  int _sortColumnIndex = 0;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _exportController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final records = await AttendanceService.fetchCustomerRecords(
        widget.customerId,
      );
      if (!mounted) return;
      setState(() {
        _records = records;
        _eventRows = _expandRecords(records);
        _applySort();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Unable to load attendance history right now. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _applySort();
    });
  }

  void _applySort() {
    int cmpDate(DateTime? a, DateTime? b) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return a.compareTo(b);
    }

    _eventRows.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = cmpDate(a.timeIn, b.timeIn);
          break;
        case 1:
          cmp = cmpDate(a.timeOut, b.timeOut);
          break;
        case 2:
          cmp = a.status.toLowerCase().compareTo(b.status.toLowerCase());
          break;
        case 3:
        default:
          cmp = (a.verifyingAdminName ?? '').toLowerCase().compareTo(
            (b.verifyingAdminName ?? '').toLowerCase(),
          );
      }
      return _sortAscending ? cmp : -cmp;
    });
  }

  List<_HistoryEventRow> _expandRecords(List<AttendanceRecord> records) {
    final List<_HistoryEventRow> rows = [];
    for (final record in records) {
      final bool hasIn = record.timeIn != null;
      final bool hasOut = record.timeOut != null;
      final String status = record.status.trim().toUpperCase();
      if (hasIn) {
        rows.add(
          _HistoryEventRow(
            timeIn: record.timeIn,
            timeOut: record.timeOut,
            status: 'IN',
            verifyingAdminName: record.verifyingAdminName,
            platform: record.platform,
          ),
        );
      }
      if (hasOut) {
        rows.add(
          _HistoryEventRow(
            timeIn: record.timeIn,
            timeOut: record.timeOut,
            status: 'OUT',
            verifyingAdminName: record.verifyingAdminName,
            platform: record.platform,
          ),
        );
      }
      if (!hasIn && !hasOut) {
        rows.add(
          _HistoryEventRow(
            timeIn: record.timeIn,
            timeOut: record.timeOut,
            status: status == 'OUT' ? 'OUT' : 'IN',
            verifyingAdminName: record.verifyingAdminName,
            platform: record.platform,
          ),
        );
      }
    }
    return rows;
  }

  List<_HistoryEventRow> _visibleEventRows() {
    List<_HistoryEventRow> filtered = _eventRows;
    if (_statusFilter != 'All') {
      filtered =
          filtered
              .where((r) => r.status.toUpperCase() == _statusFilter)
              .toList();
    }
    filtered =
        filtered.where((row) {
          final DateTime? d = (row.timeIn ?? row.timeOut)?.toLocal();
          if (d == null) return false;
          if (_selectedDayFilter != null) {
            return d.year == _selectedDayFilter!.year &&
                d.month == _selectedDayFilter!.month &&
                d.day == _selectedDayFilter!.day;
          }
          return d.year == _selectedDate.year && d.month == _selectedDate.month;
        }).toList();
    return filtered;
  }

  String _formatDateLabel(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  String _formatMonthLabel(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDateFilter() async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDayFilter ?? _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _selectedDayFilter = picked;
    });
  }

  Future<void> _setWholeMonthFilter() async {
    final DateTime? picked =
        await showMonthPickerDialog(context, _selectedDate);
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _selectedDayFilter = null;
    });
  }

  /// Filtered AttendanceRecord list for PDF export.
  List<AttendanceRecord> _visibleRecords() {
    return _records.where((record) {
      final DateTime? d = (record.timeIn ?? record.timeOut)?.toLocal();
      if (d == null) return false;
      if (_selectedDayFilter != null) {
        return d.year == _selectedDayFilter!.year &&
            d.month == _selectedDayFilter!.month &&
            d.day == _selectedDayFilter!.day;
      }
      return d.year == _selectedDate.year && d.month == _selectedDate.month;
    }).toList();
  }

  String _buildDateRangeStr() {
    final String base = _selectedDayFilter != null
        ? _formatDateLabel(_selectedDayFilter!)
        : 'Month of ${_formatMonthLabel(_selectedDate)}';
    return _statusFilter != 'All' ? '$base | Status: $_statusFilter' : base;
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    final DateTime l = dt.toLocal();
    final int h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final String period = l.hour >= 12 ? 'PM' : 'AM';
    final String min = l.minute.toString().padLeft(2, '0');
    return '${l.month.toString().padLeft(2, '0')}/${l.day.toString().padLeft(2, '0')}/${l.year}  $h:$min $period';
  }

  Widget _buildStatusChip(String status) {
    final bool isIn = status.toUpperCase() == 'IN';
    final Color color = isIn ? Colors.green : const Color(0xFFC62828);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        status.isEmpty ? 'UNKNOWN' : status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusFilterHeader(int total) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Status ($total)',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        PopupMenuButton<String>(
          tooltip: 'Filter status',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          onSelected: (v) => setState(() => _statusFilter = v),
          itemBuilder:
              (_) => const [
                PopupMenuItem(value: 'All', child: Text('All')),
                PopupMenuItem(value: 'IN', child: Text('In')),
                PopupMenuItem(value: 'OUT', child: Text('Out')),
              ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isWide = size.width >= 700;
    final List<_HistoryEventRow> visible = _visibleEventRows();
    final int totalIn =
        visible.where((r) => r.status.toUpperCase() == 'IN').length;
    final int totalOut =
        visible.where((r) => r.status.toUpperCase() == 'OUT').length;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWide ? size.width * 0.05 : 16,
        vertical: isWide ? size.height * 0.06 : 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1100,
          maxHeight: size.height * 0.9,
        ),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF111111), Color(0xFF1C1C1C)],
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Title + member name
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFFA812,
                          ).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.history,
                          color: Color(0xFFFFA812),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Attendance History',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.memberName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Controls row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stats chips
                      _HeaderChip(label: 'In: $totalIn', color: Colors.green),
                      const SizedBox(width: 8),
                      _HeaderChip(
                        label: 'Out: $totalOut',
                        color: const Color(0xFFC62828),
                      ),
                      const SizedBox(width: 16),
                      // Date filter
                      OutlinedButton.icon(
                        onPressed: _pickDateFilter,
                        icon: const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.white70,
                        ),
                        label: Text(
                          _selectedDayFilter != null
                              ? _formatDateLabel(_selectedDayFilter!)
                              : _formatMonthLabel(_selectedDate),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white24,
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 34),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      if (_selectedDayFilter != null) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: _setWholeMonthFilter,
                          tooltip: 'Show whole month',
                          icon: const Icon(
                            Icons.filter_alt_off,
                            size: 18,
                            color: Colors.white70,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                      const SizedBox(width: 14),
                      // Export
                      ValueListenableBuilder<bool>(
                        valueListenable: _exportController.isExporting,
                        builder:
                            (_, isExporting, __) =>
                                TimeInOutHistoryExportButton(
                                  isLoading: _isLoading,
                                  isExporting: isExporting,
                                  hasError: _error != null,
                                  hasRecords: _records.isNotEmpty,
                                  onExport: () => _exportController.export(
                                    context: context,
                                    memberName: widget.memberName,
                                    customerId: widget.customerId,
                                    records: _visibleRecords(),
                                    dateRangeStr: _buildDateRangeStr(),
                                  ),
                                ),
                      ),
                      const SizedBox(width: 8),
                      // Close
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close, color: Colors.white54),
                        tooltip: 'Close',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────
            Expanded(child: _buildBody(visible, totalIn, totalOut)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<_HistoryEventRow> visible, int totalIn, int totalOut) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loadHistory,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 56,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 14),
              const Text(
                'No time-in or time-out records yet.',
                style: TextStyle(color: Colors.black45, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }
    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            const Text(
              'No records match the current filter.',
              style: TextStyle(color: Colors.black45),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: LayoutBuilder(
            builder:
                (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: SingleChildScrollView(
                      child: DataTable(
                        sortColumnIndex:
                            _sortColumnIndex == 2 ? null : _sortColumnIndex,
                        sortAscending: _sortAscending,
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFF5F5F5),
                        ),
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF222222),
                        ),
                        dataRowMinHeight: 44,
                        dataRowMaxHeight: 50,
                        columnSpacing: 30,
                        columns: [
                          DataColumn(
                            label: Text('Time In ($totalIn)'),
                            onSort: _sort,
                          ),
                          DataColumn(
                            label: Text('Time Out ($totalOut)'),
                            onSort: _sort,
                          ),
                          DataColumn(
                            label: _buildStatusFilterHeader(visible.length),
                          ),
                          DataColumn(
                            label: const Text('Verified By'),
                            onSort: _sort,
                          ),
                        ],
                        rows:
                            visible.asMap().entries.map((entry) {
                              final int idx = entry.key;
                              final _HistoryEventRow r = entry.value;
                              return DataRow(
                                color: WidgetStateProperty.resolveWith<Color?>(
                                  (states) =>
                                      idx.isOdd ? Colors.grey.shade50 : null,
                                ),
                                cells: [
                                  DataCell(
                                    Text(
                                      _formatDateTime(r.timeIn),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      _formatDateTime(r.timeOut),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DataCell(_buildStatusChip(r.status)),
                                  DataCell(
                                    Text(
                                      (r.verifyingAdminName != null &&
                                              r.verifyingAdminName!
                                                  .trim()
                                                  .isNotEmpty)
                                          ? r.verifyingAdminName!
                                          : '—',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

// ── Small header chip ────────────────────────────────────────────────────────

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
