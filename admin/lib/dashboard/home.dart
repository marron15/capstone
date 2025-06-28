import 'package:flutter/material.dart';
import '../statistics/week_paid_members.dart';
import '../statistics/new_week_members.dart';
import '../statistics/total_memberships.dart';
import '../statistics/new_members_month.dart';
import '../statistics/trainers_total_pie.dart';
import '../sidenav.dart';

class StatisticPage extends StatelessWidget {
  const StatisticPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      drawer: const SideNav(),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth < 500 ? 1 : 4;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 1.2,
                    children: const [
                      // Week Paid Members (Pie Chart)
                      _StatCard(
                        title: 'Week Paid Members',
                        subtitle: '',
                        child: WeekPaidMembers(),
                      ),
                      // New Members this Week (Bar Graph)
                      _StatCard(
                        title: 'New Members this Week',
                        subtitle: '',
                        child: NewMembersBarGraph(),
                      ),
                      // Memberships Total (Bar Graph)
                      _StatCard(
                        title: 'Memberships Total',
                        subtitle: '',
                        child: MembershipsTotalBarGraph(),
                      ),
                      // New Members this Month (Bar Graph)
                      _StatCard(
                        title: 'New Members this Month',
                        subtitle: '',
                        child: NewMembersMonthBarGraph(),
                      ),
                      // Trainers Total (Pie Chart)
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
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _StatCard(
      {required this.title, required this.child, this.subtitle = ''});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
