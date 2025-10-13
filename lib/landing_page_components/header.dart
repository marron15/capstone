import 'package:flutter/material.dart';
import '../modals_customer/login.dart';
import '../services/unified_auth_state.dart';
import '../services/auth_service.dart';
import '../main.dart';

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
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const LoginChoicePage(),
                      ),
                      (route) => false,
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
                      _HeaderNavButton(
                        icon: Icons.fitness_center,
                        label: 'Gym Equipment',
                        onTap: () => onNavTap(1),
                      ),
                      _HeaderNavButton(
                        icon: Icons.shopping_cart,
                        label: 'Products',
                        onTap: () => onNavTap(2),
                      ),
                      _HeaderNavButton(
                        icon: Icons.person,
                        label: 'Trainers',
                        onTap: () => onNavTap(5),
                      ),
                      _HeaderNavButton(
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
                          _HeaderNavButton(
                            icon: Icons.person,
                            label: 'Profile',
                            onTap: onProfileTap ?? () {},
                          ),
                          const SizedBox(width: 12),
                        ],
                        // Logout Button
                        ElevatedButton(
                          onPressed: () async {
                            // Show confirmation dialog
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
                                // Call logout API
                                final result = await AuthService.logout();

                                // Clear auth state
                                await unifiedAuthState.logout();

                                // Show success message
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result.success
                                            ? 'Logged out successfully!'
                                            : 'Successfully Logout',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                // Even if API call fails, clear auth state
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
                    // Show Login button when logged out
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        // Login Button
                        _HoverElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const LoginModal(),
                            );
                          },
                          isSmallScreen: isSmallScreen,
                          text: 'Login',
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        // Help icon next to Login
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

class _HeaderNavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_HeaderNavButton> createState() => _HeaderNavButtonState();
}

class _HeaderNavButtonState extends State<_HeaderNavButton> {
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

class _HoverElevatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isSmallScreen;
  final String text;

  const _HoverElevatedButton({
    required this.onPressed,
    required this.isSmallScreen,
    required this.text,
  });

  @override
  State<_HoverElevatedButton> createState() => _HoverElevatedButtonState();
}

class _HoverElevatedButtonState extends State<_HoverElevatedButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final Color hoverAccent = const Color(0xFFFFA812);
    final Color textColor = _isHovering ? hoverAccent : Colors.black;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSmallScreen ? 14 : 18,
            vertical: widget.isSmallScreen ? 8 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          style: TextStyle(
            color: textColor,
            fontSize: widget.isSmallScreen ? 14 : 16,
          ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}
