import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

String _formatDate(dynamic value) {
  if (value == null) return '-';
  final String text = value.toString().trim();
  if (text.isEmpty) return '-';

  DateTime? parsed = DateTime.tryParse(text);
  parsed ??= DateTime.tryParse(text.replaceFirst(' ', 'T'));
  if (parsed == null) return text;

  final String month = parsed.month.toString().padLeft(2, '0');
  final String day = parsed.day.toString().padLeft(2, '0');
  final String year = parsed.year.toString();
  return '$month/$day/$year';
}

String _renewedByLabel(Map<String, dynamic> row) {
  final dynamic raw =
      row['renewed_by'] ?? row['renewed_by_name'] ?? row['updated_by'];
  final String text = (raw ?? '').toString().trim();
  return text.isEmpty ? 'System' : text;
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

Future<void> exportMembershipHistoryPdf({
  required BuildContext context,
  required String memberName,
  required int customerId,
  required List<Map<String, dynamic>> rows,
}) async {
  if (rows.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No membership history to export.')),
      );
    }
    return;
  }

  try {
    final pw.ThemeData theme = await _loadBundledFontsTheme();
    final pw.Document pdf = pw.Document(theme: theme);
    final DateTime now = DateTime.now();
    final String generatedAt =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final List<List<String>> tableRows =
        rows.map((row) {
          return [
            (row['membership_id'] ?? row['id'] ?? '-').toString(),
            _formatDate(row['start_date']),
            _formatDate(row['expiration_date'] ?? row['end_date']),
            _statusLabel(row),
            _renewedByLabel(row),
          ];
        }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Text(
              'Membership History Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Member: $memberName'),
            pw.Text('Customer ID: $customerId'),
            pw.Text('Generated At: $generatedAt'),
            pw.Text('Rows: ${tableRows.length}'),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Membership ID',
                'Start Date',
                'End Date',
                'Status',
                'Renewed By',
              ],
              data: tableRows,
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
                0: const pw.FlexColumnWidth(1.0),
                1: const pw.FlexColumnWidth(1.15),
                2: const pw.FlexColumnWidth(1.15),
                3: const pw.FlexColumnWidth(1.0),
                4: const pw.FlexColumnWidth(1.5),
              },
            ),
          ];
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    final String filename =
        'Membership_History_${customerId}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

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
          content: Text('Exported ${rows.length} row(s) to $filename.pdf'),
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
