import 'package:flutter/material.dart';
import 'dashboard/admin_profile.dart';
import 'dashboard/home.dart';

class SideNav extends StatelessWidget {
  const SideNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Admin Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatisticPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Admin Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminProfilePage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('Trainers'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Trainers
            },
          ),
          ListTile(
            leading: const Icon(Icons.card_membership),
            title: const Text('Memberships'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Memberships
            },
          ),
        ],
      ),
    );
  }
}
