import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_saver/file_saver.dart';

Future<void> exportStatsToPDF(
  BuildContext context, {
  required String title,
  required List<List<dynamic>> rows,
  List<List<dynamic>>? customerTableRows,
  List<List<dynamic>>? reservationTableRows,
  Map<String, int>? todayMemberships,
  Map<String, int>? weeklyMemberships,
  Map<String, int>? monthlyMemberships,
  Map<String, int>? membershipTotals,
  int? expiredMemberships,
}) async {
  try {
    if (rows.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final pdf = pw.Document();

    // Split rows into main stats and memberships/reservations
    final List<List<dynamic>> mainStatsRows = [
      rows[0], // Header row
    ];
    final List<List<dynamic>> membershipsReservationsRows = [
      rows[0], // Header row
    ];

    for (final row in rows.skip(1)) {
      final section = row[0].toString();
      if (section == 'Memberships' || section == 'Reservations') {
        membershipsReservationsRows.add(row);
      } else {
        mainStatsRows.add(row);
      }
    }

    // Page 1: Main stats (excluding Memberships and Reservations)
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.only(bottom: 16),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Generated on: ${DateTime.now().toString().split(' ')[0]}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Main stats table (excluding Memberships and Reservations)
            _buildDataTable(mainStatsRows),
          ];
        },
      ),
    );

    // Page 2: Memberships and Reservations together
    if (membershipsReservationsRows.length > 1) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(bottom: 16),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Generated on: ${DateTime.now().toString().split(' ')[0]}',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Memberships and Reservations table
              _buildDataTable(membershipsReservationsRows),
            ];
          },
        ),
      );
    }

    // Optional: Page 2 containing Customer Table if provided
    if (customerTableRows != null && customerTableRows.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(bottom: 16),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Customers',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Generated on: ${DateTime.now().toString().split(' ')[0]}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              _buildCustomerTable(customerTableRows),
            ];
          },
        ),
      );
    }

    if (reservationTableRows != null && reservationTableRows.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(bottom: 16),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Product Reservations',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Generated on: ${DateTime.now().toString().split(' ')[0]}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              _buildReservationTable(reservationTableRows),
            ];
          },
        ),
      );
    }

    // Today Memberships Chart (for Daily)
    if (todayMemberships != null) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(bottom: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'New Memberships Today',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Generated on: ${DateTime.now().toString().split(' ')[0]}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              _buildTodayMembershipsChart(todayMemberships),
            ];
          },
        ),
      );
    }

    // Page 2: Weekly Memberships Chart
    if (weeklyMemberships != null) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(bottom: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'New Memberships this Week',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Generated on: ${DateTime.now().toString().split(' ')[0]}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Weekly Memberships Chart
              _buildWeeklyMembershipsChart(weeklyMemberships),
            ];
          },
        ),
      );
    }

    // Page 3: Monthly Memberships Chart
    if (monthlyMemberships != null) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(bottom: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'New Memberships this Month',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Generated on: ${DateTime.now().toString().split(' ')[0]}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Monthly Memberships Chart
              _buildMonthlyMembershipsChart(monthlyMemberships),
            ];
          },
        ),
      );
    }

    // Page 4: Membership Totals Chart
    if (membershipTotals != null && expiredMemberships != null) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(bottom: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Membership Totals',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Generated on: ${DateTime.now().toString().split(' ')[0]}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Membership Totals Chart
              _buildMembershipTotalsChart(membershipTotals, expiredMemberships),
            ];
          },
        ),
      );
    }

    // Save the PDF
    final Uint8List pdfBytes = await pdf.save();

    final DateTime now = DateTime.now();
    final String timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    await FileSaver.instance.saveFile(
      name: '${title.replaceAll(' ', '_')}_$timestamp',
      bytes: pdfBytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exported ${rows.length - 1} rows to ${title.replaceAll(' ', '_')}_$timestamp.pdf',
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
  }
}

pw.Widget _buildCustomerTable(List<List<dynamic>> rows) {
  // Expect rows[0] as headers, remaining as data
  final headers = rows.first.map((c) => c.toString()).toList();
  final dataRows = rows.skip(1).toList();

  return pw.Container(
    width: double.infinity,
    child: pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.6), // Customer ID
        1: pw.FlexColumnWidth(2.4), // Name
        2: pw.FlexColumnWidth(2.2), // Contact
        3: pw.FlexColumnWidth(1.8), // Membership
        4: pw.FlexColumnWidth(2.0), // Start
        5: pw.FlexColumnWidth(2.0), // Expiration
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children:
              headers
                  .map(
                    (h) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: pw.Text(
                        h,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                          color: PdfColors.blue800,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  )
                  .toList(),
        ),
        ...dataRows.map((row) {
          final membership = row[3].toString();
          final isExpired = row.length > 6 && row[6] == true;
          return pw.TableRow(
            decoration:
                isExpired
                    ? const pw.BoxDecoration(color: PdfColors.red50)
                    : const pw.BoxDecoration(),
            children: [
              for (int i = 0; i < 6; i++)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: pw.Text(
                    row[i].toString(),
                    style: pw.TextStyle(
                      fontSize: 10,
                      color:
                          i == 3
                              ? _getStatusColor(membership)
                              : (i == 5 && isExpired
                                  ? PdfColors.red
                                  : PdfColors.black),
                      fontWeight:
                          i == 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
            ],
          );
        }),
      ],
    ),
  );
}

pw.Widget _buildReservationTable(List<List<dynamic>> rows) {
  final headers = rows.first.map((c) => c.toString()).toList();
  final dataRows = rows.skip(1).toList();

  return pw.Container(
    width: double.infinity,
    child: pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(2.2),
        2: pw.FlexColumnWidth(2.4),
        3: pw.FlexColumnWidth(1.2),
        4: pw.FlexColumnWidth(2.2),
        5: pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children:
              headers
                  .map(
                    (h) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: pw.Text(
                        h,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                          color: PdfColors.blue800,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  )
                  .toList(),
        ),
        ...dataRows.map((row) {
          final String status = row[5].toString().toLowerCase();
          return pw.TableRow(
            children: List.generate(6, (index) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: pw.Text(
                  row[index].toString(),
                  style: pw.TextStyle(
                    fontSize: 10,
                    color:
                        index == 5 ? _getStatusColor(status) : PdfColors.black,
                    fontWeight:
                        index == 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }),
          );
        }),
      ],
    ),
  );
}

pw.Widget _buildDataTable(List<List<dynamic>> rows) {
  const double headerPadV = 8;
  const double rowPadV = 5;

  // Group rows by section for better organization
  final Map<String, List<List<dynamic>>> groupedRows = {};
  final List<List<dynamic>> dataRows = rows.skip(1).toList();

  for (final row in dataRows) {
    final section = row[0].toString();
    if (!groupedRows.containsKey(section)) {
      groupedRows[section] = [];
    }
    groupedRows[section]!.add(row);
  }

  return pw.Container(
    width: double.infinity,
    child: pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(2.2),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: headerPadV,
              ),
              child: pw.Text(
                'Category',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: PdfColors.blue800,
                ),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: headerPadV,
              ),
              child: pw.Text(
                'Status/Type',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: PdfColors.blue800,
                ),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: headerPadV,
              ),
              child: pw.Text(
                'Count',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: PdfColors.blue800,
                ),
              ),
            ),
          ],
        ),
        // Grouped data rows with section headers
        ...groupedRows.entries.expand((entry) {
          final section = entry.key;
          final sectionRows = entry.value;

          return [
            // Section header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: rowPadV,
                  ),
                  child: pw.Text(
                    section,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.blue700,
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: rowPadV,
                  ),
                  child: pw.Text(''),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: rowPadV,
                  ),
                  child: pw.Text(''),
                ),
              ],
            ),
            // Individual metric rows
            ...sectionRows.map(
              (row) => pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.fromLTRB(
                      16,
                      rowPadV,
                      8,
                      rowPadV,
                    ),
                    child: pw.Text(
                      '', // Empty for indentation
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: rowPadV,
                    ),
                    child: pw.Text(
                      row[1].toString(),
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: _getStatusColor(row[1].toString()),
                      ),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: rowPadV,
                    ),
                    child: pw.Text(
                      row[2].toString(),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Total row at the bottom of each section
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey50),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(
                    16,
                    rowPadV,
                    8,
                    rowPadV,
                  ),
                  child: pw.Text(
                    '', // Empty for indentation
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: rowPadV,
                  ),
                  child: pw.Text(''),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: rowPadV,
                  ),
                  child: pw.Text(
                    'Total ${sectionRows.fold<int>(0, (sum, row) => sum + (row[2] as int))}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
            ),
          ];
        }),
      ],
    ),
  );
}

PdfColor _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return PdfColors.green;
    case 'archived':
      return PdfColors.orange;
    case 'expired':
      return PdfColors.red;
    case 'daily':
      return PdfColors.orange;
    case 'half month':
      return PdfColors.blue;
    case 'monthly':
      return PdfColors.green;
    default:
      return PdfColors.black;
  }
}

pw.Widget _buildWeeklyMembershipsChart(Map<String, int> weeklyData) {
  final days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  // Calculate dynamic max value for scaling based on total new memberships
  final int totalForWeek = weeklyData.values.fold(0, (sum, v) => sum + v);
  int _roundUpToNearestTen(int v) {
    if (v <= 0) return 10;
    final int rem = v % 10;
    return rem == 0 ? v : v + (10 - rem);
  }

  final int maxValue = _roundUpToNearestTen(totalForWeek);

  // Format week range like in home.dart
  String _formatWeekRange(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final int weekday = date.weekday; // 1=Mon .. 7=Sun
    final DateTime start = date.subtract(Duration(days: weekday - 1));
    final DateTime end = start.add(const Duration(days: 6));
    String fmt(DateTime d) => '${months[d.month - 1]} ${d.day}';
    return '${fmt(start)} - ${fmt(end)}';
  }

  final String subtitle = _formatWeekRange(DateTime.now());
  final List<int> valuesInOrder = days.map((d) => weeklyData[d] ?? 0).toList();
  const double _yAxisWidth = 30; // Keep in sync with Y-axis container width
  const double _yAxisGap =
      8; // Keep in sync with SizedBox between axis and chart
  const double _chartHeight = 260; // Match container height for exact scaling

  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(16),
    margin: const pw.EdgeInsets.only(bottom: 20),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'New Memberships this Week',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          subtitle,
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 16),

        // Chart with Y-axis and grid lines
        pw.Container(
          height: _chartHeight,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Y-axis labels
              pw.Container(
                width: _yAxisWidth,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: List.generate(6, (index) {
                    final double step = maxValue / 5;
                    final int value = ((5 - index) * step).round();
                    return pw.Text(
                      value.toString(),
                      style: const pw.TextStyle(fontSize: 10),
                    );
                  }),
                ),
              ),
              pw.SizedBox(width: _yAxisGap),

              // Chart area
              pw.Expanded(
                child: pw.Stack(
                  children: [
                    // Grid lines precisely aligned to 0..maxValue (5 intervals)
                    ...List.generate(6, (i) {
                      final double bottom = i * (_chartHeight / 5);
                      return pw.Positioned(
                        left: 0,
                        right: 0,
                        bottom: bottom,
                        child: pw.Container(
                          height: 1,
                          color: PdfColors.grey300,
                        ),
                      );
                    }),

                    // Bars
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children:
                          days.asMap().entries.map((entry) {
                            final String day = entry.value;
                            final int value = weeklyData[day] ?? 0;
                            final double scaled =
                                (value / maxValue) * _chartHeight;
                            // Scale purely by value so 3 looks between 2 and 4
                            final double height = value > 0 ? scaled : 0;

                            return pw.Container(
                              width: 30,
                              height: height,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue400,
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Day labels and values below the 0 baseline
        pw.SizedBox(height: 8),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: _yAxisWidth + _yAxisGap),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: List.generate(days.length, (i) {
              return pw.SizedBox(
                width: 30,
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      dayLabels[i],
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      valuesInOrder[i].toString(),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildMonthlyMembershipsChart(Map<String, int> monthlyData) {
  // Create week labels with date ranges
  final DateTime now = DateTime.now();
  final int year = now.year;
  final int month = now.month;
  final int daysInMonth = DateTime(year, month + 1, 0).day;

  String rng(int s, int e) => '$s-${e > daysInMonth ? daysInMonth : e}';
  final String w1 = rng(1, 7);
  final String w2 = rng(8, 14);
  final String w3 = rng(15, 21);
  final String w4 = rng(22, daysInMonth);

  final weeks = [
    {'label': 'Week 1', 'range': w1, 'key': '1'},
    {'label': 'Week 2', 'range': w2, 'key': '2'},
    {'label': 'Week 3', 'range': w3, 'key': '3'},
    {'label': 'Week 4', 'range': w4, 'key': '4'},
  ];

  // Calculate dynamic max value for scaling based on this month's total
  final int totalForMonth = monthlyData.values.fold(0, (sum, v) => sum + v);
  int _roundUpToNearestTen(int v) {
    if (v <= 0) return 10;
    final int rem = v % 10;
    return rem == 0 ? v : v + (10 - rem);
  }

  final int maxValue = _roundUpToNearestTen(totalForMonth);

  // Format month name like in home.dart
  String monthLabel(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[d.month - 1];
  }

  final String subtitle = monthLabel(now);

  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(16),
    margin: const pw.EdgeInsets.only(bottom: 20),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'New Memberships this Month',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          subtitle,
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 16),

        // Chart with Y-axis and grid lines
        pw.Container(
          height: 260,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Y-axis labels
              pw.Container(
                width: 30,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: List.generate(6, (index) {
                    final double step = maxValue / 5;
                    final int value = ((5 - index) * step).round();
                    return pw.Text(
                      value.toString(),
                      style: const pw.TextStyle(fontSize: 10),
                    );
                  }),
                ),
              ),
              pw.SizedBox(width: 8),

              // Chart area
              pw.Expanded(
                child: pw.Stack(
                  children: [
                    // Grid lines precisely aligned to 0..maxValue (5 intervals)
                    ...List.generate(6, (i) {
                      final double bottom = i * (240 / 5);
                      return pw.Positioned(
                        left: 0,
                        right: 0,
                        bottom: bottom,
                        child: pw.Container(
                          height: 1,
                          color: PdfColors.grey300,
                        ),
                      );
                    }),

                    // Bars
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children:
                          weeks.map((week) {
                            final value = monthlyData[week['key']] ?? 0;
                            final height = (value / maxValue) * 240;

                            return pw.Container(
                              width: 40,
                              height: height,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.purple400,
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Week labels and values below the 0 baseline
        pw.SizedBox(height: 8),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 30 + 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children:
                weeks.map((week) {
                  final value = monthlyData[week['key']] ?? 0;
                  return pw.SizedBox(
                    width: 40,
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(
                          week['label']!,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          week['range']!,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          value.toString(),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildTodayMembershipsChart(Map<String, int> todayData) {
  final categories = [
    {
      'name': 'Daily',
      'value': todayData['Daily'] ?? 0,
      'color': PdfColors.orange,
    },
    {
      'name': 'Half Month',
      'value': todayData['Half Month'] ?? 0,
      'color': PdfColors.blue,
    },
    {
      'name': 'Monthly',
      'value': todayData['Monthly'] ?? 0,
      'color': PdfColors.green,
    },
    {
      'name': 'Expired',
      'value': todayData['Expired'] ?? 0,
      'color': PdfColors.red,
    },
  ];

  final int total = categories.fold<int>(0, (s, c) => s + (c['value'] as int));

  int _roundUpToNearestTwenty(int v) {
    if (v <= 0) return 10;
    final int rem = v % 20;
    return rem == 0 ? v : v + (20 - rem);
  }

  final int maxValue = _roundUpToNearestTwenty(total);

  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(16),
    margin: const pw.EdgeInsets.only(bottom: 20),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'New Memberships Today',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Container(
          height: 260,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                width: 30,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: List.generate(6, (index) {
                    final double step = maxValue / 5;
                    final int value = ((5 - index) * step).round();
                    return pw.Text(
                      value.toString(),
                      style: const pw.TextStyle(fontSize: 10),
                    );
                  }),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Stack(
                  children: [
                    ...List.generate(6, (i) {
                      final double bottom = i * (240 / 5);
                      return pw.Positioned(
                        left: 0,
                        right: 0,
                        bottom: bottom,
                        child: pw.Container(
                          height: 1,
                          color: PdfColors.grey300,
                        ),
                      );
                    }),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children:
                          categories.map((c) {
                            final int v = c['value'] as int;
                            final double h = (v / maxValue) * 240;
                            return pw.Container(
                              width: 40,
                              height: h,
                              decoration: pw.BoxDecoration(
                                color: c['color'] as PdfColor,
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 38),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children:
                categories.map((c) {
                  return pw.SizedBox(
                    width: 40,
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(
                          c['name'] as String,
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          (c['value'] as int).toString(),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildMembershipTotalsChart(
  Map<String, int> membershipData,
  int expired,
) {
  final categories = [
    {
      'name': 'Daily',
      'value': membershipData['Daily'] ?? 0,
      'color': PdfColors.orange,
    },
    {
      'name': 'Half Month',
      'value': membershipData['Half Month'] ?? 0,
      'color': PdfColors.blue,
    },
    {
      'name': 'Monthly',
      'value': membershipData['Monthly'] ?? 0,
      'color': PdfColors.green,
    },
    {'name': 'Expired', 'value': expired, 'color': PdfColors.red},
  ];

  final total = categories.fold<int>(
    0,
    (sum, cat) => sum + (cat['value'] as int),
  );

  // Calculate dynamic max value for scaling based on total memberships
  int _roundUpToNearestTen(int v) {
    if (v <= 0) return 10;
    final int rem = v % 10;
    return rem == 0 ? v : v + (10 - rem);
  }

  final int maxValue = _roundUpToNearestTen(total);

  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(16),
    margin: const pw.EdgeInsets.only(bottom: 20),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Membership Totals',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 16),

        // Chart with Y-axis and grid lines
        pw.Container(
          height: 260,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Y-axis labels (0..maxValue, 10 intervals)
              pw.Container(
                width: 30,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: List.generate(11, (index) {
                    final double step = maxValue / 10;
                    final int value = ((10 - index) * step).round();
                    return pw.Text(
                      value.toString(),
                      style: const pw.TextStyle(fontSize: 10),
                    );
                  }),
                ),
              ),
              pw.SizedBox(width: 8),

              // Chart area
              pw.Expanded(
                child: pw.Stack(
                  children: [
                    // Grid lines precisely aligned to 0..maxValue (10 intervals)
                    ...List.generate(11, (i) {
                      final double bottom = i * (240 / 10);
                      return pw.Positioned(
                        left: 0,
                        right: 0,
                        bottom: bottom,
                        child: pw.Container(
                          height: 1,
                          color: PdfColors.grey300,
                        ),
                      );
                    }),

                    // Bars
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children:
                          categories.map((category) {
                            final value = category['value'] as int;
                            final height =
                                (value / maxValue) * 240; // 240px max height

                            return pw.Container(
                              width: 40,
                              height: height,
                              decoration: pw.BoxDecoration(
                                color: category['color'] as PdfColor,
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Category labels and values below the 0 baseline
        pw.SizedBox(height: 8),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 30 + 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children:
                categories.map((category) {
                  final String name = category['name'] as String;
                  final int value = category['value'] as int;
                  return pw.SizedBox(
                    width: 40,
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(
                          name,
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          value.toString(),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
        pw.SizedBox(height: 60),
        pw.Center(
          child: pw.Text(
            'Total memberships: $total',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Export multiple reports into a single PDF document
Future<void> exportMultipleReportsToPDF(
  BuildContext context, {
  required List<({String title, List<List<dynamic>> rows})> reports,
  String? fileName,
  bool withCharts = true,
}) async {
  try {
    if (reports.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final pdf = pw.Document();

    for (int i = 0; i < reports.length; i++) {
      final report = reports[i];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(bottom: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      report.title,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Page ${i + 1} of ${reports.length} • Generated on: ${DateTime.now().toString().split(' ')[0]}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Data table
              _buildDataTable(report.rows),

              pw.SizedBox(height: 30),

              // Chart section removed for better page fitting
            ];
          },
        ),
      );
    }

    // Save the PDF
    final Uint8List pdfBytes = await pdf.save();

    final DateTime now = DateTime.now();
    final String timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    final String baseName = fileName ?? 'Statistics_Export';

    await FileSaver.instance.saveFile(
      name: '${baseName}_$timestamp',
      bytes: pdfBytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exported ${reports.length} report(s) to ${baseName}_$timestamp.pdf',
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
  }
}
