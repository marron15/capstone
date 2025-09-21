import 'package:flutter/material.dart';
import '../services/unified_auth_state.dart';

class SideNav extends StatelessWidget {
  const SideNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Center(
                    child: Text(
                      'Admin Dashboard',
                      style: TextStyle(color: Colors.black, fontSize: 24),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin-statistics');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Admin Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin-dashboard');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: const Text('Trainers'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin-trainers');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Customers'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin-customers');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('Products'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin-products');
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    onPressed: () async {
                      await unifiedAuthState.logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/admin-login',
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
