import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> exportAttendanceLogPdf({
  required BuildContext context,
  required List<List<String>> rows,
}) async {
  if (rows.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No records to export.')));
    }
    return;
  }

  try {
    final pdf = pw.Document();
    final DateTime now = DateTime.now();
    final String reportDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final List<String> headers = [
      'Customer',
      'ID',
      'Date',
      'Time In',
      'Time Out',
      'Duration',
      'Verified By',
      'Status',
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Text(
              'Attendance Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Generated: $reportDate'),
            pw.SizedBox(height: 4),
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
                0: const pw.FlexColumnWidth(2.2),
                1: const pw.FlexColumnWidth(0.9),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1.2),
                5: const pw.FlexColumnWidth(1.1),
                6: const pw.FlexColumnWidth(1.8),
                7: const pw.FlexColumnWidth(1.0),
              },
            ),
          ];
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    final String filename =
        'Attendance_Report_${reportDate.replaceAll('-', '')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

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
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}
