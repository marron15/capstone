import 'package:flutter/material.dart';

import '../member_pdf/time_in_out_history_report.dart';
import '../services/attendance_service.dart';

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
    int compareNullableDate(DateTime? a, DateTime? b) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return a.compareTo(b);
    }

    _eventRows.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = compareNullableDate(a.timeIn, b.timeIn);
          break;
        case 1:
          cmp = compareNullableDate(a.timeOut, b.timeOut);
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
      final bool hasTimeIn = record.timeIn != null;
      final bool hasTimeOut = record.timeOut != null;
      final String status = record.status.trim().toUpperCase();

      if (hasTimeIn) {
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

      if (hasTimeOut) {
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

      if (!hasTimeIn && !hasTimeOut) {
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
              .where((row) => row.status.toUpperCase() == _statusFilter)
              .toList();
    }

    filtered =
        filtered.where((row) {
          final DateTime? recordDate = (row.timeIn ?? row.timeOut)?.toLocal();
          if (recordDate == null) return false;

          if (_selectedDayFilter != null) {
            return recordDate.year == _selectedDayFilter!.year &&
                recordDate.month == _selectedDayFilter!.month &&
                recordDate.day == _selectedDayFilter!.day;
          }

          return recordDate.year == _selectedDate.year &&
              recordDate.month == _selectedDate.month;
        }).toList();

    return filtered;
  }

  String _formatDateLabel(DateTime date) {
    final String mm = date.month.toString().padLeft(2, '0');
    final String dd = date.day.toString().padLeft(2, '0');
    final String yyyy = date.year.toString();
    return '$mm/$dd/$yyyy';
  }

  String _formatMonthLabel(DateTime date) {
    final String mm = date.month.toString().padLeft(2, '0');
    final String yyyy = date.year.toString();
    return '$mm/$yyyy';
  }

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

  void _setWholeMonthFilter() {
    setState(() {
      _selectedDayFilter = null;
    });
  }

  Widget _buildStatusFilterHeader(int totalCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Status (Total: $totalCount)'),
        PopupMenuButton<String>(
          tooltip: 'Filter status',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          onSelected: (value) {
            setState(() {
              _statusFilter = value;
            });
          },
          itemBuilder:
              (context) => const [
                PopupMenuItem(value: 'All', child: Text('All')),
                PopupMenuItem(value: 'IN', child: Text('In')),
                PopupMenuItem(value: 'OUT', child: Text('Out')),
              ],
        ),
      ],
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final DateTime local = dateTime.toLocal();
    final String mm = local.month.toString().padLeft(2, '0');
    final String dd = local.day.toString().padLeft(2, '0');
    final String yyyy = local.year.toString();
    final int rawHour = local.hour;
    final int hour12 = rawHour % 12 == 0 ? 12 : rawHour % 12;
    final String period = rawHour >= 12 ? 'PM' : 'AM';
    final String min = local.minute.toString().padLeft(2, '0');
    return '$mm/$dd/$yyyy $hour12:$min $period';
  }

  Widget _buildStatusChip(String status) {
    final bool isIn = status.toUpperCase() == 'IN';
    final Color color = isIn ? Colors.green : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
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

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final List<_HistoryEventRow> visibleRows = _visibleEventRows();
    final int totalVisits = visibleRows.length;
    final int totalIn =
        visibleRows.where((row) => row.status.toUpperCase() == 'IN').length;
    final int totalOut =
        visibleRows.where((row) => row.status.toUpperCase() == 'OUT').length;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 980,
          maxHeight: size.height * 0.88,
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF101010),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA812).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: Color(0xFFFFA812),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Attendance History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.memberName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _pickDateFilter,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _selectedDayFilter != null
                          ? _formatDateLabel(_selectedDayFilter!)
                          : _formatMonthLabel(_selectedDate),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      minimumSize: const Size(0, 40),
                    ),
                  ),
                  if (_selectedDayFilter != null) ...[
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _setWholeMonthFilter,
                      tooltip: 'Whole Month',
                      icon: const Icon(Icons.filter_alt_off),
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                  ],
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _exportController.isExporting,
                      builder: (context, isExporting, _) {
                        return TimeInOutHistoryExportButton(
                          isLoading: _isLoading,
                          isExporting: isExporting,
                          hasError: _error != null,
                          hasRecords: _records.isNotEmpty,
                          onExport:
                              () => _exportController.export(
                                context: context,
                                memberName: widget.memberName,
                                customerId: widget.customerId,
                                records: _records,
                              ),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : (_error != null)
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _loadHistory,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                      : (_records.isEmpty)
                      ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No time-in or time-out records yet.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      )
                      : Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth,
                                    ),
                                    child: DataTable(
                                      sortColumnIndex:
                                          _sortColumnIndex == 2
                                              ? null
                                              : _sortColumnIndex,
                                      sortAscending: _sortAscending,
                                      headingRowColor: WidgetStateProperty.all(
                                        Colors.indigo.shade50,
                                      ),
                                      headingTextStyle: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: Colors.black.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                      dataRowMinHeight: 42,
                                      dataRowMaxHeight: 48,
                                      columnSpacing: 34,
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
                                          label: _buildStatusFilterHeader(
                                            totalVisits,
                                          ),
                                        ),
                                        DataColumn(
                                          label: const Text('Verified By'),
                                          onSort: _sort,
                                        ),
                                      ],
                                      rows:
                                          visibleRows.asMap().entries.map((
                                            entry,
                                          ) {
                                            final int idx = entry.key;
                                            final _HistoryEventRow record =
                                                entry.value;

                                            return DataRow(
                                              color:
                                                  WidgetStateProperty.resolveWith<
                                                    Color?
                                                  >((states) {
                                                    if (idx.isOdd) {
                                                      return Colors
                                                          .grey
                                                          .shade50;
                                                    }
                                                    return null;
                                                  }),
                                              cells: [
                                                DataCell(
                                                  Text(
                                                    _formatDateTime(
                                                      record.timeIn,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    _formatDateTime(
                                                      record.timeOut,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  _buildStatusChip(
                                                    record.status,
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    (record.verifyingAdminName !=
                                                                null &&
                                                            record
                                                                .verifyingAdminName!
                                                                .trim()
                                                                .isNotEmpty)
                                                        ? record
                                                            .verifyingAdminName!
                                                        : '-',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
