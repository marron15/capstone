import 'package:flutter/material.dart';

import '../member_pdf/renewal_membership.dart';
import '../services/membership_service.dart';
import '../services/unified_auth_state.dart';

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

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final String text = value.toString().trim();
    if (text.isEmpty) return '-';
    DateTime? parsed = DateTime.tryParse(text);
    parsed ??= DateTime.tryParse(text.replaceFirst(' ', 'T'));
    if (parsed == null) return text;
    final String month = parsed.month.toString().padLeft(2, '0');
    final String day = parsed.day.toString().padLeft(2, '0');
    return '$month/$day/${parsed.year}';
  }

  String _statusLabel(Map<String, dynamic> row) {
    final String raw =
        (row['status'] ?? row['membership_type'] ?? '').toString().trim();
    if (raw.isEmpty) return '-';
    final String normalized = raw.toLowerCase();
    if (normalized == 'daily') return 'Daily';
    if (normalized.replaceAll(' ', '') == 'halfmonth') return 'Half Month';
    if (normalized == 'monthly') return 'Monthly';
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

    final String? accessToken = _accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      setState(() {
        _error = 'Please log in again to view membership history.';
        _isLoading = false;
      });
      return;
    }

    try {
      final List<Map<String, dynamic>> rows =
          await MembershipService.getMembershipHistory(accessToken);
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

  Future<void> _exportPdf() async {
    if (_isLoading || _isExportingPdf || _rows.isEmpty) return;
    setState(() {
      _isExportingPdf = true;
    });
    try {
      await exportMembershipHistoryPdf(
        context: context,
        memberName: _memberName,
        customerId: _customerId,
        rows: _rows,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isExportingPdf = false;
      });
    }
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
              color: const Color(0xFFFFA812).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Color(0xFF111111),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Membership History',
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
          ElevatedButton.icon(
            onPressed:
                (_isLoading || _isExportingPdf || _rows.isEmpty)
                    ? null
                    : _exportPdf,
            icon:
                _isExportingPdf
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(_isExportingPdf ? 'Exporting...' : 'Export to PDF'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFFFFA812),
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.black54,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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

  Widget _buildTable() {
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
                  headingRowColor: WidgetStateProperty.all(
                    Colors.grey.shade100,
                  ),
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
                  dataRowMinHeight: 42,
                  dataRowMaxHeight: 50,
                  columnSpacing: 28,
                  columns: const [
                    DataColumn(label: Text('Membership ID')),
                    DataColumn(label: Text('Start Date')),
                    DataColumn(label: Text('End Date')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Renewed By')),
                  ],
                  rows:
                      _rows.asMap().entries.map((entry) {
                        final Map<String, dynamic> row = entry.value;
                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((
                            states,
                          ) {
                            if (entry.key.isOdd) return Colors.grey.shade50;
                            return null;
                          }),
                          cells: [
                            DataCell(
                              Text(
                                (row['membership_id'] ?? row['id'] ?? '-')
                                    .toString(),
                                style: const TextStyle(fontSize: 13),
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
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFA812,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFFA812,
                                    ).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  _statusLabel(row),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFB77900),
                                  ),
                                ),
                              ),
                            ),
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
            );
          },
        ),
      ),
    );
  }

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
            child: _buildTable(),
          ),
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
          maxWidth: 1000,
          maxHeight: size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildHeader(), Flexible(child: _buildBody())],
        ),
      ),
    );
  }
}
