import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:file_saver/file_saver.dart';
import 'package:http/http.dart' as http;
import '../modal/new_products.dart';
import 'dart:ui' as ui;

Future<void> exportProductsToExcel(
  BuildContext context,
  List<Product> items,
) async {
  try {
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final xlsio.Workbook workbook = xlsio.Workbook();
    final xlsio.Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Products';

    // Header
    sheet.getRangeByIndex(1, 1).setText('Image');
    sheet.getRangeByIndex(1, 2).setText('Name');
    sheet.getRangeByIndex(1, 3).setText('Description');
    final xlsio.Range header = sheet.getRangeByIndex(1, 1, 1, 3);
    header.cellStyle.bold = true;
    header.cellStyle.backColor = '#E6F0FF';

    double maxImageWidthPx = 0;
    for (int i = 0; i < items.length; i++) {
      final Product p = items[i];
      final int row = i + 2; // data rows start at 2

      // Text data
      sheet.getRangeByIndex(row, 2).setText(p.name);
      sheet.getRangeByIndex(row, 3).setText(p.description);

      // Image: prefer in-memory bytes; fall back to fetch from URL
      Uint8List? imageBytes = p.imageBytes;
      if (imageBytes == null && p.imageUrl != null) {
        try {
          final http.Response resp = await http.get(Uri.parse(p.imageUrl!));
          if (resp.statusCode == 200) imageBytes = resp.bodyBytes;
        } catch (_) {
          imageBytes = null;
        }
      }

      if (imageBytes != null && imageBytes.isNotEmpty) {
        int imgW = 64;
        int imgH = 48;
        try {
          final ui.Image decoded = await decodeImageFromList(imageBytes);
          imgW = decoded.width;
          imgH = decoded.height;
        } catch (_) {}

        final xlsio.Picture picture = sheet.pictures.addStream(
          row,
          1,
          imageBytes,
        );
        picture.width = imgW;
        picture.height = imgH;

        // Adjust row height to fit image (Excel points ~= pixels * 0.75 at 96 DPI)
        sheet.getRangeByIndex(row, 1).rowHeight = imgH * 0.75;
        if (imgW > maxImageWidthPx) maxImageWidthPx = imgW.toDouble();
      }
    }

    // Autofit text columns, set first column width based on largest image
    sheet.getRangeByIndex(1, 2, items.length + 1, 3).autoFitColumns();
    // Approximate conversion from pixels to Excel column width units
    final double imageColWidth =
        (maxImageWidthPx > 0) ? (maxImageWidthPx / 7.0) : 12.0;
    sheet.getRangeByIndex(1, 1, 1, 1).columnWidth = imageColWidth;

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final DateTime now = DateTime.now();
    final String dd = now.day.toString().padLeft(2, '0');
    final String mm = now.month.toString().padLeft(2, '0');
    final String yyyy = now.year.toString().padLeft(4, '0');
    final String fileName = '$mm-$dd-$yyyy Products';
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported ${items.length} rows to $fileName.xlsx'),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
  }
}
