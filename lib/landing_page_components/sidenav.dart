import 'package:flutter/material.dart';

import '../services/unified_auth_state.dart';

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

  @override
  Widget build(BuildContext context) {
    final List<String> sections = const [
      'Home',
      'Service',
      'Products',
      'Inquiries',
      'About Us',
    ];

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'RNR FITNESS GYM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Close menu',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withValues(alpha: 0.16), height: 1),
              const SizedBox(height: 14),
              for (final section in sections)
                _SideNavButton(
                  label: section,
                  onTap: () {
                    Navigator.of(context).pop();
                    onSectionTap?.call(section);
                  },
                ),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withValues(alpha: 0.16), height: 1),
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: unifiedAuthState,
                builder: (context, _) {
                  if (!unifiedAuthState.isCustomerLoggedIn) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onProfileTap,
                        icon: const Icon(Icons.account_circle),
                        label: const Text('Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: onLogoutTap,
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text(
                          'Logout',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.88),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SideNavButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          alignment: Alignment.centerLeft,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
