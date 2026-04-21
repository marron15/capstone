import 'package:flutter/material.dart';

import '../services/api_service.dart';

Future<void> showRenewMembershipHistoryModal(
  BuildContext context,
  Map<String, dynamic> customer,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _RenewMembershipHistoryDialog(customer: customer),
  );
}

class _RenewMembershipHistoryDialog extends StatefulWidget {
  const _RenewMembershipHistoryDialog({required this.customer});

  final Map<String, dynamic> customer;

  @override
  State<_RenewMembershipHistoryDialog> createState() =>
      _RenewMembershipHistoryDialogState();
}

class _RenewMembershipHistoryDialogState
    extends State<_RenewMembershipHistoryDialog> {
  List<Map<String, dynamic>> _rows = [];
  bool _isLoading = true;
  String? _error;
  String _typeFilter = 'All';
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDayFilter;
  int _sortColumnIndex = 3;
  bool _sortAscending = false;

  int get _customerId {
    final dynamic raw = widget.customer['customerId'] ?? widget.customer['id'];
    return raw is int ? raw : int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  String get _memberName {
    return (widget.customer['name'] ?? widget.customer['fullName'] ?? 'Member')
        .toString()
        .trim();
  }

  @override
  void initState() {
    super.initState();
    _fetchMembershipHistory();
  }

  String _normalizeMembershipType(dynamic value) {
    final String raw = (value ?? '').toString().trim().toLowerCase();
    if (raw == 'daily') return 'Daily';
    if (raw.replaceAll(' ', '') == 'halfmonth') return 'Half Month';
    if (raw == 'monthly') return 'Monthly';
    return raw.isEmpty ? '-' : value.toString();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final String text = value.toString().trim();
    if (text.isEmpty) return null;

    DateTime? parsed = DateTime.tryParse(text);
    parsed ??= DateTime.tryParse(text.replaceFirst(' ', 'T'));
    return parsed;
  }

  DateTime? _parsePhilippineDateTime(dynamic value) {
    if (value == null) return null;
    final String text = value.toString().trim();
    if (text.isEmpty) return null;

    DateTime? parsed = DateTime.tryParse(text);
    parsed ??= DateTime.tryParse(text.replaceFirst(' ', 'T'));
    if (parsed == null) return null;

    final bool hasTimezone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(text);
    if (hasTimezone) {
      return parsed.toUtc().add(const Duration(hours: 8));
    }

    // MySQL DATETIME usually has no timezone; treat it as UTC then convert to PH.
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    ).add(const Duration(hours: 8));
  }

  String _formatDate(dynamic value) {
    final DateTime? dt = _parseDate(value);
    if (dt == null) return '-';
    final String mm = dt.month.toString().padLeft(2, '0');
    final String dd = dt.day.toString().padLeft(2, '0');
    final String yyyy = dt.year.toString();
    return '$mm/$dd/$yyyy';
  }

  String _formatDateTime(dynamic value) {
    final DateTime? dt = _parsePhilippineDateTime(value);
    if (dt == null) return '-';
    final String mm = dt.month.toString().padLeft(2, '0');
    final String dd = dt.day.toString().padLeft(2, '0');
    final String yyyy = dt.year.toString();
    final int hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final String min = dt.minute.toString().padLeft(2, '0');
    final String period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$mm/$dd/$yyyy  $hour12:$min $period';
  }

  Future<void> _fetchMembershipHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getCustomerMembershipHistory(
        customerId: _customerId,
      );
      if (!mounted) return;
      setState(() {
        _rows = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load membership history: $e';
        _isLoading = false;
      });
    }
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime baseDate = _selectedDayFilter ?? _selectedDate;
    final DateTime initialDate = baseDate.isAfter(today) ? today : baseDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: today,
      selectableDayPredicate: (day) {
        final DateTime candidate = DateTime(day.year, day.month, day.day);
        return !candidate.isAfter(today);
      },
      helpText: 'Select date',
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
      _selectedDayFilter = _selectedDate;
    });
  }

  void _setWholeMonthFilter() {
    setState(() {
      _selectedDayFilter = null;
    });
  }

  String _formatDateLabel(DateTime date) {
    final String mm = date.month.toString().padLeft(2, '0');
    final String dd = date.day.toString().padLeft(2, '0');
    return '$mm/$dd/${date.year}';
  }

  String _formatMonthLabel(DateTime date) {
    final String mm = date.month.toString().padLeft(2, '0');
    return '$mm/${date.year}';
  }

  List<Map<String, dynamic>> _visibleRows() {
    final List<Map<String, dynamic>> filtered =
        _rows.where((row) {
          final String membershipType = _normalizeMembershipType(
            row['membership_type'] ?? row['status'],
          );
          if (_typeFilter != 'All' && membershipType != _typeFilter) {
            return false;
          }

          final DateTime? anchor =
              _parsePhilippineDateTime(row['updated_at']) ??
              _parsePhilippineDateTime(row['created_at']) ??
              _parseDate(row['start_date']);
          if (anchor == null) return false;

          if (_selectedDayFilter != null) {
            return anchor.year == _selectedDayFilter!.year &&
                anchor.month == _selectedDayFilter!.month &&
                anchor.day == _selectedDayFilter!.day;
          }

          return anchor.year == _selectedDate.year &&
              anchor.month == _selectedDate.month;
        }).toList();

    int compareDate(dynamic a, dynamic b) {
      final DateTime aDate =
          _parseDate(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bDate =
          _parseDate(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    }

    filtered.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = compareDate(a['start_date'], b['start_date']);
          break;
        case 1:
          cmp = compareDate(a['expiration_date'], b['expiration_date']);
          break;
        case 2:
          cmp = _normalizeMembershipType(
            a['membership_type'] ?? a['status'],
          ).compareTo(
            _normalizeMembershipType(b['membership_type'] ?? b['status']),
          );
          break;
        case 3:
        default:
          cmp = compareDate(
            _parsePhilippineDateTime(a['updated_at'] ?? a['created_at']),
            _parsePhilippineDateTime(b['updated_at'] ?? b['created_at']),
          );
      }
      return _sortAscending ? cmp : -cmp;
    });

    return filtered;
  }

  bool _isMembershipExpired(Map<String, dynamic> row) {
    final dynamic expirationRaw = row['expiration_date'];
    final DateTime? expirationDate = _parseDate(expirationRaw);
    if (expirationDate == null) return false;

    final DateTime now = DateTime.now();
    final String membershipType = _normalizeMembershipType(
      row['membership_type'] ?? row['status'],
    );

    if (membershipType == 'Daily') {
      final String expirationText = (expirationRaw ?? '').toString().trim();
      final bool hasExplicitTime =
          expirationText.contains(':') || expirationText.contains('T');

      // Backward compatibility: if Daily expiration is date-only, treat it as 9:00 PM.
      final DateTime dailyCutoff =
          hasExplicitTime
              ? expirationDate
              : DateTime(
                expirationDate.year,
                expirationDate.month,
                expirationDate.day,
                21,
                0,
                0,
              );

      return !dailyCutoff.isAfter(now);
    }

    final DateTime todayOnly = DateTime(now.year, now.month, now.day);
    return expirationDate.isBefore(todayOnly);
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Daily':
        return Colors.orange;
      case 'Half Month':
        return Colors.blue;
      case 'Monthly':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMembershipFilterHeader(int totalCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Membership ($totalCount)'),
        PopupMenuButton<String>(
          tooltip: 'Filter membership type',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          onSelected: (value) {
            setState(() {
              _typeFilter = value;
            });
          },
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

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildHeader(), Flexible(child: _buildBody())],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.autorenew_rounded,
              color: Colors.black87,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Renew Membership History',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_memberName  •  ID #$_customerId',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(
              _selectedDayFilter != null
                  ? _formatDateLabel(_selectedDayFilter!)
                  : _formatMonthLabel(_selectedDate),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size(0, 40),
            ),
          ),
          if (_selectedDayFilter != null) ...[
            const SizedBox(width: 10),
            IconButton(
              onPressed: _setWholeMonthFilter,
              tooltip: 'Whole Month',
              icon: const Icon(Icons.filter_alt_off),
            ),
            const SizedBox(width: 6),
          ],
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.black87),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final List<Map<String, dynamic>> visibleRows = _visibleRows();

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _fetchMembershipHistory,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 56,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No membership history found for $_memberName.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _buildDataTable(visibleRows),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> rows) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  headingRowColor: WidgetStateProperty.all(
                    Colors.indigo.shade50,
                  ),
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
                  dataRowMinHeight: 42,
                  dataRowMaxHeight: 48,
                  columnSpacing: 30,
                  columns: [
                    DataColumn(
                      label: const Text('Start Date'),
                      onSort: (i, asc) => _sort(i, asc),
                    ),
                    DataColumn(
                      label: const Text('Expiration Date'),
                      onSort: (i, asc) => _sort(i, asc),
                    ),
                    DataColumn(
                      label: _buildMembershipFilterHeader(rows.length),
                      onSort: (i, asc) => _sort(i, asc),
                    ),
                    DataColumn(
                      label: const Text('Updated At'),
                      onSort: (i, asc) => _sort(i, asc),
                    ),
                  ],
                  rows:
                      rows.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final Map<String, dynamic> row = entry.value;
                        final bool isExpired = _isMembershipExpired(row);

                        final String type = _normalizeMembershipType(
                          row['membership_type'] ?? row['status'],
                        );

                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((
                            states,
                          ) {
                            if (isExpired) return Colors.red.shade50;
                            if (index.isOdd) return Colors.grey.shade50;
                            return null;
                          }),
                          cells: [
                            DataCell(
                              Text(
                                _formatDate(row['start_date']),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            DataCell(
                              Text(
                                _formatDate(row['expiration_date']),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _typeColor(
                                    type,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _typeColor(
                                      type,
                                    ).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _typeColor(type),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                _formatDateTime(
                                  row['updated_at'] ?? row['created_at'],
                                ),
                                style: const TextStyle(fontSize: 13),
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
    );
  }
}
