import 'package:flutter/material.dart';
import '../services/unified_auth_state.dart';

class SideNav extends StatelessWidget {
  final double? width;
  const SideNav({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    // Render as a fixed side panel, not a modal drawer
    return SafeArea(
      child: Container(
        width: width ?? 280,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(
              color: Colors.black.withAlpha((0.08 * 255).toInt()),
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    height: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Admin Dashboard',
                      style: TextStyle(color: Colors.black, fontSize: 24),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Dashboard'),
                    onTap: () {
                      Navigator.pushNamed(context, '/admin-statistics');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Admin Profile'),
                    onTap: () {
                      Navigator.pushNamed(context, '/admin-dashboard');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: const Text('Trainers'),
                    onTap: () {
                      Navigator.pushNamed(context, '/admin-trainers');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Customers'),
                    onTap: () {
                      Navigator.pushNamed(context, '/admin-customers');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.inventory),
                    title: const Text('Products'),
                    onTap: () {
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
      ),
    );
  }
}
