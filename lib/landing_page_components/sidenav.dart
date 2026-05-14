import 'package:flutter/material.dart';

import '../services/unified_auth_state.dart';

/// Landing drawer — layout/spacing aligned with [SideNav] in `admin/sidenav.dart`
/// (header height/padding, ListTile metrics, nav margins, logout padding).
class LandingSideNav extends StatelessWidget {
  final void Function(String section)? onSectionTap;
  final VoidCallback onProfileTap;
  final Future<void> Function() onLogoutTap;

  const LandingSideNav({
    super.key,
    this.onSectionTap,
    required this.onProfileTap,
    required this.onLogoutTap,
  });

  static const List<String> _sections = [
    'Home',
    'Service',
    'Products',
    'Inquiries',
    'About Us',
  ];

  static IconData _iconForSection(String section) {
    switch (section) {
      case 'Home':
        return Icons.home_rounded;
      case 'Service':
        return Icons.fitness_center_rounded;
      case 'Products':
        return Icons.shopping_bag_rounded;
      case 'Inquiries':
        return Icons.mail_outline_rounded;
      case 'About Us':
        return Icons.info_outline_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  /// Same outer spacing pattern as admin `_navItem` (margin + ListTile paddings).
  Widget _navRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.92),
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        contentPadding: const EdgeInsets.only(
          left: 20,
          right: 16,
          top: 4,
          bottom: 4,
        ),
        minLeadingWidth: 24,
        minVerticalPadding: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.14),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: unifiedAuthState,
                builder: (context, child) {
                  final bool loggedIn = unifiedAuthState.isCustomerLoggedIn;

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Container(
                        height: 70,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'RNR FITNESS GYM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close menu',
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      if (loggedIn)
                        _navRow(
                          icon: Icons.account_circle_outlined,
                          label: 'Profile',
                          onTap: onProfileTap,
                        ),
                      for (final section in _sections)
                        _navRow(
                          icon: _iconForSection(section),
                          label: section,
                          onTap: () {
                            Navigator.of(context).pop();
                            onSectionTap?.call(section);
                          },
                        ),
                      if (loggedIn)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                              minimumSize: const Size.fromHeight(40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: onLogoutTap,
                          ),
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
