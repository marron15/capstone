import 'package:flutter/material.dart';
import '../services/unified_auth_state.dart';
import '../main.dart' show navigatorKey;

class SideNav extends StatefulWidget {
  final double? width;
  final VoidCallback? onClose;
  const SideNav({super.key, this.width, this.onClose});

  @override
  State<SideNav> createState() => _SideNavState();
}

class _SideNavState extends State<SideNav> {
  bool _isNavigating = false;

  void _navigate(String? currentRoute, String route) {
    if (currentRoute == route) return;
    if (_isNavigating) return; // Prevent multiple simultaneous navigations

    _isNavigating = true;

    // Use microtask to defer navigation until after current execution
    // This prevents navigation during build or frame rendering
    Future.microtask(() {
      if (!mounted) {
        _isNavigating = false;
        return;
      }

      // Use global navigator key to avoid context disposal issues
      final navigator = navigatorKey.currentState;
      if (navigator == null || !navigator.mounted) {
        _isNavigating = false;
        return;
      }

      try {
        // Use pushNamedAndRemoveUntil to replace current route
        // This is more reliable than pushReplacementNamed for Flutter web
        navigator
            .pushNamedAndRemoveUntil(
              route,
              (route) => false, // Remove all previous routes
            )
            .then((_) {
              if (mounted) {
                _isNavigating = false;
              }
            })
            .catchError((e) {
              _isNavigating = false;
              if (mounted) {
                debugPrint('Navigation error: $e');
              }
            });
      } catch (e) {
        _isNavigating = false;
        if (mounted) {
          debugPrint('Navigation error: $e');
        }
      }
    });
  }

  Widget _navItem({
    IconData? icon,
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
        leading: icon != null ? Icon(icon, color: Colors.black) : null,
        title: Text(label),
        selected: isSelected,
        selectedTileColor: Colors.grey.shade200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => _navigate(currentRoute, route),
      ),
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
                  _navItem(
                    icon: Icons.access_time,
                    label: 'Attendance Log',
                    route: '/admin-attendance',
                    currentRoute: currentRoute,
                  ),
                  _navItem(
                    icon: Icons.inventory,
                    label: 'Product List',
                    route: '/admin-products',
                    currentRoute: currentRoute,
                  ),
                  _navItem(
                    icon: Icons.shopping_cart,
                    label: 'Reserved Products',
                    route: '/admin-reserved-products',
                    currentRoute: currentRoute,
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
