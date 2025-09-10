import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:file_saver/file_saver.dart';

Future<void> exportCustomersToExcel(
  BuildContext context,
  List<Map<String, dynamic>> rows,
) async {
  try {
    if (rows.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final xlsio.Workbook workbook = xlsio.Workbook();
    final xlsio.Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Customers';

    // Header
    sheet.getRangeByIndex(1, 1).setText('Name');
    sheet.getRangeByIndex(1, 2).setText('Contact Number');
    sheet.getRangeByIndex(1, 3).setText('Membership Type');
    sheet.getRangeByIndex(1, 4).setText('Membership Start Date');
    sheet.getRangeByIndex(1, 5).setText('Membership Expiration Date');

    // Style header row (row 1)
    final xlsio.Range headerRange = sheet.getRangeByIndex(1, 1, 1, 5);
    headerRange.cellStyle.bold = true;
    headerRange.cellStyle.backColor = '#E6F0FF';

    for (int i = 0; i < rows.length; i++) {
      final Map<String, dynamic> c = rows[i];
      final DateTime start = c['startDate'] as DateTime;
      final DateTime exp = c['expirationDate'] as DateTime;
      final int rowIdx = i + 2; // data starts at row 2
      sheet.getRangeByIndex(rowIdx, 1).setText((c['name'] ?? '').toString());
      sheet
          .getRangeByIndex(rowIdx, 2)
          .setText((c['contactNumber'] ?? c['phone_number'] ?? '').toString());
      final String membershipStr =
          (c['membershipType'] ?? c['membership_type'] ?? '').toString();
      sheet.getRangeByIndex(rowIdx, 3).setText(membershipStr);
      sheet.getRangeByIndex(rowIdx, 4).setText(_formatDate(start));
      sheet.getRangeByIndex(rowIdx, 5).setText(_formatDate(exp));

      // Apply background color to Membership Type column per row
      String bgHex;
      switch (membershipStr) {
        case 'Daily':
          bgHex = '#FFEAD1'; // light orange
          break;
        case 'Half Month':
          bgHex = '#E5F0FF'; // light blue
          break;
        case 'Monthly':
          bgHex = '#E6F7EA'; // light green
          break;
        default:
          bgHex = '#FFFFFF';
      }
      final xlsio.Range membershipCell = sheet.getRangeByIndex(rowIdx, 3);
      membershipCell.cellStyle.backColor = bgHex;
    }

    // Auto-fit columns based on content (apply on range, not worksheet)
    final int lastRow = rows.length + 1; // header + data
    sheet.getRangeByIndex(1, 1, lastRow, 5).autoFitColumns();

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final DateTime now = DateTime.now();
    final String dd = now.day.toString().padLeft(2, '0');
    final String mm = now.month.toString().padLeft(2, '0');
    final String yyyy = now.year.toString().padLeft(4, '0');
    final String fileName = '$mm-$dd-$yyyy Customers';
    final Uint8List u8 = Uint8List.fromList(bytes);
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: u8,
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported ${rows.length} rows to $fileName.xlsx')),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
  }
}

String _formatDate(DateTime date) {
  final String dd = date.day.toString().padLeft(2, '0');
  final String mm = date.month.toString().padLeft(2, '0');
  final String yyyy = date.year.toString().padLeft(4, '0');
  return '$mm/$dd/$yyyy';
}
