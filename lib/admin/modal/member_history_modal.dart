import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_saver/file_saver.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────
//  Public entry-point
// ─────────────────────────────────────────────────────────────

/// Shows the Time-In / Time-Out history modal for [customer].
///
/// [customer] must at minimum contain:
///   - `customerId` (int | String)
///   - `name` (String)
Future<void> showMemberHistoryModal(
  BuildContext context,
  Map<String, dynamic> customer,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _MemberHistoryDialog(customer: customer),
  );
}

// ─────────────────────────────────────────────────────────────
//  Dialog widget
// ─────────────────────────────────────────────────────────────

class _MemberHistoryDialog extends StatefulWidget {
  const _MemberHistoryDialog({required this.customer});

  final Map<String, dynamic> customer;

  @override
  State<_MemberHistoryDialog> createState() => _MemberHistoryDialogState();
}

class _MemberHistoryDialogState extends State<_MemberHistoryDialog> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;
  bool _isExporting = false;

  // Sorting state
  int _sortColumnIndex = 0;
  bool _sortAscending = false; // newest first by default

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  int get _customerId {
    final dynamic v = widget.customer['customerId'];
    return v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
  }

  String get _memberName =>
      (widget.customer['name'] ?? widget.customer['fullName'] ?? 'Member')
          .toString()
          .trim();

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getCustomerAttendanceLogs(
        customerId: _customerId,
      );
      if (mounted) {
        setState(() {
          _logs = data;
          _isLoading = false;
          _applySortToLogs();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load logs: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ── Sorting ──────────────────────────────────────────────

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _applySortToLogs();
    });
  }

  void _applySortToLogs() {
    _logs.sort((a, b) {
      dynamic aVal, bVal;
      switch (_sortColumnIndex) {
        case 0: // Date / Time-In
          aVal = a['time_in'] ?? a['date'] ?? '';
          bVal = b['time_in'] ?? b['date'] ?? '';
          break;
        case 1: // Time-Out
          aVal = a['time_out'] ?? '';
          bVal = b['time_out'] ?? '';
          break;
        case 2: // Status
          aVal = a['status'] ?? '';
          bVal = b['status'] ?? '';
          break;
        case 3: // Verified By
          aVal = a['verified_by'] ?? '';
          bVal = b['verified_by'] ?? '';
          break;
        default:
          return 0;
      }
      final int cmp = aVal.toString().compareTo(bVal.toString());
      return _sortAscending ? cmp : -cmp;
    });
  }

  // ── Formatters ────────────────────────────────────────────

  String _fmt(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final pad = (int n) => n.toString().padLeft(2, '0');
      return '${pad(dt.month)}/${pad(dt.day)}/${dt.year}  '
          '${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';
    } catch (_) {
      return raw;
    }
  }

  // ── PDF Export ────────────────────────────────────────────

  Future<void> _exportPdf() async {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No logs to export')));
      return;
    }
    setState(() => _isExporting = true);
    try {
      await exportMemberHistoryToPdf(
        context: context,
        memberName: _memberName,
        customerId: _customerId,
        logs: _logs,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
              Icons.access_time,
              color: Colors.black87,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time In / Out History',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _memberName,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Export PDF button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child:
                _isExporting
                    ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black87,
                      ),
                    )
                    : Tooltip(
                      message: _isLoading ? 'Loading logs...' : 'Export to PDF',
                      child: ElevatedButton.icon(
                        onPressed:
                            _isLoading || _error != null ? null : _exportPdf,
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text(
                          'Export PDF',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: ButtonStyle(
                          animationDuration: Duration.zero,
                          backgroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.disabled)) {
                              return Colors.red.shade200;
                            }
                            return Colors.red.shade700;
                          }),
                          foregroundColor: const WidgetStatePropertyAll(
                            Colors.white,
                          ),
                          overlayColor: const WidgetStatePropertyAll(
                            Colors.transparent,
                          ),
                          elevation: const WidgetStatePropertyAll(0),
                          shadowColor: const WidgetStatePropertyAll(
                            Colors.transparent,
                          ),
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
          ),
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
                onPressed: _fetchLogs,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_logs.isEmpty) {
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
                'No attendance records found for $_memberName.',
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
        // DataTable
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _buildDataTable(),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    final int totalVisits = _logs.length;
    final int totalIn =
        _logs.where((l) => (l['status'] ?? '').toString() == 'IN').length;
    final int totalOut =
        _logs.where((l) => (l['status'] ?? '').toString() == 'OUT').length;

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
                  columnSpacing: 34,
                  columns: [
                    DataColumn(
                      label: Text('Time In ($totalIn)'),
                      onSort: (i, asc) => _sort(i, asc),
                    ),
                    DataColumn(
                      label: Text('Time Out ($totalOut)'),
                      onSort: (i, asc) => _sort(i, asc),
                    ),
                    DataColumn(
                      label: Text('Status (Total: $totalVisits)'),
                      onSort: (i, asc) => _sort(i, asc),
                    ),
                    DataColumn(
                      label: const Text('Verified By'),
                      onSort: (i, asc) => _sort(i, asc),
                    ),
                    DataColumn(label: const Text('Platform')),
                  ],
                  rows:
                      _logs.asMap().entries.map((entry) {
                        final int idx = entry.key;
                        final Map<String, dynamic> log = entry.value;
                        final String status = (log['status'] ?? '').toString();
                        final bool isIn = status == 'IN';

                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((
                            states,
                          ) {
                            if (idx.isOdd) return Colors.grey.shade50;
                            return null;
                          }),
                          cells: [
                            DataCell(
                              Text(
                                _fmt(log['time_in']?.toString()),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            DataCell(
                              Text(
                                _fmt(log['time_out']?.toString()),
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
                                  color:
                                      isIn
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        isIn
                                            ? Colors.green.shade200
                                            : Colors.red.shade200,
                                  ),
                                ),
                                child: Text(
                                  status.isEmpty ? '—' : status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isIn
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                log['verified_by']?.toString().isEmpty ?? true
                                    ? '—'
                                    : log['verified_by'].toString(),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            DataCell(
                              Text(
                                log['platform']?.toString().isEmpty ?? true
                                    ? '—'
                                    : log['platform'].toString(),
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

// ─────────────────────────────────────────────────────────────
//  Standalone PDF export function
// ─────────────────────────────────────────────────────────────

/// Generates a formatted PDF of [logs] for the given [memberName] and
/// triggers a browser download automatically.
Future<void> exportMemberHistoryToPdf({
  required BuildContext context,
  required String memberName,
  required int customerId,
  required List<Map<String, dynamic>> logs,
}) async {
  if (logs.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('No logs to export')));
    return;
  }

  try {
    // Load fonts (same pattern as existing pdf_stats_export.dart)
    pw.ThemeData theme;
    try {
      final base = pw.Font.ttf(
        (await rootBundle.load(
          'assets/fonts/NotoSans-Regular.ttf',
        )).buffer.asByteData(),
      );
      final bold = pw.Font.ttf(
        (await rootBundle.load(
          'assets/fonts/NotoSans-Bold.ttf',
        )).buffer.asByteData(),
      );
      theme = pw.ThemeData.withFont(base: base, bold: bold);
    } catch (_) {
      theme = pw.ThemeData.base();
    }

    final pdf = pw.Document(theme: theme);

    // Helper: format datetime string
    String fmt(String? raw) {
      if (raw == null || raw.isEmpty) return '-';
      try {
        final dt = DateTime.parse(raw).toLocal();
        final p = (int n) => n.toString().padLeft(2, '0');
        return '${p(dt.month)}/${p(dt.day)}/${dt.year} ${p(dt.hour)}:${p(dt.minute)}';
      } catch (_) {
        return raw;
      }
    }

    // Build rows (header + data)
    final headers = [
      'Time In',
      'Time Out',
      'Status',
      'Verified By',
      'Platform',
    ];

    final dataRows =
        logs
            .map(
              (l) => [
                fmt(l['time_in']?.toString()),
                fmt(l['time_out']?.toString()),
                (l['status'] ?? '').toString(),
                (l['verified_by']?.toString().isEmpty ?? true)
                    ? '-'
                    : l['verified_by'].toString(),
                (l['platform']?.toString().isEmpty ?? true)
                    ? '-'
                    : l['platform'].toString(),
              ],
            )
            .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build:
            (pw.Context ctx) => [
              // ── Page header ──────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(bottom: 14),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RNR Fitness Gym - Attendance History Report',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo800,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Member: ',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.Text(
                          memberName,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Text(
                          'Customer ID: #$customerId',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated: ${DateTime.now().toString().split('.')[0]}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // ── Summary row ───────────────────────────────────
              _pdfSummaryBar(logs),
              pw.SizedBox(height: 14),

              // ── Attendance table ──────────────────────────────
              _pdfAttendanceTable(headers, dataRows),
            ],
      ),
    );

    final Uint8List pdfBytes = await pdf.save();

    final now = DateTime.now();
    final timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    final safeN = memberName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(' ', '_');
    await FileSaver.instance.saveFile(
      name: 'AttendanceHistory_${safeN}_$timestamp',
      bytes: pdfBytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported ${logs.length} record(s) - AttendanceHistory_${safeN}_$timestamp.pdf',
          ),
          backgroundColor: Colors.indigo,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
    }
  }
}

// ── PDF builder helpers (private) ─────────────────────────────

pw.Widget _pdfSummaryBar(List<Map<String, dynamic>> logs) {
  final int totalIn =
      logs.where((l) => (l['status'] ?? '').toString() == 'IN').length;
  final int totalOut =
      logs.where((l) => (l['status'] ?? '').toString() == 'OUT').length;

  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: pw.BoxDecoration(
      color: PdfColors.indigo50,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: PdfColors.indigo100, width: 0.5),
    ),
    child: pw.Row(
      children: [
        _pdfStatPill('Total Records', logs.length, PdfColors.indigo800),
        pw.SizedBox(width: 24),
        _pdfStatPill('Time-In Count', totalIn, PdfColors.green800),
        pw.SizedBox(width: 24),
        _pdfStatPill('Time-Out Count', totalOut, PdfColors.red800),
      ],
    ),
  );
}

pw.Widget _pdfStatPill(String label, int value, PdfColor color) {
  return pw.Row(
    children: [
      pw.Text(
        '$label: ',
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
      pw.Text(
        value.toString(),
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );
}

pw.Widget _pdfAttendanceTable(
  List<String> headers,
  List<List<String>> dataRows,
) {
  const colWidths = {
    0: pw.FlexColumnWidth(2.5), // Time In
    1: pw.FlexColumnWidth(2.5), // Time Out
    2: pw.FlexColumnWidth(1.0), // Status
    3: pw.FlexColumnWidth(2.0), // Verified By
    4: pw.FlexColumnWidth(1.2), // Platform
  };

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    columnWidths: colWidths,
    children: [
      // Header row
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
        children:
            headers
                .map(
                  (h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: PdfColors.indigo800,
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
      // Data rows
      ...dataRows.asMap().entries.map((entry) {
        final int idx = entry.key;
        final List<String> row = entry.value;
        final String status = row[2]; // Status column
        final bool isIn = status == 'IN';

        return pw.TableRow(
          decoration: pw.BoxDecoration(
            color: idx.isOdd ? PdfColors.grey50 : PdfColors.white,
          ),
          children:
              row.asMap().entries.map((cell) {
                final int colIdx = cell.key;
                final String text = cell.value;
                final bool isStatusCol = colIdx == 2;

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: pw.Text(
                    text,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color:
                          isStatusCol
                              ? (isIn ? PdfColors.green700 : PdfColors.red700)
                              : PdfColors.black,
                      fontWeight:
                          isStatusCol
                              ? pw.FontWeight.bold
                              : pw.FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
        );
      }),
    ],
  );
}
