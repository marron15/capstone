import 'package:flutter/material.dart';
import '../modals/login.dart';
import '../services/auth_state.dart';
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
            animation: authState,
            builder: (context, child) {
              if (authState.isLoggedIn) {
                // Show Profile and Logout buttons when logged in
                return Row(
                  children: [
                    // Go to main.dart (Home) button
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginChoicePage(),
                          ),
                          (route) => false,
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 12,
                          vertical: isSmallScreen ? 6 : 8,
                        ),
                      ),
                      child: const Text('Home'),
                    ),
                    const SizedBox(width: 8),
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
                                          () =>
                                              Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(true),
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
                            await authState.logout();

                            // Show success message
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result.success
                                        ? 'Logged out successfully!'
                                        : 'Logged out locally',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            // Even if API call fails, clear auth state
                            await authState.logout();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Logged out locally'),
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
                // Show Login and Sign Up buttons when logged out
                return Row(
                  children: [
                    // Go to main.dart (Home) button
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginChoicePage(),
                          ),
                          (route) => false,
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 12,
                          vertical: isSmallScreen ? 6 : 8,
                        ),
                      ),
                      child: const Text('Home'),
                    ),
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
                  ],
                );
              }
            },
          ),
        ],
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
