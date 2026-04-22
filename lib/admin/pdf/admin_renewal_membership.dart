import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<pw.ThemeData> _loadBundledFontsTheme() async {
  try {
    final pw.Font base = pw.Font.ttf(
      (await rootBundle.load('fonts/NotoSans-Regular.ttf')).buffer.asByteData(),
    );
    final pw.Font bold = pw.Font.ttf(
      (await rootBundle.load('fonts/NotoSans-Bold.ttf')).buffer.asByteData(),
    );
    return pw.ThemeData.withFont(base: base, bold: bold);
  } catch (_) {
    return pw.ThemeData.base();
  }
}

Future<void> exportRenewalMembershipHistoryPdf({
  required BuildContext context,
  required String memberName,
  required int customerId,
  required String rangeLabel,
  required String membershipFilter,
  required List<List<String>> rows,
}) async {
  if (rows.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No rows to export.')));
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

    const List<String> headers = [
      'Start Date',
      'Expiration Date',
      'Membership',
      'Verified By',
      'Updated At',
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Text(
              'Renew Membership History Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Member: $memberName'),
            pw.Text('Customer ID: $customerId'),
            pw.Text('Date Filter: $rangeLabel'),
            pw.Text('Membership Filter: $membershipFilter'),
            pw.Text('Generated At: $generatedAt'),
            pw.Text('Rows: ${rows.length}'),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
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
                0: const pw.FlexColumnWidth(1.3),
                1: const pw.FlexColumnWidth(1.3),
                2: const pw.FlexColumnWidth(1.1),
                3: const pw.FlexColumnWidth(1.8),
                4: const pw.FlexColumnWidth(1.5),
              },
            ),
          ];
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    final String filename =
        'Renewal_History_${customerId}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    await FileSaver.instance.saveFile(
      name: filename,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );

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
