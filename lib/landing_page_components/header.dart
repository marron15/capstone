import 'package:flutter/material.dart';
import '../services/unified_auth_state.dart';
import '../services/apk_download_button.dart';

// TRANSPARENT HEADER (moved from main.dart)
class MainHeader extends StatelessWidget {
  final bool isScrolled;
  final void Function(String section)? onSectionTap;
  const MainHeader({super.key, this.isScrolled = false, this.onSectionTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          height: isScrolled ? 80 : 160,
          decoration: BoxDecoration(
            color: isScrolled ? const Color(0xFF111111) : Colors.transparent,
            border:
                isScrolled
                    ? const Border(
                      bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
                    )
                    : null,
            boxShadow:
                isScrolled
                    ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'RNR FITNESS GYM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (MediaQuery.of(context).size.width >= 900) ...[
                  _HeaderNavTextButton(
                    label: 'Home',
                    onTap: () => onSectionTap?.call('Home'),
                  ),
                  _HeaderNavTextButton(
                    label: 'Service',
                    onTap: () => onSectionTap?.call('Service'),
                  ),
                  _HeaderNavTextButton(
                    label: 'Products',
                    onTap: () => onSectionTap?.call('Products'),
                  ),
                  _HeaderNavTextButton(
                    label: 'Inquiries',
                    onTap: () => onSectionTap?.call('Inquiries'),
                  ),
                  _HeaderNavTextButton(
                    label: 'About Us',
                    onTap: () => onSectionTap?.call('About Us'),
                  ),
                  const Spacer(),
                ],
                AnimatedBuilder(
                  animation: unifiedAuthState,
                  builder: (context, child) {
                    if (unifiedAuthState.isCustomerLoggedIn) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/customer-profile');
                            },
                            icon: const Icon(
                              Icons.account_circle,
                              color: Colors.white,
                              size: 40,
                            ),
                            tooltip: 'Profile',
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              await unifiedAuthState.logout();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Logged out successfully'),
                                  ),
                                );
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/home',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withValues(
                                alpha: 0.8,
                              ),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.logout, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(width: 10),
                const ApkDownloadButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderNavTextButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderNavTextButton({required this.label, required this.onTap});

  @override
  State<_HeaderNavTextButton> createState() => _HeaderNavTextButtonState();
}

class _HeaderNavTextButtonState extends State<_HeaderNavTextButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final Color hoverAccent = const Color(0xFFFFA812);
    final Color textColor = _isHovering ? hoverAccent : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        child: TextButton(
          onPressed: widget.onTap,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}
