import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:syncfusion_officechart/officechart.dart' as office;
import 'package:file_saver/file_saver.dart';

Future<void> exportStatsToExcel(
  BuildContext context, {
  required String sheetName,
  required List<List<dynamic>> rows,
  bool withBarChart = true,
  String? chartTitle,
}) async {
  try {
    if (rows.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final xlsio.Workbook workbook = xlsio.Workbook();
    final xlsio.Worksheet sheet = workbook.worksheets[0];
    sheet.name = sheetName;

    for (int r = 0; r < rows.length; r++) {
      final List<dynamic> row = rows[r];
      for (int c = 0; c < row.length; c++) {
        final cell = sheet.getRangeByIndex(r + 1, c + 1);
        final dynamic val = row[c];
        if (val is num) {
          cell.setNumber(val.toDouble());
        } else {
          cell.setText(val.toString());
        }
      }
    }

    // Style header row
    final xlsio.Range header = sheet.getRangeByIndex(
      1,
      1,
      1,
      rows.first.length,
    );
    header.cellStyle.bold = true;
    header.cellStyle.backColor = '#EFEFEF';
    sheet
        .getRangeByIndex(1, 1, rows.length, rows.first.length)
        .autoFitColumns();

    // Optionally add a clustered column (bar) chart for first two columns
    if (withBarChart && rows.length > 2 && rows.first.length >= 2) {
      final int lastRow = rows.length;
      // Enforce UI-aligned caps: Memberships = 100, Week/Month/Trainers = 50
      final String title = (chartTitle ?? sheetName).toLowerCase();
      final int axisMax = title.contains('membership') ? 100 : 50;

      final office.ChartCollection charts = office.ChartCollection(sheet);
      final office.Chart chart = charts.add();
      chart.chartType = office.ExcelChartType.column;
      // Provide dataRange so axis properties are supported
      chart.dataRange = sheet.getRangeByName('A1:B$lastRow');
      final office.ChartSerie series = chart.series.add();
      series.categoryLabels = sheet.getRangeByName('A2:A$lastRow');
      series.values = sheet.getRangeByName('B2:B$lastRow');
      series.name = chartTitle ?? sheetName;
      chart.isSeriesInRows = false;
      chart.chartTitle = chartTitle ?? sheetName;
      chart.primaryValueAxis.minimumValue = 0;
      chart.primaryValueAxis.maximumValue = axisMax.toDouble();
      final int topRow = lastRow > 2 ? lastRow - 1 : lastRow;
      chart.topRow = topRow;
      // Center the chart horizontally by spanning a balanced width
      chart.leftColumn = 11; // start at column K
      chart.rightColumn = 16; // end at column P
      chart.bottomRow = chart.topRow + 18;
      sheet.charts = charts;
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final DateTime now = DateTime.now();
    final String ts =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final Uint8List u8 = Uint8List.fromList(bytes);
    await FileSaver.instance.saveFile(
      name: '${sheetName}_$ts',
      bytes: u8,
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exported ${rows.length - 1} rows to ${sheetName}_$ts.xlsx',
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
  }
}

/// Export multiple sheets into a single Excel workbook and save once.
Future<void> exportMultipleSheetsToExcel(
  BuildContext context, {
  required List<({String sheetName, List<List<dynamic>> rows})> sheets,
  String? fileName,
  bool withBarCharts = true,
}) async {
  try {
    if (sheets.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final xlsio.Workbook workbook = xlsio.Workbook();

    // Ensure at least one worksheet exists; reuse first for first sheet
    for (int i = 0; i < sheets.length; i++) {
      final ({String sheetName, List<List<dynamic>> rows}) s = sheets[i];
      final xlsio.Worksheet ws =
          i == 0
              ? workbook.worksheets[0]
              : workbook.worksheets.addWithName(s.sheetName);
      ws.name = s.sheetName;

      final List<List<dynamic>> rows = s.rows;
      if (rows.isEmpty) continue;

      for (int r = 0; r < rows.length; r++) {
        final List<dynamic> row = rows[r];
        for (int c = 0; c < row.length; c++) {
          final cell = ws.getRangeByIndex(r + 1, c + 1);
          final dynamic val = row[c];
          if (val is num) {
            cell.setNumber(val.toDouble());
          } else {
            cell.setText(val.toString());
          }
        }
      }

      // Style header and auto-fit
      final xlsio.Range header = ws.getRangeByIndex(1, 1, 1, rows.first.length);
      header.cellStyle.bold = true;
      header.cellStyle.backColor = '#EFEFEF';
      ws.getRangeByIndex(1, 1, rows.length, rows.first.length).autoFitColumns();

      if (withBarCharts && rows.length > 2 && rows.first.length >= 2) {
        final int lastRow = rows.length;
        final String title = s.sheetName.toLowerCase();
        final int axisMax = title.contains('membership') ? 100 : 50;

        final office.ChartCollection charts = office.ChartCollection(ws);
        final office.Chart chart = charts.add();
        chart.chartType = office.ExcelChartType.column;
        chart.dataRange = ws.getRangeByName('A1:B$lastRow');
        final office.ChartSerie series = chart.series.add();
        series.categoryLabels = ws.getRangeByName('A2:A$lastRow');
        series.values = ws.getRangeByName('B2:B$lastRow');
        series.name = s.sheetName;
        chart.isSeriesInRows = false;
        chart.chartTitle = s.sheetName;
        chart.primaryValueAxis.minimumValue = 0;
        chart.primaryValueAxis.maximumValue = axisMax.toDouble();
        final int topRow = lastRow > 2 ? lastRow - 1 : lastRow;
        chart.topRow = topRow;
        chart.leftColumn = 11;
        chart.rightColumn = 16;
        chart.bottomRow = chart.topRow + 18;
        ws.charts = charts;
      }
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final DateTime now = DateTime.now();
    final String ts =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final String baseName =
        (fileName == null || fileName.trim().isEmpty)
            ? 'Statistics_Export'
            : fileName;
    final Uint8List u8 = Uint8List.fromList(bytes);
    await FileSaver.instance.saveFile(
      name: '${baseName}_$ts',
      bytes: u8,
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exported ${sheets.length} sheet(s) to ${baseName}_$ts.xlsx',
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
  }
}
