import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/attendance_service.dart';

class TimeInOutHistoryExportController {
  final ValueNotifier<bool> isExporting = ValueNotifier<bool>(false);

  Future<void> export({
    required BuildContext context,
    required String memberName,
    required int customerId,
    required List<AttendanceRecord> records,
    required String dateRangeStr,
  }) async {
    if (isExporting.value || records.isEmpty) return;

    isExporting.value = true;
    try {
      await exportTimeInOutHistoryReportPdf(
        context: context,
        memberName: memberName,
        customerId: customerId,
        records: records,
        dateRangeStr: dateRangeStr,
      );
    } finally {
      isExporting.value = false;
    }
  }

  void dispose() {
    isExporting.dispose();
  }
}

class TimeInOutHistoryExportButton extends StatelessWidget {
  const TimeInOutHistoryExportButton({
    super.key,
    required this.isLoading,
    required this.isExporting,
    required this.hasError,
    required this.hasRecords,
    required this.onExport,
  });

  final bool isLoading;
  final bool isExporting;
  final bool hasError;
  final bool hasRecords;
  final Future<void> Function() onExport;

  @override
  Widget build(BuildContext context) {
    if (isExporting) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }

    return Tooltip(
      message: isLoading ? 'Loading logs...' : 'Export to PDF',
      child: ElevatedButton.icon(
        onPressed: (isLoading || hasError || !hasRecords) ? null : onExport,
        icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
        label: const Text('Export PDF'),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFBDBDBD),
          disabledForegroundColor: Colors.white60,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(0, 40),
        ),
      ),
    );
  }
}

bool _hasLogValue(dynamic value) {
  final String text = value?.toString().trim() ?? '';
  return text.isNotEmpty && text.toLowerCase() != 'null';
}

String _normalizedStatusValue(Map<String, dynamic> log) {
  final String raw = (log['status'] ?? '').toString().trim().toUpperCase();
  if (raw == 'IN' || raw == 'OUT') return raw;
  return _hasLogValue(log['time_out']) ? 'OUT' : 'IN';
}

List<Map<String, dynamic>> _expandLogsByEvent(List<Map<String, dynamic>> logs) {
  final List<Map<String, dynamic>> expanded = [];

  for (final original in logs) {
    final Map<String, dynamic> base = Map<String, dynamic>.from(original);
    final bool hasTimeIn = _hasLogValue(base['time_in']);
    final bool hasTimeOut = _hasLogValue(base['time_out']);

    if (hasTimeIn) {
      final row = Map<String, dynamic>.from(base);
      row['status'] = 'IN';
      row['date'] = row['time_in'] ?? row['date'];
      expanded.add(row);
    }

    if (hasTimeOut) {
      final row = Map<String, dynamic>.from(base);
      row['status'] = 'OUT';
      row['date'] = row['time_out'] ?? row['date'];
      expanded.add(row);
    }

    if (!hasTimeIn && !hasTimeOut) {
      final row = Map<String, dynamic>.from(base);
      row['status'] = _normalizedStatusValue(row);
      expanded.add(row);
    }
  }

  return expanded;
}

Future<pw.ThemeData> _loadBundledFontsTheme() async {
  try {
    final pw.Font base = pw.Font.ttf(
      (await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      )).buffer.asByteData(),
    );
    final pw.Font bold = pw.Font.ttf(
      (await rootBundle.load(
        'assets/fonts/NotoSans-Bold.ttf',
      )).buffer.asByteData(),
    );
    return pw.ThemeData.withFont(base: base, bold: bold);
  } catch (_) {
    return pw.ThemeData.base();
  }
}

String _formatDateTime(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';

  try {
    final DateTime dt = DateTime.parse(raw).toLocal();
    final String mm = dt.month.toString().padLeft(2, '0');
    final String dd = dt.day.toString().padLeft(2, '0');
    final String yyyy = dt.year.toString();
    final int hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final String min = dt.minute.toString().padLeft(2, '0');
    final String period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$mm/$dd/$yyyy $hour12:$min $period';
  } catch (_) {
    return raw;
  }
}

List<Map<String, dynamic>> _buildLogsFromRecords(
  List<AttendanceRecord> records,
) {
  return records
      .map(
        (record) => <String, dynamic>{
          'time_in': record.timeIn?.toIso8601String(),
          'time_out': record.timeOut?.toIso8601String(),
          'status': record.status,
          'verified_by': record.verifyingAdminName,
        },
      )
      .toList();
}

Future<void> exportTimeInOutHistoryReportPdf({
  required BuildContext context,
  required String memberName,
  required int customerId,
  required List<AttendanceRecord> records,
  required String dateRangeStr,
}) async {
  final List<Map<String, dynamic>> expandedLogs = _expandLogsByEvent(
    _buildLogsFromRecords(records),
  );

  if (expandedLogs.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No logs to export.')));
    }
    return;
  }

  try {
    final pw.ThemeData theme = await _loadBundledFontsTheme();
    final pw.Document pdf = pw.Document(theme: theme);

    final List<List<String>> dataRows =
        expandedLogs
            .map(
              (log) => [
                _formatDateTime(log['time_in']?.toString()),
                _formatDateTime(log['time_out']?.toString()),
                _normalizedStatusValue(log),
                (log['verified_by']?.toString().trim().isNotEmpty ?? false)
                    ? log['verified_by'].toString().trim()
                    : '-',
              ],
            )
            .toList();

    final DateTime now = DateTime.now();
    final int hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final String period = now.hour >= 12 ? 'PM' : 'AM';
    final String generatedAt =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '$hour12:${now.minute.toString().padLeft(2, '0')} $period';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Text(
              'Time In/Out History Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Member: $memberName'),
            pw.Text('Customer ID: #$customerId'),
            if (dateRangeStr.isNotEmpty) pw.Text('Date Filter: $dateRangeStr'),
            pw.Text('Generated: $generatedAt'),
            pw.Text('Rows: ${dataRows.length}'),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: const ['Time In', 'Time Out', 'Status', 'Verified By'],
              data: dataRows,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(1.8),
                1: const pw.FlexColumnWidth(1.8),
                2: const pw.FlexColumnWidth(0.9),
                3: const pw.FlexColumnWidth(1.8),
              },
            ),
          ];
        },
      ),
    );

    final Uint8List bytes = await pdf.save();

    final String safeName = memberName
        .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '')
        .trim()
        .replaceAll(' ', '_');
    final String timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final String filename = 'TimeInOut_History_${safeName}_$timestamp';

    await FileSaver.instance.saveFile(
      name: filename,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );

    await Printing.sharePdf(bytes: bytes, filename: '$filename.pdf');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${dataRows.length} row(s) to $filename.pdf'),
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
