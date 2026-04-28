import 'dart:async';
import 'package:flutter/material.dart';

import '../landing_page_modals/membership_history_modal.dart';
import '../landing_page_modals/scan_qr.dart';

import '../services/attendance_service.dart';
import '../services/unified_auth_state.dart';

class HeroMembershipContainer extends StatefulWidget {
  const HeroMembershipContainer({Key? key}) : super(key: key);

  @override
  State<HeroMembershipContainer> createState() =>
      _HeroMembershipContainerState();
}

class _HeroMembershipContainerState extends State<HeroMembershipContainer>
    with QrScanningMixin {
  Timer? _countdownTimer;
  bool isSubmittingScan = false;
  String? scanErrorMessage;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
    unifiedAuthState.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    unifiedAuthState.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (unifiedAuthState.isCustomerLoggedIn) {
      _startCountdownTimer();
    } else {
      _countdownTimer?.cancel();
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      } else {
        timer.cancel();
      }
    });
  }

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

  String _getTimeRemaining(DateTime expirationDate) {
    final now = DateTime.now();
    final difference = expirationDate.difference(now);
    if (difference.isNegative) return 'Expired';
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;
    if (days > 0) return '${days}d ${hours}h ${minutes}m ${seconds}s';
    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  double _getMembershipProgress(DateTime startDate, DateTime expirationDate) {
    final now = DateTime.now();
    final totalDuration = expirationDate.difference(startDate);
    final elapsed = now.difference(startDate);
    if (totalDuration.inMilliseconds == 0) return 0.0;
    if (elapsed.isNegative) return 0.0;
    if (elapsed.inMilliseconds > totalDuration.inMilliseconds) return 1.0;
    return elapsed.inMilliseconds / totalDuration.inMilliseconds;
  }

  Widget _buildDateRow(
    String label,
    String date,
    IconData icon,
    Color color,
    bool isSmallScreen,
    Size screenSize,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  color: Colors.white,
                  fontSize:
                      (isSmallScreen
                          ? (screenSize.width * 0.035).clamp(12.0, 18.0)
                          : (screenSize.width * 0.024).clamp(14.0, 22.0)),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  int _getDaysUsed(DateTime startDate) =>
      DateTime.now().difference(startDate).inDays;

  int _getDaysLeft(DateTime expirationDate) {
    final difference = expirationDate.difference(DateTime.now());
    return difference.isNegative ? 0 : difference.inDays;
  }

  String _formatAttendanceTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'No attendance captured yet';
    return '${_formatDate(timestamp)} at ${_formatTime(timestamp)}';
  }

  // Delegates to QrScanningMixin to avoid duplication
  Future<void> _startScanFlow() => startScanFlow();
  // QR scan operations delegated to QrScanningMixin

  Future<void> _openAttendanceHistory() async => await openAttendanceHistory();

  Widget _buildAttendanceStatusContent(
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
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(
                    isClockedIn ? Icons.login : Icons.logout,
                    size: 16,
                    color: badgeColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    snapshot?.readableStatus ?? 'Awaiting Scan',
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
            const Icon(Icons.verified_user, size: 16, color: Colors.white70),
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

  // ── Shared sub-builders ────────────────────────────────────────────────

  Widget _buildMembershipInfoColumn(bool isSmallScreen, Size screenSize) {
    final data = unifiedAuthState.membershipData!;
    final bool active = _isMembershipActive(data.expirationDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row: type + badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${data.membershipType} Membership',
                style: TextStyle(
                  color: const Color(0xFFFFA812),
                  fontSize:
                      isSmallScreen
                          ? (screenSize.width * 0.045).clamp(16.0, 22.0)
                          : (screenSize.width * 0.022).clamp(16.0, 24.0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:
                    active
                        ? Colors.green.withValues(alpha: 0.9)
                        : Colors.red.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (active ? Colors.green : Colors.red).withValues(
                      alpha: 0.4,
                    ),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    active ? Icons.check_circle : Icons.warning,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    active ? 'Active' : 'Expired',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Progress bar
        if (active) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Time Remaining',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _getTimeRemaining(data.expirationDate),
                style: const TextStyle(
                  color: Color(0xFFFFA812),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: _getMembershipProgress(data.startDate, data.expirationDate),
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA812)),
            minHeight: 5,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 14),
        ],
        // Dates box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildDateRow(
                'Start Date',
                _formatDate(data.startDate),
                Icons.calendar_today,
                const Color(0xFFFFA812),
                isSmallScreen,
                screenSize,
              ),
              const SizedBox(height: 10),
              _buildDateRow(
                'Expires',
                data.membershipType == 'Daily'
                    ? _getTimeRemaining(data.expirationDate)
                    : _formatDate(data.expirationDate),
                Icons.event_busy,
                const Color(0xFFFFA812),
                isSmallScreen,
                screenSize,
              ),
            ],
          ),
        ),
        // Stats (days used/left)
        if (active) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA812).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFFA812).withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Days Used',
                    '${_getDaysUsed(data.startDate)}',
                    Icons.timer,
                    const Color(0xFFFFA812),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Days Left',
                    '${_getDaysLeft(data.expirationDate)}',
                    Icons.schedule,
                    const Color(0xFFFFA812),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        // Attendance status
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: _buildAttendanceStatusContent(
            unifiedAuthState.attendanceSnapshot,
            isSmallScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isSmallScreen) {
    return AnimatedBuilder(
      animation: unifiedAuthState,
      builder: (context, _) {
        if (!unifiedAuthState.isCustomerLoggedIn)
          return const SizedBox.shrink();
        final bool active =
            unifiedAuthState.membershipData != null &&
            _isMembershipActive(
              unifiedAuthState.membershipData!.expirationDate,
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionBtn(
              icon: Icons.qr_code_scanner,
              label:
                  isSubmittingScan
                      ? 'Processing...'
                      : (!active ? 'Membership Expired' : 'Scan Admin QR'),
              color: const Color(0xFFFFA812),
              onPressed: (isSubmittingScan || !active) ? null : _startScanFlow,
              isLoading: isSubmittingScan,
            ),
            const SizedBox(height: 10),
            _ActionBtn(
              icon: Icons.history,
              label: 'Time In/Out History',
              color: Colors.white70,
              onPressed: _openAttendanceHistory,
            ),
            const SizedBox(height: 10),
            _ActionBtn(
              icon: Icons.history_rounded,
              label: 'Membership History',
              color: const Color(0xFFFFA812).withValues(alpha: 0.8),
              onPressed: () => showMembershipHistoryModal(context),
            ),
            if (scanErrorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                scanErrorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double viewportWidth =
            constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : screenSize.width;
        final double viewportHeight =
            constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : screenSize.height;

        final bool isSmallScreen = viewportWidth < 600;
        final bool isWide = viewportWidth >= 900;
        final bool isCompactHeight = viewportHeight < 820;
        final double targetWidth = isWide ? 860 : (isSmallScreen ? 340 : 480);
        final double contentWidth =
            isSmallScreen ? viewportWidth.clamp(280.0, 380.0) : targetWidth;
        final Size responsiveSize = Size(viewportWidth, viewportHeight);

        return SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: contentWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome back, ${unifiedAuthState.customerName ?? 'Member'}!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize:
                          isSmallScreen
                              ? (responsiveSize.width * 0.12).clamp(16.0, 24.0)
                              : (responsiveSize.width * 0.045).clamp(
                                20.0,
                                36.0,
                              ),
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(
                    height: isCompactHeight ? 10 : responsiveSize.height * 0.02,
                  ),
                  if (unifiedAuthState.membershipData != null) ...[
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: targetWidth),
                      padding: EdgeInsets.all(isCompactHeight ? 14 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF131313),
                            const Color(0xFF1E1E1E),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.38),
                            blurRadius: 20,
                            spreadRadius: 1,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child:
                          isWide
                              ? IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _buildMembershipInfoColumn(
                                        isSmallScreen,
                                        responsiveSize,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    VerticalDivider(
                                      width: 1,
                                      thickness: 1,
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(height: 8),
                                          _buildActionButtons(isSmallScreen),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : Column(
                                children: [
                                  _buildMembershipInfoColumn(
                                    isSmallScreen,
                                    responsiveSize,
                                  ),
                                  SizedBox(height: isCompactHeight ? 10 : 16),
                                  _buildActionButtons(isSmallScreen),
                                ],
                              ),
                    ),
                  ] else ...[
                    Text(
                      'Loading membership details...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize:
                            isSmallScreen
                                ? (responsiveSize.width * 0.035).clamp(
                                  12.0,
                                  18.0,
                                )
                                : (responsiveSize.width * 0.024).clamp(
                                  14.0,
                                  22.0,
                                ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Reusable action button ───────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final bool isCompactHeight = screenSize.height < 820;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color.withValues(alpha: 0.12),
        side: BorderSide(color: color.withValues(alpha: 0.9), width: 1.8),
        minimumSize: Size(double.infinity, isCompactHeight ? 46 : 54),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 22,
          vertical: isCompactHeight ? 10 : (isSmallScreen ? 14 : 16),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: (isSmallScreen || isCompactHeight) ? 20 : 22,
            color: color,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompactHeight ? 14 : (isSmallScreen ? 15 : 16),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (isLoading) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
