import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:file_saver/file_saver.dart';

Future<void> exportTrainersToExcel(
  BuildContext context,
  List<Map<String, String>> rows,
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
    sheet.name = 'Trainers';

    // Header
    sheet.getRangeByIndex(1, 1).setText('First Name');
    sheet.getRangeByIndex(1, 2).setText('Middle Name');
    sheet.getRangeByIndex(1, 3).setText('Last Name');
    sheet.getRangeByIndex(1, 4).setText('Contact Number');
    sheet.getRangeByIndex(1, 5).setText('Status');

    final xlsio.Range headerRange = sheet.getRangeByIndex(1, 1, 1, 5);
    headerRange.cellStyle.bold = true;
    headerRange.cellStyle.backColor = '#E6F0FF';

    for (int i = 0; i < rows.length; i++) {
      final Map<String, String> t = rows[i];
      final int rowIdx = i + 2; // data starts at row 2

      sheet.getRangeByIndex(rowIdx, 1).setText(t['firstName'] ?? '');
      sheet.getRangeByIndex(rowIdx, 2).setText(t['middleName'] ?? '');
      sheet.getRangeByIndex(rowIdx, 3).setText(t['lastName'] ?? '');
      sheet.getRangeByIndex(rowIdx, 4).setText(t['contactNumber'] ?? '');
      sheet.getRangeByIndex(rowIdx, 5).setText((t['status'] ?? 'active'));
    }

    // Autofit
    final int lastRow = rows.length + 1;
    sheet.getRangeByIndex(1, 1, lastRow, 5).autoFitColumns();

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final DateTime now = DateTime.now();
    final String dd = now.day.toString().padLeft(2, '0');
    final String mm = now.month.toString().padLeft(2, '0');
    final String yyyy = now.year.toString().padLeft(4, '0');
    final String fileName = '$mm-$dd-$yyyy Trainers';
    final Uint8List u8 = Uint8List.fromList(bytes);
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: u8,
      fileExtension: 'xlsx',
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
