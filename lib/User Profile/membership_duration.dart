import 'package:flutter/material.dart';

String formatMembershipExpiration(DateTime? date) {
  if (date == null) return 'Membership Expiration: --';
  final months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return 'Membership Expiration: \\${months[date.month - 1]} \\${date.day}, \\${date.year}';
}

Widget membershipExpirationText(DateTime? date) {
  return Text(
    formatMembershipExpiration(date),
    style: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
  );
}
