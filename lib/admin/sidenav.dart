import 'package:flutter/material.dart';
import '../services/unified_auth_state.dart';

class SideNav extends StatefulWidget {
  final double? width;
  final VoidCallback? onClose;
  const SideNav({super.key, this.width, this.onClose});

  @override
  State<SideNav> createState() => _SideNavState();
}

class _SideNavState extends State<SideNav> {
  bool _productsExpanded = false;

  void _navigate(BuildContext context, String? currentRoute, String route) {
    if (currentRoute != route) {
      Navigator.pushNamed(context, route);
    }
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required String route,
    required String? currentRoute,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    double leftBorderWidth = 4,
  }) {
    final bool isSelected = currentRoute == route;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey.shade200 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border:
            isSelected
                ? Border(
                  left: BorderSide(color: Colors.grey, width: leftBorderWidth),
                )
                : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(label),
        selected: isSelected,
        selectedTileColor: Colors.grey.shade200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => _navigate(context, currentRoute, route),
      ),
    );
  }

  Widget _productsGroup(String? currentRoute) {
    final bool isProductsRoute = currentRoute == '/admin-products';
    final bool isReservedRoute = currentRoute == '/admin-reserved-products';
    final bool isExpanded =
        _productsExpanded || isProductsRoute || isReservedRoute;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isExpanded ? Colors.grey.shade100 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border:
                isExpanded
                    ? Border(
                      left: BorderSide(color: Colors.grey.shade400, width: 4),
                    )
                    : null,
          ),
          child: ListTile(
            leading: const Icon(Icons.inventory, color: Colors.black),
            title: const Text('Products'),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.black54,
            ),
            onTap: () => setState(() => _productsExpanded = !_productsExpanded),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          firstCurve: Curves.easeOutCubic,
          secondCurve: Curves.easeInCubic,
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              _navItem(
                icon: Icons.list_alt,
                label: 'Product List',
                route: '/admin-products',
                currentRoute: currentRoute,
                margin: const EdgeInsets.only(left: 32, right: 8, bottom: 4),
                leftBorderWidth: 3,
              ),
              _navItem(
                icon: Icons.assignment_turned_in,
                label: 'Reserved Products',
                route: '/admin-reserved-products',
                currentRoute: currentRoute,
                margin: const EdgeInsets.only(left: 32, right: 8, bottom: 4),
                leftBorderWidth: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? currentRoute = ModalRoute.of(context)?.settings.name;

    return SafeArea(
      child: Container(
        width: widget.width ?? 280,
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
                        if (widget.onClose != null)
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close),
                            onPressed: widget.onClose,
                          ),
                      ],
                    ),
                  ),
                  _navItem(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    route: '/admin-statistics',
                    currentRoute: currentRoute,
                  ),
                  _navItem(
                    icon: Icons.person,
                    label: 'Admin Profile',
                    route: '/admin-dashboard',
                    currentRoute: currentRoute,
                  ),
                  _navItem(
                    icon: Icons.fitness_center,
                    label: 'Trainers',
                    route: '/admin-trainers',
                    currentRoute: currentRoute,
                  ),
                  _navItem(
                    icon: Icons.people,
                    label: 'Customers',
                    route: '/admin-customers',
                    currentRoute: currentRoute,
                  ),
                  _productsGroup(currentRoute),
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
