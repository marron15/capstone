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
  DateTime _selectedMonth = DateTime.now();
  int _sortColumnIndex = 4;
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

  String _formatDate(dynamic value) {
    final DateTime? dt = _parseDate(value);
    if (dt == null) return '-';
    final String mm = dt.month.toString().padLeft(2, '0');
    final String dd = dt.day.toString().padLeft(2, '0');
    final String yyyy = dt.year.toString();
    return '$mm/$dd/$yyyy';
  }

  String _formatDateTime(dynamic value) {
    final DateTime? dt = _parseDate(value);
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

  Future<void> _pickMonth() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      helpText: 'Select month',
    );
    if (picked == null) return;
    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month, 1);
    });
  }

  String _monthLabel(DateTime date) {
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
              _parseDate(row['updated_at']) ??
              _parseDate(row['created_at']) ??
              _parseDate(row['start_date']);
          if (anchor == null) return false;

          return anchor.year == _selectedMonth.year &&
              anchor.month == _selectedMonth.month;
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
          cmp = _normalizeMembershipType(
            a['membership_type'] ?? a['status'],
          ).compareTo(
            _normalizeMembershipType(b['membership_type'] ?? b['status']),
          );
          break;
        case 1:
          cmp = compareDate(a['start_date'], b['start_date']);
          break;
        case 2:
          cmp = compareDate(a['expiration_date'], b['expiration_date']);
          break;
        case 3:
          cmp = (a['status'] ?? '').toString().compareTo(
            (b['status'] ?? '').toString(),
          );
          break;
        case 4:
        default:
          cmp = compareDate(
            a['updated_at'] ?? a['created_at'],
            b['updated_at'] ?? b['created_at'],
          );
      }
      return _sortAscending ? cmp : -cmp;
    });

    return filtered;
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

  Widget _buildStatusChip(String statusText) {
    final String value = statusText.trim().isEmpty ? '-' : statusText.trim();
    final bool isExpired = value.toLowerCase().contains('expired');
    final bool isDaily = value.toLowerCase() == 'daily';
    final Color chipColor =
        isExpired ? Colors.red : (isDaily ? Colors.orange : Colors.green);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: chipColor.withValues(alpha: 0.9),
        ),
      ),
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
            onPressed: _pickMonth,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(_monthLabel(_selectedMonth)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size(0, 40),
            ),
          ),
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
                      label: _buildMembershipFilterHeader(rows.length),
                      onSort: (i, asc) => _sort(i, asc),
                    ),
                    DataColumn(
                      label: const Text('Start Date'),
                      onSort: (i, asc) => _sort(i, asc),
                    ),
                    DataColumn(
                      label: const Text('Expiration Date'),
                      onSort: (i, asc) => _sort(i, asc),
                    ),
                    DataColumn(
                      label: const Text('Status'),
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

                        final String type = _normalizeMembershipType(
                          row['membership_type'] ?? row['status'],
                        );
                        final String status =
                            (row['status'] ?? type).toString().trim();

                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((
                            states,
                          ) {
                            if (index.isOdd) return Colors.grey.shade50;
                            return null;
                          }),
                          cells: [
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
                            DataCell(_buildStatusChip(status)),
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
