import 'package:flutter/material.dart';
import '../statistics/new_week_members.dart';
import '../statistics/total_memberships.dart';
import '../statistics/new_members_month.dart';
import '../statistics/trainers_total.dart';
import '../sidenav.dart';

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
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
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
