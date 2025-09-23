import 'package:flutter/material.dart';
import '../statistics/new_week_members.dart';
import '../statistics/total_memberships.dart';
import '../statistics/new_members_month.dart';
import '../statistics/trainers_total.dart';
import '../sidenav.dart';
import '../excel/excel_stats_export.dart';
import '../services/api_service.dart';

class StatisticPage extends StatelessWidget {
  const StatisticPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      drawer: const SideNav(),
      appBar: AppBar(
        title: const Center(child: Text('Dashboard')),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Statistics',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showExportDialog(context),
                    icon: Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.teal.shade700,
                      size: 20,
                    ),
                    label: const Text('Export'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive breakpoints for columns (2x2 layout on desktop)
                    int crossAxisCount;
                    if (constraints.maxWidth < 600) {
                      crossAxisCount = 1;
                    } else {
                      crossAxisCount = 2;
                    }

                    const double spacing = 24;
                    final double itemWidth =
                        (constraints.maxWidth -
                            spacing * (crossAxisCount - 1)) /
                        crossAxisCount;
                    // Target a comfortable card height across sizes
                    final double targetHeight =
                        constraints.maxWidth < 600
                            ? 340
                            : constraints.maxWidth < 900
                            ? 300
                            : 280;
                    final double aspectRatio = itemWidth / targetHeight;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: aspectRatio,
                      children: const [
                        // Top-left
                        _StatCard(
                          title: 'New Members this Week',
                          subtitle: '',
                          child: NewMembersBarGraph(),
                        ),
                        // Top-right
                        _StatCard(
                          title: 'New Members this Month',
                          subtitle: '',
                          child: NewMembersMonthBarGraph(),
                        ),
                        // Bottom-left
                        _StatCard(
                          title: 'Memberships Total',
                          subtitle: '',
                          child: MembershipsTotalBarGraph(),
                        ),
                        // Bottom-right
                        _StatCard(
                          title: 'Trainers Total',
                          subtitle: '',
                          child: TrainersTotalPieChart(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showExportDialog(BuildContext context) async {
  // Multi-select dialog with checkboxes
  final Set<String> selected = <String>{};
  final result = await showDialog<Set<String>>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Widget buildTile(String key, String label) => CheckboxListTile(
            value: selected.contains(key),
            onChanged: (bool? v) {
              setState(() {
                if (v == true) {
                  selected.add(key);
                } else {
                  selected.remove(key);
                }
              });
            },
            title: Text(label),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          );

          return AlertDialog(
            title: const Text('Export Statistics'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildTile('week', 'New Members this Week'),
                  buildTile('month', 'New Members this Month'),
                  buildTile('memberships', 'Memberships Total'),
                  buildTile('trainers', 'Trainers Total'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed:
                    selected.isEmpty
                        ? null
                        : () =>
                            Navigator.pop(context, Set<String>.from(selected)),
                child: const Text('Export'),
              ),
            ],
          );
        },
      );
    },
  );

  if (result == null || result.isEmpty) return;

  // If only one selection, preserve previous single-sheet export behavior
  if (result.length == 1) {
    final String choice = result.first;
    if (choice == 'week') {
      final Map<String, int> map = await ApiService.getNewMembersThisWeek();
      final rows = <List<dynamic>>[
        ['Day', 'Count'],
        ['Monday', map['Monday'] ?? 0],
        ['Tuesday', map['Tuesday'] ?? 0],
        ['Wednesday', map['Wednesday'] ?? 0],
        ['Thursday', map['Thursday'] ?? 0],
        ['Friday', map['Friday'] ?? 0],
        ['Saturday', map['Saturday'] ?? 0],
        ['Sunday', map['Sunday'] ?? 0],
      ];
      await exportStatsToExcel(
        context,
        sheetName: 'New Members Week',
        rows: rows,
        withBarChart: true,
        chartTitle: 'New Members this Week',
      );
    } else if (choice == 'month') {
      final Map<String, int> map = await ApiService.getNewMembersThisMonth();
      final rows = <List<dynamic>>[
        ['Week', 'Count'],
        ['Week 1', map['1'] ?? map['Week 1'] ?? 0],
        ['Week 2', map['2'] ?? map['Week 2'] ?? 0],
        ['Week 3', map['3'] ?? map['Week 3'] ?? 0],
        ['Week 4', map['4'] ?? map['Week 4'] ?? 0],
      ];
      await exportStatsToExcel(
        context,
        sheetName: 'New Members Month',
        rows: rows,
        withBarChart: true,
        chartTitle: 'New Members this Month',
      );
    } else if (choice == 'memberships') {
      final Map<String, int> map = await ApiService.getMembershipTotals();
      final rows = <List<dynamic>>[
        ['Type', 'Count'],
        ['Daily', map['Daily'] ?? 0],
        ['Half Month', map['Half Month'] ?? 0],
        ['Monthly', map['Monthly'] ?? 0],
      ];
      await exportStatsToExcel(
        context,
        sheetName: 'Memberships Total',
        rows: rows,
        withBarChart: true,
        chartTitle: 'Memberships Total',
      );
    } else if (choice == 'trainers') {
      final int total = await ApiService.getTrainersTotal(activeOnly: true);
      final rows = <List<dynamic>>[
        ['Label', 'Count'],
        ['Total', total],
      ];
      await exportStatsToExcel(
        context,
        sheetName: 'Trainers Total',
        rows: rows,
        withBarChart: true,
        chartTitle: 'Trainers Total',
      );
    }
    return;
  }

  // Multi-sheet export path
  final List<({String sheetName, List<List<dynamic>> rows})> sheets = [];

  if (result.contains('week')) {
    final Map<String, int> map = await ApiService.getNewMembersThisWeek();
    sheets.add((
      sheetName: 'New Members Week',
      rows: [
        ['Day', 'Count'],
        ['Monday', map['Monday'] ?? 0],
        ['Tuesday', map['Tuesday'] ?? 0],
        ['Wednesday', map['Wednesday'] ?? 0],
        ['Thursday', map['Thursday'] ?? 0],
        ['Friday', map['Friday'] ?? 0],
        ['Saturday', map['Saturday'] ?? 0],
        ['Sunday', map['Sunday'] ?? 0],
      ],
    ));
  }

  if (result.contains('month')) {
    final Map<String, int> map = await ApiService.getNewMembersThisMonth();
    sheets.add((
      sheetName: 'New Members Month',
      rows: [
        ['Week', 'Count'],
        ['Week 1', map['1'] ?? map['Week 1'] ?? 0],
        ['Week 2', map['2'] ?? map['Week 2'] ?? 0],
        ['Week 3', map['3'] ?? map['Week 3'] ?? 0],
        ['Week 4', map['4'] ?? map['Week 4'] ?? 0],
      ],
    ));
  }

  if (result.contains('memberships')) {
    final Map<String, int> map = await ApiService.getMembershipTotals();
    sheets.add((
      sheetName: 'Memberships Total',
      rows: [
        ['Type', 'Count'],
        ['Daily', map['Daily'] ?? 0],
        ['Half Month', map['Half Month'] ?? 0],
        ['Monthly', map['Monthly'] ?? 0],
      ],
    ));
  }

  if (result.contains('trainers')) {
    final int total = await ApiService.getTrainersTotal(activeOnly: true);
    sheets.add((
      sheetName: 'Trainers Total',
      rows: [
        ['Label', 'Count'],
        ['Total', total],
      ],
    ));
  }

  if (sheets.isEmpty) return;
  await exportMultipleSheetsToExcel(
    context,
    sheets: sheets,
    fileName: 'Statistics',
    withBarCharts: true,
  );
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _StatCard({
    required this.title,
    required this.child,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  subtitle,
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(child: Center(child: child)),
          ],
        ),
      ),
    );
  }
}
