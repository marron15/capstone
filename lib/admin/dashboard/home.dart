import 'package:flutter/material.dart';
import '../sidenav.dart';
import '../excel/excel_stats_export.dart';
import '../services/api_service.dart';
import '../services/admin_service.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  static const double _drawerWidth = 280;
  // Drawer state no longer needed (side nav is fixed)
  bool _isLoading = true;
  String? _errorMessage;

  // Overall counts
  int productsActive = 0;
  int productsArchived = 0;
  int adminsActive = 0;
  int adminsArchived = 0;
  int customersActive = 0;
  int customersArchived = 0;
  int customersExpired = 0;
  int trainersActive = 0;
  int trainersArchived = 0;
  Map<String, int> membershipTotals = const {};

  @override
  void initState() {
    super.initState();
    _loadOverallReport();
  }

  Future<void> _loadOverallReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch in parallel
      final futures = await Future.wait([
        ApiService.getProductsByStatus('active'),
        ApiService.getProductsByStatus('inactive'),
        AdminService.getAllAdmins(),
        ApiService.getCustomersByStatusWithPasswords(status: 'active'),
        ApiService.getCustomersByStatus(status: 'inactive'),
        ApiService.getAllTrainers(),
        ApiService.getMembershipTotals(),
      ]);

      final List<Map<String, dynamic>> prodActive =
          List<Map<String, dynamic>>.from(futures[0] as List);
      final List<Map<String, dynamic>> prodInactive =
          List<Map<String, dynamic>>.from(futures[1] as List);

      final List<Map<String, dynamic>> admins = List<Map<String, dynamic>>.from(
        futures[2] as List,
      );

      final Map<String, dynamic> customersActiveRes =
          futures[3] as Map<String, dynamic>;
      final Map<String, dynamic> customersInactiveRes =
          futures[4] as Map<String, dynamic>;

      final List<Map<String, String>> trainers = List<Map<String, String>>.from(
        futures[5] as List,
      );

      final Map<String, int> memTotals = Map<String, int>.from(
        futures[6] as Map<String, int>,
      );

      // Compute counts
      productsActive = prodActive.length;
      productsArchived = prodInactive.length;

      // Admins: treat status === 'inactive' as archived if present
      adminsActive =
          admins.where((a) {
            final String s = (a['status'] ?? '').toString().toLowerCase();
            return s != 'inactive';
          }).length;
      adminsArchived = admins.length - adminsActive;

      final List<dynamic> activeCust =
          (customersActiveRes['data'] as List<dynamic>? ?? const []);
      final List<dynamic> archivedCust =
          (customersInactiveRes['data'] as List<dynamic>? ?? const []);
      customersActive = activeCust.length;
      customersArchived = archivedCust.length;

      // Expired among active customers (based on expiration_date)
      final DateTime now = DateTime.now();
      final DateTime todayOnly = DateTime(now.year, now.month, now.day);
      int expired = 0;
      for (final dynamic c in activeCust) {
        if (c is! Map<String, dynamic>) continue;
        final String? expRaw = c['expiration_date']?.toString();
        if (expRaw == null || expRaw.isEmpty) continue;
        final DateTime? exp = DateTime.tryParse(expRaw);
        if (exp != null && exp.isBefore(todayOnly)) expired++;
      }
      customersExpired = expired;

      // Trainers status-based counts
      trainersActive =
          trainers
              .where((t) => (t['status'] ?? '').toLowerCase() != 'inactive')
              .length;
      trainersArchived = trainers.length - trainersActive;

      membershipTotals = memTotals;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load report: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportOverallReport(BuildContext context) async {
    final rows = <List<dynamic>>[
      ['Section', 'Metric', 'Value'],
      ['Products', 'Active', productsActive],
      ['Products', 'Archived', productsArchived],
      ['Admins', 'Active', adminsActive],
      ['Admins', 'Archived', adminsArchived],
      ['Customers', 'Active', customersActive],
      ['Customers', 'Archived', customersArchived],
      ['Customers', 'Expired (of Active)', customersExpired],
      ['Trainers', 'Active', trainersActive],
      ['Trainers', 'Archived', trainersArchived],
      ['Memberships', 'Daily', membershipTotals['Daily'] ?? 0],
      ['Memberships', 'Half Month', membershipTotals['Half Month'] ?? 0],
      ['Memberships', 'Monthly', membershipTotals['Monthly'] ?? 0],
    ];

    await exportStatsToExcel(
      context,
      sheetName: 'Overall Report',
      rows: rows,
      withBarChart: false,
      chartTitle: 'Overall Report',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed, always-visible side navigation
            SizedBox(
              width: _drawerWidth,
              child: const SideNav(width: _drawerWidth),
            ),
            // Main content
            Expanded(
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
                          onPressed: () => _exportOverallReport(context),
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
                    if (_isLoading)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_errorMessage != null)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadOverallReport,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount;
                            if (constraints.maxWidth < 800) {
                              crossAxisCount = 1;
                            } else {
                              crossAxisCount = 2;
                            }

                            const double spacing = 24;
                            final double itemWidth =
                                (constraints.maxWidth -
                                    spacing * (crossAxisCount - 1)) /
                                crossAxisCount;
                            final double targetHeight =
                                constraints.maxWidth < 800 ? 220 : 200;
                            final double aspectRatio = itemWidth / targetHeight;

                            return GridView.count(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: spacing,
                              mainAxisSpacing: spacing,
                              childAspectRatio: aspectRatio,
                              children: [
                                _KpiCard(
                                  title: 'Products',
                                  rows: [
                                    _KpiRow(
                                      'Active',
                                      productsActive,
                                      Colors.green,
                                    ),
                                    _KpiRow(
                                      'Archived',
                                      productsArchived,
                                      Colors.orange,
                                    ),
                                  ],
                                ),
                                _KpiCard(
                                  title: 'Admins',
                                  rows: [
                                    _KpiRow(
                                      'Active',
                                      adminsActive,
                                      Colors.green,
                                    ),
                                    _KpiRow(
                                      'Archived',
                                      adminsArchived,
                                      Colors.orange,
                                    ),
                                  ],
                                ),
                                _KpiCard(
                                  title: 'Customers',
                                  rows: [
                                    _KpiRow(
                                      'Active',
                                      customersActive,
                                      Colors.green,
                                    ),
                                    _KpiRow(
                                      'Expired (Active)',
                                      customersExpired,
                                      Colors.red,
                                    ),
                                    _KpiRow(
                                      'Archived',
                                      customersArchived,
                                      Colors.orange,
                                    ),
                                  ],
                                ),
                                _KpiCard(
                                  title: 'Trainers',
                                  rows: [
                                    _KpiRow(
                                      'Active',
                                      trainersActive,
                                      Colors.green,
                                    ),
                                    _KpiRow(
                                      'Archived',
                                      trainersArchived,
                                      Colors.orange,
                                    ),
                                  ],
                                ),
                                _KpiCard(
                                  title: 'Membership Totals',
                                  rows: [
                                    _KpiRow(
                                      'Daily',
                                      membershipTotals['Daily'] ?? 0,
                                      Colors.orange,
                                    ),
                                    _KpiRow(
                                      'Half Month',
                                      membershipTotals['Half Month'] ?? 0,
                                      Colors.blue,
                                    ),
                                    _KpiRow(
                                      'Monthly',
                                      membershipTotals['Monthly'] ?? 0,
                                      Colors.green,
                                    ),
                                  ],
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
          ],
        ),
      ),
    );
  }
}

class _KpiRow {
  final String label;
  final int value;
  final Color color;
  const _KpiRow(this.label, this.value, this.color);
}

class _KpiCard extends StatelessWidget {
  final String title;
  final List<_KpiRow> rows;
  const _KpiCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: r.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.label,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      r.value.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
