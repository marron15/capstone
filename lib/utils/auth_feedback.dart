import 'package:flutter/material.dart';

import '../main.dart' show navigatorKey;

void showLoginSuccessSnackBar(
  BuildContext context, {
  required String name,
  bool isAdmin = false,
}) {
  final trimmedName = name.trim().isEmpty ? 'there' : name.trim();
  _showAuthFeedback(
    context,
    icon: Icons.check_circle_rounded,
    iconColor: const Color(0xFFA5D6A7),
    title: 'Login successful',
    message:
        isAdmin
            ? 'Welcome back, $trimmedName! You are now signed in to the admin dashboard.'
            : 'Welcome back, $trimmedName! You are now signed in to your account.',
    backgroundColor: const Color(0xFF1B5E20),
  );
}

void showLogoutSuccessSnackBar(
  BuildContext context, {
  String? name,
}) {
  final trimmedName = name?.trim();
  final message =
      trimmedName != null && trimmedName.isNotEmpty
          ? 'Goodbye, $trimmedName! You have been signed out safely.'
          : 'You have been signed out safely. See you next time!';

  _showAuthFeedback(
    context,
    icon: Icons.logout_rounded,
    iconColor: const Color(0xFFB0BEC5),
    title: 'Logout successful',
    message: message,
    backgroundColor: const Color(0xFF37474F),
  );
}

/// Shows logout feedback on the destination screen after navigation.
void showLogoutSuccessSnackBarFromRoot({String? name}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    showLogoutSuccessSnackBar(context, name: name);
  });
}

EdgeInsets _topRightSnackBarMargin(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final topInset = MediaQuery.paddingOf(context).top;
  const horizontalGap = 16.0;
  const topGap = 12.0;
  const snackbarMaxWidth = 400.0;
  const snackbarHeight = 96.0;

  final availableWidth = size.width - (horizontalGap * 2);
  final snackbarWidth =
      availableWidth > snackbarMaxWidth ? snackbarMaxWidth : availableWidth;
  final left = (size.width - snackbarWidth - horizontalGap).clamp(
    horizontalGap,
    size.width - horizontalGap,
  );
  final top = topInset + topGap;

  return EdgeInsets.only(
    left: left,
    right: horizontalGap,
    top: top,
    bottom: size.height - top - snackbarHeight,
  );
}

void _showAuthFeedback(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required String message,
  required Color backgroundColor,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: _topRightSnackBarMargin(context),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 4),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}

String resolveAdminDisplayName(Map<String, dynamic>? admin) {
  if (admin == null) return 'Admin';
  final first = (admin['first_name'] ?? '').toString().trim();
  final last = (admin['last_name'] ?? '').toString().trim();
  final full = [first, last].where((part) => part.isNotEmpty).join(' ');
  return full.isNotEmpty ? full : 'Admin';
}
