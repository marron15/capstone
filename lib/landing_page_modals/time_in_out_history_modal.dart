import 'package:flutter/material.dart';

import '../admin/modal/member_history_modal.dart';
import '../services/attendance_service.dart';

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
  bool _isExporting = false;

  int _sortColumnIndex = 0;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
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

    _records.sort((a, b) {
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

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final DateTime local = dateTime.toLocal();
    final String mm = local.month.toString().padLeft(2, '0');
    final String dd = local.day.toString().padLeft(2, '0');
    final String yyyy = local.year.toString();
    final String hh = local.hour.toString().padLeft(2, '0');
    final String min = local.minute.toString().padLeft(2, '0');
    final String ss = local.second.toString().padLeft(2, '0');
    return '$mm/$dd/$yyyy $hh:$min:$ss';
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

  Future<void> _exportPdf() async {
    if (_records.isEmpty || _isExporting) return;

    setState(() => _isExporting = true);
    try {
      final List<Map<String, dynamic>> logs =
          _records
              .map(
                (record) => {
                  'time_in': record.timeIn?.toIso8601String(),
                  'time_out': record.timeOut?.toIso8601String(),
                  'status': record.status,
                  'verified_by': record.verifyingAdminName,
                  'platform': record.platform,
                },
              )
              .toList();

      await exportMemberHistoryToPdf(
        context: context,
        memberName: widget.memberName,
        customerId: widget.customerId,
        logs: logs,
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final int totalVisits = _records.length;
    final int totalIn =
        _records.where((record) => record.status.toUpperCase() == 'IN').length;
    final int totalOut =
        _records.where((record) => record.status.toUpperCase() == 'OUT').length;

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
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child:
                        _isExporting
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Tooltip(
                              message:
                                  _isLoading
                                      ? 'Loading logs...'
                                      : 'Export to PDF',
                              child: OutlinedButton.icon(
                                onPressed:
                                    (_isLoading ||
                                            _error != null ||
                                            _records.isEmpty)
                                        ? null
                                        : _exportPdf,
                                icon: const Icon(
                                  Icons.picture_as_pdf,
                                  size: 16,
                                ),
                                label: const Text('Export PDF'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC62828),
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color(0xFFC62828),
                                  ),
                                  disabledBackgroundColor: const Color(
                                    0xFFBDBDBD,
                                  ),
                                  disabledForegroundColor: Colors.white60,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                              ),
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
                                      sortColumnIndex: _sortColumnIndex,
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
                                          label: Text(
                                            'Status (Total: $totalVisits)',
                                          ),
                                          onSort: _sort,
                                        ),
                                        DataColumn(
                                          label: const Text('Verified By'),
                                          onSort: _sort,
                                        ),
                                      ],
                                      rows:
                                          _records.asMap().entries.map((entry) {
                                            final int idx = entry.key;
                                            final AttendanceRecord record =
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
