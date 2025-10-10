import 'package:flutter/material.dart';
import '../services/unified_auth_state.dart';

class SideNav extends StatelessWidget {
  final double? width;
  final VoidCallback? onClose;
  const SideNav({super.key, this.width, this.onClose});

  @override
  Widget build(BuildContext context) {
    // Render as a fixed side panel, not a modal drawer
    final String? _currentRoute = ModalRoute.of(context)?.settings.name;

    Widget _navItem({
      required IconData icon,
      required String label,
      required String route,
    }) {
      final bool isSelected = _currentRoute == route;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade200 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border:
              isSelected
                  ? const Border(left: BorderSide(color: Colors.grey, width: 4))
                  : null,
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.black),
          title: Text(label),
          selected: isSelected,
          selectedTileColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () {
            if (_currentRoute != route) {
              Navigator.pushNamed(context, route);
            }
          },
        ),
      );
    }

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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Admin Dashboard',
                          style: TextStyle(color: Colors.black, fontSize: 24),
                        ),
                        if (onClose != null)
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close),
                            onPressed: onClose,
                          ),
                      ],
                    ),
                  ),
                  _navItem(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    route: '/admin-statistics',
                  ),
                  _navItem(
                    icon: Icons.person,
                    label: 'Admin Profile',
                    route: '/admin-dashboard',
                  ),
                  _navItem(
                    icon: Icons.fitness_center,
                    label: 'Trainers',
                    route: '/admin-trainers',
                  ),
                  _navItem(
                    icon: Icons.people,
                    label: 'Customers',
                    route: '/admin-customers',
                  ),
                  _navItem(
                    icon: Icons.inventory,
                    label: 'Products',
                    route: '/admin-products',
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
