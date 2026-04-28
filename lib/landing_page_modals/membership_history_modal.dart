import 'package:flutter/material.dart';

import '../member_pdf/renewal_membership.dart';
import '../services/membership_service.dart';
import '../services/unified_auth_state.dart';
import 'date_scope_pickers.dart';

Future<void> showMembershipHistoryModal(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _MembershipHistoryDialog(),
  );
}

class _MembershipHistoryDialog extends StatefulWidget {
  const _MembershipHistoryDialog();

  @override
  State<_MembershipHistoryDialog> createState() =>
      _MembershipHistoryDialogState();
}

class _MembershipHistoryDialogState extends State<_MembershipHistoryDialog> {
  List<Map<String, dynamic>> _rows = [];
  bool _isLoading = true;
  bool _isExportingPdf = false;
  String? _error;

  String _statusFilter = 'All';
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDayFilter;

  String get _memberName =>
      (unifiedAuthState.customerName ?? 'Member').trim().isEmpty
          ? 'Member'
          : unifiedAuthState.customerName!.trim();

  int get _customerId => unifiedAuthState.customerId ?? 0;

  String? get _accessToken => unifiedAuthState.customerAccessToken;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  DateTime? _parseDate(String text) {
    if (text.isEmpty) return null;
    DateTime? parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed;
    parsed = DateTime.tryParse(text.replaceFirst(' ', 'T'));
    if (parsed != null) return parsed;

    // Fallback for MM/DD/YYYY or similar
    final parts = text.split(RegExp(r'[/|-]'));
    if (parts.length >= 3) {
      // Could be MM/DD/YYYY or YYYY/MM/DD
      if (parts[0].length == 4) {
        return DateTime.tryParse(
          '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}',
        );
      } else if (parts[2].length == 4) {
        return DateTime.tryParse(
          '${parts[2]}-${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}',
        );
      }
    }
    return null;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    final String text = value.toString().trim();
    if (text.isEmpty) return '—';
    final DateTime? parsed = _parseDate(text);
    if (parsed == null) return text;
    return '${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}/${parsed.year}';
  }

  String _statusLabel(Map<String, dynamic> row) {
    final String raw =
        (row['Membership'] ?? row['status'] ?? row['membership_type'] ?? '')
            .toString()
            .trim();
    if (raw.isEmpty) return '—';
    final String n = raw.toLowerCase();
    if (n == 'daily') return 'Daily';
    if (n.replaceAll(' ', '') == 'halfmonth') return 'Half Month';
    if (n == 'monthly') return 'Monthly';
    return raw;
  }

  String _renewedByLabel(Map<String, dynamic> row) {
    final dynamic raw =
        row['renewed_by'] ?? row['renewed_by_name'] ?? row['updated_by'];
    final String text = (raw ?? '').toString().trim();
    return text.isEmpty ? 'System' : text;
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final String? token = _accessToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'Please log in again to view membership history.';
        _isLoading = false;
      });
      return;
    }
    try {
      final List<Map<String, dynamic>> rows =
          await MembershipService.getMembershipHistory(token);
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  List<Map<String, dynamic>> _visibleRows() {
    List<Map<String, dynamic>> filtered = _rows;
    if (_statusFilter != 'All') {
      filtered =
          filtered.where((r) => _statusLabel(r) == _statusFilter).toList();
    }

    // Date filtering
    filtered =
        filtered.where((row) {
          final String startStr = (row['start_date'] ?? '').toString().trim();
          if (startStr.isEmpty) return true; // Show by default if no date

          DateTime? d = _parseDate(startStr);
          if (d == null) return true; // Show if we can't parse it

          d = d.toLocal();

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
    final DateTime? picked = await showMonthPickerDialog(
      context,
      _selectedDate,
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _selectedDayFilter = null;
    });
  }

  Future<void> _exportPdf() async {
    final rowsToExport = _visibleRows();
    if (_isLoading || _isExportingPdf || rowsToExport.isEmpty) return;
    setState(() => _isExportingPdf = true);
    final String dateRangeStr =
        _selectedDayFilter != null
            ? _formatDateLabel(_selectedDayFilter!)
            : 'Month of ${_formatMonthLabel(_selectedDate)}';
    final String filterDesc =
        _statusFilter != 'All'
            ? '$dateRangeStr | Type: $_statusFilter'
            : dateRangeStr;
    try {
      await exportMembershipHistoryPdf(
        context: context,
        memberName: _memberName,
        customerId: _customerId,
        rows: rowsToExport,
        dateRangeStr: filterDesc,
      );
    } finally {
      if (!mounted) return;
      setState(() => _isExportingPdf = false);
    }
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111111), Color(0xFF1C1C1C)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compactHeader = constraints.maxWidth < 640;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA812).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFFFFA812),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Membership History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_memberName  •  ID #$_customerId',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                    ),
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compactHeader ? 10 : 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
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
                      side: const BorderSide(color: Colors.white24, width: 1),
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
                  if (_selectedDayFilter != null)
                    IconButton(
                      onPressed: _setWholeMonthFilter,
                      tooltip: 'Select month',
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
                  ElevatedButton.icon(
                    onPressed:
                        (_isLoading ||
                                _isExportingPdf ||
                                _visibleRows().isEmpty)
                            ? null
                            : _exportPdf,
                    icon:
                        _isExportingPdf
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 16,
                            ),
                    label: Text(_isExportingPdf ? 'Exporting…' : 'Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withValues(
                        alpha: 0.1,
                      ),
                      disabledForegroundColor: Colors.white.withValues(
                        alpha: 0.35,
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Table ────────────────────────────────────────────────────────────────

  Widget _buildTable() {
    return ClipRRect(
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
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF5F5F5),
                      ),
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF222222),
                      ),
                      dataRowMinHeight: 44,
                      dataRowMaxHeight: 52,
                      columnSpacing: 28,
                      columns: [
                        const DataColumn(label: Text('Membership ID')),
                        const DataColumn(label: Text('Start Date')),
                        const DataColumn(label: Text('End Date')),
                        DataColumn(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Membership'),
                              const SizedBox(width: 2),
                              PopupMenuButton<String>(
                                tooltip: 'Filter type',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                icon: const Icon(
                                  Icons.filter_list,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                                onSelected:
                                    (v) => setState(() => _statusFilter = v),
                                itemBuilder:
                                    (_) => const [
                                      PopupMenuItem(
                                        value: 'All',
                                        child: Text('All'),
                                      ),
                                      PopupMenuItem(
                                        value: 'Daily',
                                        child: Text('Daily'),
                                      ),
                                      PopupMenuItem(
                                        value: 'Half Month',
                                        child: Text('Half Month'),
                                      ),
                                      PopupMenuItem(
                                        value: 'Monthly',
                                        child: Text('Monthly'),
                                      ),
                                    ],
                              ),
                            ],
                          ),
                        ),
                        const DataColumn(label: Text('Renewed By')),
                      ],
                      rows:
                          _visibleRows().asMap().entries.map((entry) {
                            final Map<String, dynamic> row = entry.value;
                            return DataRow(
                              color: WidgetStateProperty.resolveWith<Color?>(
                                (states) =>
                                    entry.key.isOdd
                                        ? Colors.grey.shade50
                                        : null,
                              ),
                              cells: [
                                DataCell(
                                  Text(
                                    (row['membership_id'] ?? row['id'] ?? '—')
                                        .toString(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
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
                                    _formatDate(
                                      row['expiration_date'] ?? row['end_date'],
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                DataCell(_buildTypeChip(_statusLabel(row))),
                                DataCell(
                                  Text(
                                    _renewedByLabel(row),
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
    );
  }

  Widget _buildTypeChip(String label) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (label.toLowerCase()) {
      case 'daily':
        bgColor = Colors.orange.withValues(alpha: 0.12);
        borderColor = Colors.orange.withValues(alpha: 0.3);
        textColor = Colors.orange.shade800;
        break;
      case 'half month':
        bgColor = Colors.blue.withValues(alpha: 0.12);
        borderColor = Colors.blue.withValues(alpha: 0.3);
        textColor = Colors.blue.shade800;
        break;
      case 'monthly':
        bgColor = Colors.green.withValues(alpha: 0.12);
        borderColor = Colors.green.withValues(alpha: 0.3);
        textColor = Colors.green.shade800;
        break;
      default:
        bgColor = const Color(0xFFFFA812).withValues(alpha: 0.12);
        borderColor = const Color(0xFFFFA812).withValues(alpha: 0.3);
        textColor = const Color(0xFFB77900);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────

  Widget _buildBody() {
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
                onPressed: _fetchHistory,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final visibleRows = _visibleRows();

    // All records missing (no data at all)
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

    // Records exist but active filter yields nothing → still show table + hint
    if (visibleRows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 52,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No records match the current filter.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed:
                          () => setState(() {
                            _statusFilter = 'All';
                            _selectedDayFilter = null;
                          }),
                      icon: const Icon(Icons.filter_alt_off, size: 16),
                      label: const Text('Clear All Filters'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: _buildTable(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isWide = size.width >= 700;
    final bool isCompact = size.width < 560;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWide ? size.width * 0.05 : (isCompact ? 8 : 16),
        vertical: isWide ? size.height * 0.06 : (isCompact ? 10 : 20),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1100,
          maxHeight: size.height * (isCompact ? 0.95 : 0.9),
        ),
        child: Column(
          children: [_buildHeader(), Expanded(child: _buildBody())],
        ),
      ),
    );
  }
}
