import 'package:flutter/material.dart';
import '../modals/signup_modal.dart';
import '../modals/login.dart';

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
                    icon: Icons.home,
                    label: 'Home',
                    onTap: () => onNavTap(0),
                  ),
                  _HeaderNavButton(
                    icon: Icons.school,
                    label: 'Programs',
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
                    onTap: () => onNavTap(4),
                  ),
                  _HeaderNavButton(
                    icon: Icons.info_outline,
                    label: 'About Us',
                    onTap: () => onNavTap(5),
                  ),
                ],
              ),
            ),
            // Profile Button - Only show on larger screens
            if (!isSmallScreen && onProfileTap != null) ...[
              _HeaderNavButton(
                icon: Icons.person,
                label: 'Profile',
                onTap: onProfileTap!,
              ),
              const SizedBox(width: 12),
            ],
            const Spacer(),
            const SizedBox(width: 50),
          ],
          // Login Button
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const LoginModal(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
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
              'Login',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            ),
          ),
          const SizedBox(width: 10),
          // Sign Up Button
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const SignUpModal(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
                vertical: isSmallScreen ? 8 : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: Text(
              'Sign Up',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
