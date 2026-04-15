import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

import '../services/attendance_service.dart';
import '../services/unified_auth_state.dart';
import 'time_in_out_history_modal.dart';

class QrScannerDialog extends StatefulWidget {
  const QrScannerDialog();

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  bool _hasReturnedResult = false;

  void _handleScanResult(Code? code) {
    if (_hasReturnedResult) return;
    final String? value = code?.text;
    if (value == null || value.isEmpty) return;
    _hasReturnedResult = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isCompact = size.width < 560;
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: isCompact ? double.infinity : 420,
        height: isCompact ? 520 : 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scan Admin QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ReaderWidget(onScan: _handleScanResult),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                'Align the admin\'s QR code inside the frame. On desktop, use the gallery icon to pick an image if your camera is unavailable.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mixin to handle QR code scanning and attendance recording functionalities.
/// This mixin should be used with [State] classes that have [context], [mounted], and [setState].
mixin QrScanningMixin<T extends StatefulWidget> on State<T> {
  static const Duration _minimumSessionDuration = Duration(minutes: 3);

  // These should be implemented by the class using this mixin
  bool get isSubmittingScan;
  set isSubmittingScan(bool value);
  String? get scanErrorMessage;
  set scanErrorMessage(String? value);

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final int hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    final String period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  bool _isMembershipActive(DateTime expirationDate) {
    return DateTime.now().isBefore(expirationDate);
  }

  String _formatAttendanceTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'No attendance captured yet';
    return '${_formatDate(timestamp)} at ${_formatTime(timestamp)}';
  }

  Duration? _timeUntilTimeoutAllowed(AttendanceSnapshot? snapshot) {
    if (snapshot == null || !snapshot.isClockedIn) return null;
    final DateTime? lastTimeIn = snapshot.lastTimeIn;
    if (lastTimeIn == null) return null;
    final Duration elapsed = DateTime.now().difference(lastTimeIn);
    if (elapsed >= _minimumSessionDuration) return null;
    return _minimumSessionDuration - elapsed;
  }

  String _formatRemainingDuration(Duration duration) {
    final Duration safeDuration =
        duration.isNegative ? Duration.zero : duration;
    final int minutes = safeDuration.inMinutes;
    final int seconds = safeDuration.inSeconds.remainder(60);
    if (minutes > 0 && seconds > 0) return '${minutes}m ${seconds}s';
    if (minutes > 0) return '${minutes}m';
    return '${seconds}s';
  }

  Future<void> startScanFlow() async {
    if (!unifiedAuthState.isCustomerLoggedIn) {
      _showScanError('Please login to scan the admin QR code.');
      return;
    }

    final membershipData = unifiedAuthState.membershipData;
    if (membershipData == null) {
      _showScanError(
        'No membership found. Please contact the gym to activate your membership.',
      );
      return;
    }

    if (!_isMembershipActive(membershipData.expirationDate)) {
      _showScanError(
        'Your membership has expired. Please renew your membership to use the QR code scanner.',
      );
      return;
    }

    final String? payload = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const QrScannerDialog(),
    );

    if (!mounted || payload == null || payload.isEmpty) return;
    await recordAttendanceScan(payload);
  }

  Future<void> recordAttendanceScan(String payload) async {
    final int? customerId = unifiedAuthState.customerId;
    if (customerId == null) return;

    final membershipData = unifiedAuthState.membershipData;
    if (membershipData == null) {
      _showScanError(
        'No membership found. Please contact the gym to activate your membership.',
      );
      return;
    }

    if (!_isMembershipActive(membershipData.expirationDate)) {
      _showScanError(
        'Your membership has expired. Please renew your membership to use the QR code scanner.',
      );
      return;
    }

    if (!AttendanceService.isValidAdminPayload(payload)) {
      _showScanError(
        'Only the admin-issued QR code can be used for attendance.',
      );
      return;
    }

    final AttendanceSnapshot? currentSnapshot =
        unifiedAuthState.attendanceSnapshot;
    final Duration? remainingDuration = _timeUntilTimeoutAllowed(
      currentSnapshot,
    );
    if (remainingDuration != null) {
      final DateTime? nextAllowed = currentSnapshot?.lastTimeIn?.add(
        _minimumSessionDuration,
      );
      final StringBuffer message = StringBuffer(
        'You need at least 3 minutes between time-in and time-out. '
        'Please wait ${_formatRemainingDuration(remainingDuration)}',
      );
      if (nextAllowed != null) {
        message.write(
          ' (available at ${_formatAttendanceTimestamp(nextAllowed)})',
        );
      }
      message.write('.');
      _showScanError(message.toString());
      return;
    }

    setState(() {
      isSubmittingScan = true;
      scanErrorMessage = null;
    });

    try {
      final snapshot = await AttendanceService.recordScan(
        customerId: customerId,
        adminPayload: payload,
      );
      if (!mounted) return;
      unifiedAuthState.applyAttendanceSnapshot(snapshot);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            snapshot.isClockedIn
                ? 'Welcome! Your time-in has been captured.'
                : 'Great work! Time-out recorded.',
          ),
        ),
      );
    } on AttendanceException catch (e) {
      if (!mounted) return;
      _showScanError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showScanError('Unable to record attendance. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isSubmittingScan = false);
      }
    }
  }

  void _showScanError(String message) {
    if (!mounted) return;
    setState(() => scanErrorMessage = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> openAttendanceHistory() async {
    if (!unifiedAuthState.isCustomerLoggedIn) {
      _showScanError('Please login to view your attendance history.');
      return;
    }

    final int? customerId = unifiedAuthState.customerId;
    if (customerId == null || customerId <= 0) {
      _showScanError('Unable to load attendance history right now.');
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder:
          (_) => TimeInOutHistoryModal(
            customerId: customerId,
            memberName: unifiedAuthState.customerName ?? 'Member',
          ),
    );
  }

  Widget buildAttendanceStatusContent(
    AttendanceSnapshot? snapshot,
    bool isSmallScreen,
  ) {
    final bool hasSnapshot = snapshot != null;
    final bool isClockedIn = snapshot?.isClockedIn ?? false;
    final Color badgeColor =
        hasSnapshot
            ? (isClockedIn ? Colors.greenAccent : const Color(0xFFFFC857))
            : Colors.grey;
    final DateTime? timestamp = snapshot?.referenceTimestamp;
    final String adminName = snapshot?.verifyingAdminName ?? 'Awaiting scan';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isClockedIn ? Icons.login : Icons.logout,
                    color: badgeColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isClockedIn ? 'Clocked In' : 'Clocked Out',
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Icon(Icons.lock_clock, color: Colors.white.withValues(alpha: 0.7)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          hasSnapshot
              ? _formatAttendanceTimestamp(timestamp)
              : 'Scan the admin QR code when you arrive or leave the gym.',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 14 : 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.verified_user, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Verified by: $adminName',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
