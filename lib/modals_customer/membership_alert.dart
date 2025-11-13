import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/unified_auth_state.dart';

class MembershipAlertModal extends StatefulWidget {
  const MembershipAlertModal({Key? key}) : super(key: key);

  @override
  State<MembershipAlertModal> createState() => _MembershipAlertModalState();
}

class _MembershipAlertModalState extends State<MembershipAlertModal>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _timerController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnim = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.dispose();
    _timerController.dispose();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild and update the time remaining display
        });
      } else {
        timer.cancel();
      }
    });
  }

  // Helper method to get time remaining
  String _getTimeRemaining(DateTime expirationDate) {
    final now = DateTime.now();
    final difference = expirationDate.difference(now);

    if (difference.isNegative) return 'Expired';

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m ${seconds}s';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Helper method to check if membership is active
  bool _isMembershipActive(DateTime expirationDate) {
    return DateTime.now().isBefore(expirationDate);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    // Check if membership is expired
    final isExpired =
        unifiedAuthState.membershipData != null &&
        !_isMembershipActive(unifiedAuthState.membershipData!.expirationDate);

    const Color expiredBackgroundStart = Color(0xFF4A1111);
    const Color expiredBackgroundMid = Color(0xFFAB1E1E);
    const Color expiredBackgroundEnd = Color(0xFFE53935);
    const Color expiredAccent = Color(0xFFFFEBEE);
    const Color activeBackgroundStart = Color(0xFF161C2C);
    const Color activeBackgroundEnd = Color(0xFF1F283C);
    const Color activeAccent = Color(0xFFFFB74D);
    const Color activePrimary = Color(0xFFE0F7FA);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isSmallScreen ? screenSize.width * 0.95 : 480,
            maxHeight: screenSize.height * 0.8,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.1),
                  end: Offset.zero,
                ).animate(_slideAnim),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient:
                            isExpired
                                ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    expiredBackgroundStart,
                                    expiredBackgroundMid,
                                    expiredBackgroundEnd,
                                  ],
                                )
                                : const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    activeBackgroundStart,
                                    activeBackgroundEnd,
                                  ],
                                ),
                        border: Border.all(
                          color:
                              isExpired
                                  ? Colors.black.withValues(alpha: 0.18)
                                  : Colors.black.withValues(alpha: 0.35),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 1,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color:
                                isExpired
                                    ? Colors.black.withValues(alpha: 0.35)
                                    : Colors.black.withValues(alpha: 0.45),
                            blurRadius: 42,
                            spreadRadius: 4,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header with close button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            isExpired
                                                ? Colors.white.withValues(
                                                  alpha: 0.12,
                                                )
                                                : activeAccent.withValues(
                                                  alpha: 0.18,
                                                ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isExpired ? Icons.warning : Icons.timer,
                                        color:
                                            isExpired
                                                ? expiredAccent
                                                : activeAccent,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isExpired
                                          ? 'Membership Expired'
                                          : 'Membership Alert',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isSmallScreen ? 20 : 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white70,
                                    size: 24,
                                  ),
                                  tooltip: 'Close',
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Time remaining section
                            if (unifiedAuthState.membershipData != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient:
                                      isExpired
                                          ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withValues(
                                                alpha: 0.24,
                                              ),
                                              Colors.white.withValues(
                                                alpha: 0.14,
                                              ),
                                            ],
                                          )
                                          : LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withValues(
                                                alpha: 0.12,
                                              ),
                                              Colors.white.withValues(
                                                alpha: 0.06,
                                              ),
                                            ],
                                          ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        isExpired
                                            ? Colors.white.withValues(
                                              alpha: 0.3,
                                            )
                                            : Colors.white.withValues(
                                              alpha: 0.18,
                                            ),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      isExpired
                                          ? 'Membership Status'
                                          : 'Time Remaining',
                                      style: TextStyle(
                                        color:
                                            isExpired
                                                ? Colors.white
                                                : Colors.white.withValues(
                                                  alpha: 0.85,
                                                ),
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isExpired
                                          ? 'EXPIRED'
                                          : _getTimeRemaining(
                                            unifiedAuthState
                                                .membershipData!
                                                .expirationDate,
                                          ),
                                      style: TextStyle(
                                        color:
                                            isExpired
                                                ? expiredAccent
                                                : activePrimary,
                                        fontSize: isSmallScreen ? 28 : 32,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (!isExpired) ...[
                                      Container(
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                        child: LinearProgressIndicator(
                                          value: _getMembershipProgress(
                                            unifiedAuthState
                                                .membershipData!
                                                .startDate,
                                            unifiedAuthState
                                                .membershipData!
                                                .expirationDate,
                                          ),
                                          backgroundColor: Colors.transparent,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                activeAccent,
                                              ),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],

                            // Extension message
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient:
                                    isExpired
                                        ? LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white.withValues(
                                              alpha: 0.18,
                                            ),
                                            Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
                                          ],
                                        )
                                        : LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white.withValues(
                                              alpha: 0.12,
                                            ),
                                            Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                          ],
                                        ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      isExpired
                                          ? Colors.white.withValues(alpha: 0.28)
                                          : Colors.white.withValues(
                                            alpha: 0.18,
                                          ),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    isExpired
                                        ? Icons.warning
                                        : Icons.location_on,
                                    color:
                                        isExpired
                                            ? expiredAccent
                                            : activeAccent,
                                    size: isSmallScreen ? 24 : 28,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    isExpired
                                        ? 'Membership Has Expired!'
                                        : 'Want to Extend Membership?',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color:
                                          isExpired
                                              ? Colors.white
                                              : Colors.white.withValues(
                                                alpha: 0.92,
                                              ),
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isExpired
                                        ? 'Your membership has expired. Please renew to continue using our facilities.'
                                        : 'Go to RNR GYM to Extend your Membership at',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                      fontSize: isSmallScreen ? 12 : 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '875 RIZAL AVENUE WEST TAPINAC, OLONGAPO CITY',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color:
                                          isExpired
                                              ? expiredAccent
                                              : activeAccent,
                                      fontSize: isSmallScreen ? 13 : 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Action buttons
                            if (isExpired) ...[
                              // Only Close button for expired memberships
                              SizedBox(
                                width: double.infinity,
                                child: _AnimatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  backgroundColor: expiredBackgroundEnd,
                                  textColor: Colors.white,
                                  text: 'Close',
                                ),
                              ),
                            ] else ...[
                              // Two buttons for active memberships
                              Row(
                                children: [
                                  Expanded(
                                    child: _AnimatedButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      textColor: Colors.white,
                                      text: 'Later',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _AnimatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.pushNamed(
                                          context,
                                          '/customer-profile',
                                        );
                                      },
                                      backgroundColor: activeAccent,
                                      textColor: Colors.black,
                                      text: 'View Profile',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to get membership progress (0.0 to 1.0)
  double _getMembershipProgress(DateTime startDate, DateTime expirationDate) {
    final now = DateTime.now();
    final totalDuration = expirationDate.difference(startDate);
    final elapsed = now.difference(startDate);

    if (totalDuration.inMilliseconds == 0) return 0.0;
    if (elapsed.isNegative) return 0.0;
    if (elapsed.inMilliseconds > totalDuration.inMilliseconds) return 1.0;

    return elapsed.inMilliseconds / totalDuration.inMilliseconds;
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final String text;

  const _AnimatedButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    required this.text,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: isEnabled ? _onTapDown : null,
        onTapUp: isEnabled ? _onTapUp : null,
        onTapCancel: isEnabled ? _onTapCancel : null,
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color:
                      isEnabled
                          ? widget.backgroundColor
                          : Colors.grey.withValues(alpha: 0.3),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isEnabled
                              ? widget.backgroundColor.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: widget.onPressed,
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        widget.text,
                        style: TextStyle(
                          color:
                              isEnabled ? widget.textColor : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
