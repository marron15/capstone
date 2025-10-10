import 'package:flutter/material.dart';
import '../sidenav.dart';
import '../excel/excel_stats_export.dart';
import '../services/api_service.dart';
import '../services/admin_service.dart';
import '../statistics/new_week_members.dart';
import '../statistics/new_members_month.dart';
import '../statistics/total_memberships.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  static const double _drawerWidth = 280;
  bool _navCollapsed = false;
  // Drawer state no longer needed (side nav is fixed)
  bool _isLoading = true;
  String? _errorMessage;

  // Simple filter UI state removed per request
  final ScrollController _kpiController = ScrollController();
  String _startsView = 'Week';

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
  void dispose() {
    _kpiController.dispose();
    super.dispose();
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: _navCollapsed ? 0 : _drawerWidth,
              child: SideNav(
                width: _drawerWidth,
                onClose: () => setState(() => _navCollapsed = true),
              ),
            ),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip:
                              _navCollapsed ? 'Open Sidebar' : 'Close Sidebar',
                          onPressed:
                              () => setState(
                                () => _navCollapsed = !_navCollapsed,
                              ),
                          icon: Icon(
                            _navCollapsed ? Icons.menu : Icons.chevron_left,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Status Change Report',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _exportOverallReport(context),
                          icon: Icon(
                            Icons.file_download_outlined,
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
                    const SizedBox(height: 12),
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT MAIN COLUMN
                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.zero,
                                children: [
                                  // KPI ribbon
                                  _KpiRibbonGroups(
                                    controller: _kpiController,
                                    groups: [
                                      _KpiGroup(
                                        title: 'Admins',
                                        top: _KpiTile(
                                          label: 'Admins Active',
                                          value: adminsActive,
                                          color: const Color(0xFF2E7D32),
                                        ),
                                        bottom: _KpiTile(
                                          label: 'Admins Archived',
                                          value: adminsArchived,
                                          color: const Color(0xFFFB8C00),
                                        ),
                                      ),
                                      _KpiGroup(
                                        title: 'Trainers',
                                        top: _KpiTile(
                                          label: 'Trainers Active',
                                          value: trainersActive,
                                          color: const Color(0xFF2E7D32),
                                        ),
                                        bottom: _KpiTile(
                                          label: 'Trainers Archived',
                                          value: trainersArchived,
                                          color: const Color(0xFFFB8C00),
                                        ),
                                      ),
                                      _KpiGroup(
                                        title: 'Customers',
                                        top: _KpiTile(
                                          label: 'Customers Active',
                                          value: customersActive,
                                          color: const Color(0xFF2E7D32),
                                        ),
                                        bottom: _KpiTile(
                                          label: 'Customers Archived',
                                          value: customersArchived,
                                          color: const Color(0xFFFB8C00),
                                        ),
                                      ),
                                      _KpiGroup(
                                        title: 'Products',
                                        top: _KpiTile(
                                          label: 'Products Active',
                                          value: productsActive,
                                          color: const Color(0xFF2E7D32),
                                        ),
                                        bottom: _KpiTile(
                                          label: 'Products Archived',
                                          value: productsArchived,
                                          color: const Color(0xFFFB8C00),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Charts area
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      // Full-width first chart to occupy space
                                      return Wrap(
                                        spacing: 24,
                                        runSpacing: 24,
                                        children: [
                                          SizedBox(
                                            width: constraints.maxWidth,
                                            child: Card(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              elevation: 2,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  16.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          _startsView == 'Week'
                                                              ? 'New Memberships this Week'
                                                              : 'New Memberships this Month',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                        const Spacer(),
                                                        PopupMenuButton<String>(
                                                          tooltip: 'Filter',
                                                          onSelected:
                                                              (v) => setState(
                                                                () =>
                                                                    _startsView =
                                                                        v,
                                                              ),
                                                          itemBuilder:
                                                              (
                                                                context,
                                                              ) => const [
                                                                PopupMenuItem(
                                                                  value: 'Week',
                                                                  child: Text(
                                                                    'Week',
                                                                  ),
                                                                ),
                                                                PopupMenuItem(
                                                                  value:
                                                                      'Month',
                                                                  child: Text(
                                                                    'Month',
                                                                  ),
                                                                ),
                                                              ],
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .chevron_right,
                                                                size: 18,
                                                                color:
                                                                    Colors
                                                                        .black54,
                                                              ),
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Text(
                                                                _startsView,
                                                                style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                              const Icon(
                                                                Icons
                                                                    .arrow_drop_down,
                                                                size: 18,
                                                                color:
                                                                    Colors
                                                                        .black87,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    SizedBox(
                                                      height: 260,
                                                      child:
                                                          _startsView == 'Week'
                                                              ? const NewMembersBarGraph()
                                                              : const NewMembersMonthBarGraph(),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          // removed Memberships Report pie chart
                                          _ChartCard(
                                            title: 'Membership Totals',
                                            child: MembershipsTotalBarGraph(
                                              daily:
                                                  membershipTotals['Daily'] ??
                                                  0,
                                              halfMonth:
                                                  membershipTotals['Half Month'] ??
                                                  0,
                                              monthly:
                                                  membershipTotals['Monthly'] ??
                                                  0,
                                              expired: customersExpired,
                                            ),
                                            width: constraints.maxWidth,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
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

// Old KPI card components removed in favor of the ribbon tiles above

// Redesigned components for dashboard layout

class _KpiTile {
  final String label;
  final int value;
  final Color color;
  const _KpiTile({
    required this.label,
    required this.value,
    required this.color,
  });
}

// (legacy) _KpiRibbon removed; replaced by grouped version below

class _RibbonArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RibbonArrow({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: onTap == null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withAlpha(0), Colors.white],
              begin:
                  icon == Icons.chevron_left
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
              end:
                  icon == Icons.chevron_left
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: Colors.black54),
        ),
      ),
    );
  }
}

// Grouped KPI ribbon (two stacked tiles per entity)
class _KpiGroup {
  final String title;
  final _KpiTile top;
  final _KpiTile bottom;
  const _KpiGroup({
    required this.title,
    required this.top,
    required this.bottom,
  });
}

class _KpiRibbonGroups extends StatelessWidget {
  final List<_KpiGroup> groups;
  final ScrollController? controller;
  const _KpiRibbonGroups({required this.groups, this.controller});

  @override
  Widget build(BuildContext context) {
    Widget tile(_KpiTile t) => Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.color.withAlpha(64)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: t.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.value.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                t.label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Stack(
          children: [
            Scrollbar(
              controller: controller,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: controller,
                scrollDirection: Axis.horizontal,
                child: Builder(
                  builder: (context) {
                    final double screenW = MediaQuery.of(context).size.width;
                    final double contentW =
                        (screenW - 360).clamp(300, screenW).toDouble();
                    return ConstrainedBox(
                      constraints: BoxConstraints(minWidth: contentW),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            groups
                                .map(
                                  (g) => Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 12,
                                            bottom: 4,
                                          ),
                                          child: Text(
                                            g.title,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        tile(g.top),
                                        tile(g.bottom),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _RibbonArrow(
                icon: Icons.chevron_left,
                onTap:
                    () => controller?.animateTo(
                      (controller!.offset - 260).clamp(
                        0,
                        controller!.position.maxScrollExtent,
                      ),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _RibbonArrow(
                icon: Icons.chevron_right,
                onTap:
                    () => controller?.animateTo(
                      (controller!.offset + 260).clamp(
                        0,
                        controller!.position.maxScrollExtent,
                      ),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final double width;
  const _ChartCard({
    required this.title,
    required this.child,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(height: 260, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// Removed _MiniMetric (replaced by donut chart)
