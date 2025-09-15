import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:file_saver/file_saver.dart';

Future<void> exportAdminsToExcel(
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
    sheet.name = 'Admins';

    // Header
    sheet.getRangeByIndex(1, 1).setText('Name');
    sheet.getRangeByIndex(1, 2).setText('Email');
    sheet.getRangeByIndex(1, 3).setText('Contact');
    sheet.getRangeByIndex(1, 4).setText('Date of Birth');
    sheet.getRangeByIndex(1, 5).setText('Status');

    final xlsio.Range headerRange = sheet.getRangeByIndex(1, 1, 1, 5);
    headerRange.cellStyle.bold = true;
    headerRange.cellStyle.backColor = '#E6F0FF';

    for (int i = 0; i < rows.length; i++) {
      final Map<String, dynamic> a = rows[i];
      final int rowIdx = i + 2; // data starts at row 2

      final String first = (a['first_name'] ?? a['firstName'] ?? '').toString();
      final String middle =
          (a['middle_name'] ?? a['middleName'] ?? '').toString();
      final String last = (a['last_name'] ?? a['lastName'] ?? '').toString();
      final String name = [
        first,
        middle,
        last,
      ].where((s) => s.isNotEmpty).join(' ');

      final String email = (a['email_address'] ?? a['email'] ?? '').toString();
      final String contact =
          (a['phone_number'] ?? a['contactNumber'] ?? '').toString();
      final String dob =
          (a['date_of_birth'] ?? a['dateOfBirth'] ?? '').toString();
      final String status = (a['status'] ?? 'active').toString();

      sheet.getRangeByIndex(rowIdx, 1).setText(name);
      sheet.getRangeByIndex(rowIdx, 2).setText(email);
      sheet.getRangeByIndex(rowIdx, 3).setText(contact);
      sheet.getRangeByIndex(rowIdx, 4).setText(dob);
      sheet.getRangeByIndex(rowIdx, 5).setText(status);
    }

    final int lastRow = rows.length + 1;
    sheet.getRangeByIndex(1, 1, lastRow, 5).autoFitColumns();

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final DateTime now = DateTime.now();
    final String dd = now.day.toString().padLeft(2, '0');
    final String mm = now.month.toString().padLeft(2, '0');
    final String yyyy = now.year.toString().padLeft(4, '0');
    final String fileName = '$mm-$dd-$yyyy Admins';
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
