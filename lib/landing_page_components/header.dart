import 'package:flutter/material.dart';

class BlackHeader extends StatelessWidget {
  const BlackHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Logo or App Name
          const Icon(Icons.fitness_center, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Text(
            'RNR Fitness Gym',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          // Navigation Buttons
          _HeaderNavButton(icon: Icons.home, label: 'Home', onTap: () {}),
          _HeaderNavButton(icon: Icons.school, label: 'Programs', onTap: () {}),
          _HeaderNavButton(icon: Icons.card_membership, label: 'Membership', onTap: () {}),
          _HeaderNavButton(icon: Icons.info_outline, label: 'About Us', onTap: () {}),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: const Text('Sign Up'),
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
