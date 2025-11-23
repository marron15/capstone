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
  bool _customersExpanded = true;
  bool _productsExpanded = true;

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
    bool isNested = false,
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
        contentPadding: EdgeInsets.only(
          left: isNested ? 56 : 16,
          right: 16,
          top: 4,
          bottom: 4,
        ),
      ),
    );
  }

  Widget _buildDropdownSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onExpansionChanged,
    required List<Widget> children,
    required String? currentRoute,
    required List<String> routes,
  }) {
    final bool hasSelectedChild = routes.contains(currentRoute);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasSelectedChild ? Colors.grey.shade200 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.black),
            title: Text(title),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.black,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: onExpansionChanged,
          ),
          if (isExpanded) ...children,
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String? currentRoute = ModalRoute.of(context)?.settings.name;

    // Auto-expand dropdowns if current route is a child
    if (currentRoute == '/admin-customers' ||
        currentRoute == '/admin-attendance') {
      if (!_customersExpanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _customersExpanded = true;
            });
          }
        });
      }
    }

    if (currentRoute == '/admin-products' ||
        currentRoute == '/admin-reserved-products') {
      if (!_productsExpanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _productsExpanded = true;
            });
          }
        });
      }
    }
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
                  _buildDropdownSection(
                    title: 'Customers Management',
                    icon: Icons.people,
                    isExpanded: _customersExpanded,
                    onExpansionChanged: () {
                      setState(() {
                        _customersExpanded = !_customersExpanded;
                      });
                    },
                    currentRoute: currentRoute,
                    routes: ['/admin-customers', '/admin-attendance'],
                    children: [
                      _navItem(
                        icon: Icons.people,
                        label: 'Customers',
                        route: '/admin-customers',
                        currentRoute: currentRoute,
                        isNested: true,
                      ),
                      _navItem(
                        icon: Icons.access_time,
                        label: 'Time in/out',
                        route: '/admin-attendance',
                        currentRoute: currentRoute,
                        isNested: true,
                      ),
                    ],
                  ),
                  _buildDropdownSection(
                    title: 'Products',
                    icon: Icons.inventory,
                    isExpanded: _productsExpanded,
                    onExpansionChanged: () {
                      setState(() {
                        _productsExpanded = !_productsExpanded;
                      });
                    },
                    currentRoute: currentRoute,
                    routes: ['/admin-products', '/admin-reserved-products'],
                    children: [
                      _navItem(
                        icon: Icons.inventory,
                        label: 'Product List',
                        route: '/admin-products',
                        currentRoute: currentRoute,
                        isNested: true,
                      ),
                      _navItem(
                        icon: Icons.shopping_cart,
                        label: 'Reserved Products',
                        route: '/admin-reserved-products',
                        currentRoute: currentRoute,
                        isNested: true,
                      ),
                    ],
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
