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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (MediaQuery.of(context).size.width >= 900) ...[
                  _HeaderNavTextButton(label: 'Home', onTap: () => onSectionTap?.call('Home')),
                  _HeaderNavTextButton(label: 'Service', onTap: () => onSectionTap?.call('Service')),
                  _HeaderNavTextButton(label: 'Products', onTap: () => onSectionTap?.call('Products')),
                  _HeaderNavTextButton(label: 'Inquiries', onTap: () => onSectionTap?.call('Inquiries')),
                  _HeaderNavTextButton(label: 'About Us', onTap: () => onSectionTap?.call('About Us')),
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
                              size: 28,
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
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

// BLACK HEADER (used by landing_page.dart)
class BlackHeader extends StatelessWidget {
  final Function(int) onNavTap;
  final VoidCallback? onProfileTap;

  const BlackHeader({Key? key, required this.onNavTap, this.onProfileTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: 12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isSmallScreen ? double.infinity : 1200,
          ),
          child: Row(
            children: [
              if (isSmallScreen) ...[
                Builder(
                  builder:
                      (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                ),
                const SizedBox(width: 30),
              ],
              // Home icon button placed on the left side
              Tooltip(
                message: 'Home',
                child: IconButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => route.isFirst,
                    );
                  },
                  icon: const Icon(Icons.home_outlined, color: Colors.white),
                  iconSize: isSmallScreen ? 20 : 30,
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  splashRadius: isSmallScreen ? 18 : 20,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 8),
              const Spacer(),
              // Navigation Buttons - Only show on larger screens
              if (!isSmallScreen) ...[
                const Spacer(),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BlackHeaderNavButton(
                        icon: Icons.fitness_center,
                        label: 'Gym Equipment',
                        onTap: () => onNavTap(1),
                      ),
                      _BlackHeaderNavButton(
                        icon: Icons.shopping_cart,
                        label: 'Products',
                        onTap: () => onNavTap(2),
                      ),
                      _BlackHeaderNavButton(
                        icon: Icons.person,
                        label: 'Trainers',
                        onTap: () => onNavTap(5),
                      ),
                      _BlackHeaderNavButton(
                        icon: Icons.info_outline,
                        label: 'About Us',
                        onTap: () => onNavTap(5),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 24),
              ],
              // Conditional rendering based on authentication state
              AnimatedBuilder(
                animation: unifiedAuthState,
                builder: (context, child) {
                  if (unifiedAuthState.isCustomerLoggedIn) {
                    // Show Profile and Logout buttons when logged in
                    return Row(
                      children: [
                        // Profile Button
                        if (!isSmallScreen) ...[
                          _BlackHeaderNavButton(
                            icon: Icons.person,
                            label: 'Profile',
                            onTap: onProfileTap ?? () {},
                          ),
                          const SizedBox(width: 12),
                        ],
                        // Logout Button
                        ElevatedButton(
                          onPressed: () async {
                            final bool shouldLogout =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Logout'),
                                      content: const Text(
                                        'Are you sure you want to logout?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                          child: const Text('Logout'),
                                        ),
                                      ],
                                    );
                                  },
                                ) ??
                                false;

                            if (shouldLogout) {
                              try {
                                await unifiedAuthState.logout();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Logged out successfully!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                await unifiedAuthState.logout();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Successfully Logout'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 14 : 18,
                              vertical: isSmallScreen ? 8 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Logout',
                            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Show help tooltip when logged out
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message:
                              'Information\n\n• New to gym? you have free 3 days trial! to be his trainer, after that you can pay for Membership\n\n• How to get Membership and Account?\n  Go to 875 RIZAL AVENUE WEST TAPINAC, OLONGAPO CITY (RNR GYM)',
                          preferBelow: false,
                          verticalOffset: 8,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          margin: const EdgeInsets.only(top: 10),
                          waitDuration: const Duration(milliseconds: 180),
                          showDuration: const Duration(seconds: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xF0111111),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFFA812),
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xAA000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          textStyle: const TextStyle(
                            color: Colors.white,
                            height: 1.4,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.help_outline,
                              color: Colors.white70,
                            ),
                            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                            iconSize: isSmallScreen ? 18 : 20,
                            splashRadius: isSmallScreen ? 18 : 20,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      backgroundColor: const Color(0xFF111111),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      titlePadding: const EdgeInsets.fromLTRB(
                                        20,
                                        16,
                                        20,
                                        0,
                                      ),
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        20,
                                        12,
                                        20,
                                        12,
                                      ),
                                      title: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(0x22FFFFFF),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.help_outline,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Information',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: 520,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  color: Color(0xFFFFA812),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    'New to gym? you have free 3 days trial! to be his trainer, after that you can pay for Membership',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      height: 1.6,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 14),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.place_outlined,
                                                  color: Color(0xFF64B5F6),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    'How to Get Membership and Account? Go to 875 RIZAL AVENUE WEST TAPINAC , OLONGAPO CITY RNR GYM',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      height: 1.6,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      actionsPadding: const EdgeInsets.fromLTRB(
                                        12,
                                        0,
                                        12,
                                        8,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.white70,
                                          ),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlackHeaderNavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BlackHeaderNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_BlackHeaderNavButton> createState() => _BlackHeaderNavButtonState();
}

class _BlackHeaderNavButtonState extends State<_BlackHeaderNavButton> {
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
        child: TextButton.icon(
          onPressed: widget.onTap,
          icon: Icon(widget.icon, color: Colors.white, size: 20),
          label: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            style: TextStyle(color: textColor, fontSize: 16),
            child: Text(widget.label),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }
}
