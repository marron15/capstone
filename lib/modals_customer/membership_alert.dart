import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/unified_auth_state.dart';
import '../admin/services/api_service.dart';

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

  bool _isLoadingReservations = true;
  Map<String, dynamic>? _latestReservation;

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
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    if (unifiedAuthState.customerId == null) {
      setState(() => _isLoadingReservations = false);
      return;
    }

    try {
      final reservations = await ApiService.getCustomerReservations(
        customerId: unifiedAuthState.customerId!,
      );

      if (mounted) {
        setState(() {
          _isLoadingReservations = false;

          // Get the latest reservation with accepted or declined status
          final processedReservations =
              reservations.where((r) {
                final status = (r['status'] ?? '').toString().toLowerCase();
                return status == 'accepted' || status == 'declined';
              }).toList();

          if (processedReservations.isNotEmpty) {
            // Sort by created_at descending to get the latest
            processedReservations.sort((a, b) {
              final dateA =
                  DateTime.tryParse((a['created_at'] ?? '').toString()) ??
                  DateTime(1970);
              final dateB =
                  DateTime.tryParse((b['created_at'] ?? '').toString()) ??
                  DateTime(1970);
              return dateB.compareTo(dateA);
            });
            _latestReservation = processedReservations.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReservations = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    const Color activeBackgroundStart = Color(0xFF161C2C);
    const Color activeBackgroundEnd = Color(0xFF1F283C);
    const Color activeAccent = Color(0xFFFFB74D);

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
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [activeBackgroundStart, activeBackgroundEnd],
                        ),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.35),
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
                            color: Colors.black.withValues(alpha: 0.45),
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
                                        color: activeAccent.withValues(
                                          alpha: 0.18,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _latestReservation != null
                                            ? (_latestReservation!['status'] ??
                                                            '')
                                                        .toString()
                                                        .toLowerCase() ==
                                                    'accepted'
                                                ? Icons.check_circle
                                                : Icons.cancel
                                            : Icons.inventory_2,
                                        color:
                                            _latestReservation != null
                                                ? (_latestReservation!['status'] ??
                                                                '')
                                                            .toString()
                                                            .toLowerCase() ==
                                                        'accepted'
                                                    ? Colors.green.shade300
                                                    : Colors.red.shade300
                                                : activeAccent,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _latestReservation != null
                                          ? 'Reservation Update'
                                          : 'Product Reservations',
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

                            // Reservation Status section
                            if (_isLoadingReservations)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            else if (_latestReservation != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.12),
                                      Colors.white.withValues(alpha: 0.06),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Reservation Status',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Show status based on accepted/declined
                                    if ((_latestReservation!['status'] ?? '')
                                            .toString()
                                            .toLowerCase() ==
                                        'declined') ...[
                                      // Declined status
                                      Text(
                                        'DECLINED',
                                        style: TextStyle(
                                          color: Colors.red.shade300,
                                          fontSize: isSmallScreen ? 28 : 32,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      // Show admin note if available
                                      if (_latestReservation!['decline_note'] !=
                                              null &&
                                          (_latestReservation!['decline_note'] ??
                                                  '')
                                              .toString()
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Admin Note:',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.8),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                (_latestReservation!['decline_note'])
                                                    .toString(),
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.9),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ] else ...[
                                      // Accepted status
                                      Text(
                                        'Your Reserve Request has been accepted',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.green.shade300,
                                          fontSize: isSmallScreen ? 20 : 24,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                    if (_latestReservation!['product_name'] !=
                                        null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        'Product: ${_latestReservation!['product_name']}',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ] else ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.12),
                                      Colors.white.withValues(alpha: 0.06),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No Reservations',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'You have no product reservations',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Information message
                            if (_latestReservation != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.12),
                                      Colors.white.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      (_latestReservation!['status'] ?? '')
                                                  .toString()
                                                  .toLowerCase() ==
                                              'accepted'
                                          ? Icons.check_circle_outline
                                          : Icons.info_outline,
                                      color:
                                          (_latestReservation!['status'] ?? '')
                                                      .toString()
                                                      .toLowerCase() ==
                                                  'accepted'
                                              ? Colors.green.shade300
                                              : Colors.orange.shade300,
                                      size: isSmallScreen ? 24 : 28,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      (_latestReservation!['status'] ?? '')
                                                  .toString()
                                                  .toLowerCase() ==
                                              'accepted'
                                          ? 'Reservation Accepted!'
                                          : 'Reservation Declined',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.92,
                                        ),
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      (_latestReservation!['status'] ?? '')
                                                  .toString()
                                                  .toLowerCase() ==
                                              'accepted'
                                          ? 'You can pick up your reserved product at the gym.'
                                          : 'Please see the admin note above for details.',
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
                                        color: activeAccent,
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
                                    text: 'Close',
                                  ),
                                ),
                                if (_latestReservation != null) ...[
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
                              ],
                            ),
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
