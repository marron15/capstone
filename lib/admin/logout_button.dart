import 'package:flutter/material.dart';
import '../services/auth_service.dart';

import '../User Profile/profile_data.dart';
import '../services/unified_auth_state.dart';
import '../utils/auth_feedback.dart';
import '../utils/logout_confirm_dialog.dart';

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
      shouldLogout = await showLogoutConfirmDialog(context);
    }

    if (!shouldLogout) return;

    final memberName = unifiedAuthState.customerName;

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
      await AuthService.logout(customerId: unifiedAuthState.customerId);

      // Clear auth state and local profile data
      unifiedAuthState.logout();
      profileNotifier.value = ProfileData();

      // Close loading dialog
      Navigator.of(context).pop();

      if (context.mounted) {
        onLogoutSuccess?.call();

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (Route<dynamic> route) => false,
        );
        showLogoutSuccessSnackBarFromRoot(name: memberName);
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Even if API call fails, clear auth state and local data and navigate
      unifiedAuthState.logout();
      profileNotifier.value = ProfileData();

      if (context.mounted) {
        onLogoutSuccess?.call();

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (Route<dynamic> route) => false,
        );
        showLogoutSuccessSnackBarFromRoot(name: memberName);
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
