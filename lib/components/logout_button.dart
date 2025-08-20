import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../landing_page_components/landing_page.dart';
import '../User Profile/profile_data.dart';
import '../services/auth_state.dart';

class LogoutButton extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onLogoutSuccess;
  final bool showConfirmDialog;
  final Color? iconColor;
  final Color? textColor;

  const LogoutButton({
    Key? key,
    this.child,
    this.onLogoutSuccess,
    this.showConfirmDialog = true,
    this.iconColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => handleLogout(context),
      child: child ?? Icon(Icons.logout, color: iconColor ?? Colors.white),
    );
  }

  Future<void> handleLogout(BuildContext context) async {
    bool shouldLogout = true;

    if (showConfirmDialog) {
      shouldLogout =
          await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Logout', style: TextStyle(color: textColor)),
                  ),
                ],
              );
            },
          ) ??
          false;
    }

    if (!shouldLogout) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Call logout API
      final result = await AuthService.logout();

      // Clear auth state and local profile data
      authState.logout();
      profileNotifier.value = ProfileData();

      // Close loading dialog
      Navigator.of(context).pop();

      if (context.mounted) {
        // Show success message
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

        // Call success callback if provided
        onLogoutSuccess?.call();

        // Navigate to landing page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LandingPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Even if API call fails, clear auth state and local data and navigate
      authState.logout();
      profileNotifier.value = ProfileData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out locally'),
            backgroundColor: Colors.orange,
          ),
        );

        onLogoutSuccess?.call();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LandingPage()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }
}

// Text button variant
class LogoutTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onLogoutSuccess;
  final bool showConfirmDialog;
  final Color? textColor;
  final double fontSize;

  const LogoutTextButton({
    Key? key,
    this.text = 'Logout',
    this.onLogoutSuccess,
    this.showConfirmDialog = true,
    this.textColor,
    this.fontSize = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LogoutButton(
      onLogoutSuccess: onLogoutSuccess,
      showConfirmDialog: showConfirmDialog,
      textColor: textColor,
      child: Text(
        text,
        style: TextStyle(color: textColor ?? Colors.white, fontSize: fontSize),
      ),
    );
  }
}

// Elevated button variant
class LogoutElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onLogoutSuccess;
  final bool showConfirmDialog;
  final Color? backgroundColor;
  final Color? textColor;

  const LogoutElevatedButton({
    Key? key,
    this.text = 'Logout',
    this.onLogoutSuccess,
    this.showConfirmDialog = true,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LogoutButton(
      onLogoutSuccess: onLogoutSuccess,
      showConfirmDialog: showConfirmDialog,
      textColor: textColor,
      child: ElevatedButton(
        onPressed: null, // Handled by LogoutButton
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.red,
          foregroundColor: textColor ?? Colors.white,
        ),
        child: Text(text),
      ),
    );
  }
}
