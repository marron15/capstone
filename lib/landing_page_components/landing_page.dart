import 'package:flutter/material.dart';

import 'header.dart';

import 'equipment_images.dart';

import 'add_ons.dart';

import 'products.dart';

import 'trainers.dart';

import '../services/auth_state.dart';

import 'footer.dart';

import '../User Profile/profile.dart';

import '../User Profile/profile_data.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _equipmentImagesKey = GlobalKey();

  final GlobalKey _servicesKey = GlobalKey();

  final GlobalKey _productsKey = GlobalKey();

  final GlobalKey _plansKey = GlobalKey();

  final GlobalKey _trainersKey = GlobalKey();

  late AnimationController _heroController;
  late AnimationController _fadeController;
  late Animation<double> _heroAnimation;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _heroAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
    );

    // Start animations
    _heroController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _scrollToSection(int index) {
    if (index == 0) {
      _scrollController.animateTo(
        0.0,

        duration: const Duration(milliseconds: 500),

        curve: Curves.easeInOut,
      );

      return;
    }

    final contextList = [
      _equipmentImagesKey.currentContext, // index 1

      _servicesKey.currentContext, // index 2

      _productsKey.currentContext, // index 3

      _plansKey.currentContext, // index 4

      _trainersKey.currentContext, // index 5
    ];

    // Adjust index for the new list starting from 1

    final adjustedIndex = index - 1;

    if (adjustedIndex >= 0 && adjustedIndex < contextList.length) {
      final ctx = contextList[adjustedIndex];

      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,

          duration: const Duration(milliseconds: 500),

          curve: Curves.easeInOut,
        );
      }
    }
  }

  // Helper method to format dates

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

  // Helper method to check if membership is active

  bool _isMembershipActive(DateTime expirationDate) {
    return DateTime.now().isBefore(expirationDate);
  }

  // Helper method to get time remaining

  String _getTimeRemaining(DateTime expirationDate) {
    final now = DateTime.now();

    final difference = expirationDate.difference(now);

    if (difference.isNegative) return 'Expired';

    final days = difference.inDays;

    final hours = difference.inHours % 24;

    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${difference.inMinutes}m';
    }
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

  // Helper method to build date row

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
          padding: EdgeInsets.all(8),

          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),

            borderRadius: BorderRadius.circular(8),
          ),

          child: Icon(icon, color: color, size: 20),
        ),

        SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                label,

                style: TextStyle(
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

  // Helper method to build benefit item

  Widget _buildBenefitItem(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),

      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 16),

          SizedBox(width: 8),

          Expanded(
            child: Text(
              text,

              style: TextStyle(
                color: Colors.white,

                fontSize: 12,

                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build stat item

  Widget _buildStatItem(
    String label,

    String value,

    IconData icon,

    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),

        SizedBox(height: 8),

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

          style: TextStyle(
            color: Colors.white70,

            fontSize: 11,

            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Helper method to get days used

  int _getDaysUsed(DateTime startDate) {
    final now = DateTime.now();

    final difference = now.difference(startDate);

    return difference.inDays;
  }

  // Helper method to get days left

  int _getDaysLeft(DateTime expirationDate) {
    final now = DateTime.now();

    final difference = expirationDate.difference(now);

    return difference.isNegative ? 0 : difference.inDays;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.black,

        child: ListView(
          padding: EdgeInsets.zero,

          children: [
            SizedBox(height: 80),

            ValueListenableBuilder<ProfileData>(
              valueListenable: profileNotifier,

              builder:
                  (context, profile, _) => Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (context) => ProfilePage(),
                            ),
                          );
                        },

                        child: CircleAvatar(
                          radius: 60,

                          backgroundColor: const Color.fromARGB(
                            59,

                            170,

                            170,

                            170,
                          ),

                          backgroundImage:
                              profile.imageFile != null
                                  ? FileImage(profile.imageFile!)
                                  : null,

                          child:
                              profile.imageFile == null
                                  ? Icon(
                                    Icons.person,

                                    color: Colors.white,

                                    size: 60,
                                  )
                                  : null,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Text(
                        ('${profile.firstName} ${profile.middleName} ${profile.lastName}')
                                .trim()
                                .isNotEmpty
                            ? ('${profile.firstName} ${profile.middleName} ${profile.lastName}')
                                .trim()
                            : 'Guest',

                        style: TextStyle(
                          color: Colors.white,

                          fontSize: 22,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 20),
                    ],
                  ),
            ),

            _DrawerNavItem(
              icon: Icons.home,

              label: 'Home',

              onTap: () {
                Navigator.pop(context);

                _scrollController.animateTo(
                  0.0,

                  duration: const Duration(milliseconds: 500),

                  curve: Curves.easeInOut,
                );
              },
            ),

            _DrawerNavItem(
              icon: Icons.fitness_center,

              label: 'Gym Equipment',

              onTap: () {
                Navigator.pop(context);

                _scrollToSection(1);
              },
            ),

            _DrawerNavItem(
              icon: Icons.card_membership,

              label: 'Services',

              onTap: () {
                Navigator.pop(context);

                _scrollToSection(2);
              },
            ),

            _DrawerNavItem(
              icon: Icons.shopping_cart,

              label: 'Products',

              onTap: () {
                Navigator.pop(context);

                _scrollToSection(3);
              },
            ),

            _DrawerNavItem(
              icon: Icons.person,

              label: 'Trainers',

              onTap: () {
                Navigator.pop(context);

                _scrollToSection(5);
              },
            ),

            _DrawerNavItem(
              icon: Icons.info_outline,

              label: 'About Us',

              onTap: () {
                Navigator.pop(context);

                _scrollToSection(5);
              },
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Container(
            color: Colors.black,

            child: SafeArea(
              child: BlackHeader(
                onNavTap: _scrollToSection,

                onProfileTap: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                },
              ),
            ),
          ),

          Expanded(
            child: Stack(
              fit: StackFit.expand,

              children: [
                Opacity(
                  opacity: 1.0,

                  child: Image.asset(
                    'assets/images/gym_view/BACK VIEW OF GYM 2.jpg',

                    fit: BoxFit.cover,
                  ),
                ),

                Container(color: Colors.black.withAlpha((0.4 * 255).toInt())),

                SafeArea(
                  child: SingleChildScrollView(
                    controller: _scrollController,

                    physics: const BouncingScrollPhysics(),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Container(
                          width: double.infinity,

                          padding: EdgeInsets.symmetric(
                            horizontal:
                                isSmallScreen ? 20.0 : screenSize.width * 0.1,

                            vertical: screenSize.height * 0.06,
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,

                            children: [
                              // Animated Hero Title
                              AnimatedBuilder(
                                animation: _heroAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 0.8 + (0.2 * _heroAnimation.value),
                                    child: FadeTransition(
                                      opacity: _heroAnimation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.5),
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: _heroController,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                        child: Text(
                                          'Welcome to RNR FITNESS GYM',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize:
                                                (isSmallScreen
                                                    ? (screenSize.width * 0.10)
                                                        .clamp(28.0, 38.0)
                                                    : (screenSize.width * 0.06)
                                                        .clamp(32.0, 48.0)),
                                            fontWeight: FontWeight.w900,
                                            height: 1.1,
                                            letterSpacing: 1.2,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.5,
                                                ),
                                                offset: const Offset(0, 2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              SizedBox(height: screenSize.height * 0.03),

                              SizedBox(height: screenSize.height * 0.02),

                              // Conditional content based on login status
                              AnimatedBuilder(
                                animation: authState,

                                builder: (context, child) {
                                  if (authState.isLoggedIn) {
                                    // Show membership information when logged in

                                    return Column(
                                      children: [
                                        Text(
                                          'Welcome back, ${authState.customerName ?? 'Member'}!',

                                          style: TextStyle(
                                            color: Colors.white,

                                            fontSize:
                                                (isSmallScreen
                                                    ? (screenSize.width * 0.048)
                                                        .clamp(15.0, 22.0)
                                                    : (screenSize.width * 0.032)
                                                        .clamp(16.0, 26.0)),

                                            fontWeight: FontWeight.w700,

                                            height: 1.5,
                                          ),
                                        ),

                                        SizedBox(
                                          height: screenSize.height * 0.02,
                                        ),

                                        if (authState.membershipData !=
                                            null) ...[
                                          Container(
                                            width: double.infinity,

                                            constraints: BoxConstraints(
                                              maxWidth:
                                                  isSmallScreen ? 320 : 400,
                                            ),

                                            padding: EdgeInsets.all(20),

                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,

                                                end: Alignment.bottomRight,

                                                colors: [
                                                  Colors.black87.withValues(
                                                    alpha: 0.9,
                                                  ),

                                                  Colors.blueGrey.withValues(
                                                    alpha: 0.8,
                                                  ),

                                                  Colors.black87.withValues(
                                                    alpha: 0.9,
                                                  ),
                                                ],
                                              ),

                                              borderRadius:
                                                  BorderRadius.circular(16),

                                              border: Border.all(
                                                color:
                                                    _isMembershipActive(
                                                          authState
                                                              .membershipData!
                                                              .expirationDate,
                                                        )
                                                        ? Colors.green
                                                            .withValues(
                                                              alpha: 0.6,
                                                            )
                                                        : Colors.red.withValues(
                                                          alpha: 0.6,
                                                        ),

                                                width: 2,
                                              ),

                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      _isMembershipActive(
                                                            authState
                                                                .membershipData!
                                                                .expirationDate,
                                                          )
                                                          ? Colors.green
                                                              .withValues(
                                                                alpha: 0.3,
                                                              )
                                                          : Colors.red
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),

                                                  blurRadius: 15,

                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),

                                            child: Column(
                                              children: [
                                                // Header with membership type and status
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,

                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        '${authState.membershipData!.membershipType} Membership',

                                                        style: TextStyle(
                                                          color:
                                                              Colors
                                                                  .lightBlueAccent,

                                                          fontSize:
                                                              (isSmallScreen
                                                                  ? (screenSize
                                                                              .width *
                                                                          0.045)
                                                                      .clamp(
                                                                        16.0,

                                                                        22.0,
                                                                      )
                                                                  : (screenSize
                                                                              .width *
                                                                          0.03)
                                                                      .clamp(
                                                                        18.0,

                                                                        26.0,
                                                                      )),

                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),

                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 12,

                                                            vertical: 6,
                                                          ),

                                                      decoration: BoxDecoration(
                                                        color:
                                                            _isMembershipActive(
                                                                  authState
                                                                      .membershipData!
                                                                      .expirationDate,
                                                                )
                                                                ? Colors.green
                                                                    .withValues(
                                                                      alpha:
                                                                          0.9,
                                                                    )
                                                                : Colors.red
                                                                    .withValues(
                                                                      alpha:
                                                                          0.9,
                                                                    ),

                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),

                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: (_isMembershipActive(
                                                                      authState
                                                                          .membershipData!
                                                                          .expirationDate,
                                                                    )
                                                                    ? Colors
                                                                        .green
                                                                    : Colors
                                                                        .red)
                                                                .withValues(
                                                                  alpha: 0.4,
                                                                ),

                                                            blurRadius: 8,

                                                            spreadRadius: 1,
                                                          ),
                                                        ],
                                                      ),

                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,

                                                        children: [
                                                          Icon(
                                                            _isMembershipActive(
                                                                  authState
                                                                      .membershipData!
                                                                      .expirationDate,
                                                                )
                                                                ? Icons
                                                                    .check_circle
                                                                : Icons.warning,

                                                            color: Colors.white,

                                                            size: 16,
                                                          ),

                                                          SizedBox(width: 6),

                                                          Text(
                                                            _isMembershipActive(
                                                                  authState
                                                                      .membershipData!
                                                                      .expirationDate,
                                                                )
                                                                ? 'Active'
                                                                : 'Expired',

                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,

                                                              fontSize: 12,

                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                SizedBox(height: 16),

                                                // Progress bar showing time remaining
                                                if (_isMembershipActive(
                                                  authState
                                                      .membershipData!
                                                      .expirationDate,
                                                )) ...[
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,

                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,

                                                        children: [
                                                          Text(
                                                            'Time Remaining',

                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white70,

                                                              fontSize: 12,

                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),

                                                          Text(
                                                            _getTimeRemaining(
                                                              authState
                                                                  .membershipData!
                                                                  .expirationDate,
                                                            ),

                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .lightBlueAccent,

                                                              fontSize: 12,

                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      SizedBox(height: 8),

                                                      LinearProgressIndicator(
                                                        value: _getMembershipProgress(
                                                          authState
                                                              .membershipData!
                                                              .startDate,

                                                          authState
                                                              .membershipData!
                                                              .expirationDate,
                                                        ),

                                                        backgroundColor: Colors
                                                            .white
                                                            .withValues(
                                                              alpha: 0.8,
                                                            ),

                                                        valueColor: AlwaysStoppedAnimation<
                                                          Color
                                                        >(
                                                          _getMembershipProgress(
                                                                    authState
                                                                        .membershipData!
                                                                        .startDate,

                                                                    authState
                                                                        .membershipData!
                                                                        .expirationDate,
                                                                  ) >
                                                                  0.7
                                                              ? Colors.orange
                                                              : Colors.green,
                                                        ),

                                                        minHeight: 6,

                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              3,
                                                            ),
                                                      ),
                                                    ],
                                                  ),

                                                  SizedBox(height: 16),
                                                ],

                                                // Dates section
                                                Container(
                                                  padding: EdgeInsets.all(16),

                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.1),

                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),

                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),

                                                      width: 1,
                                                    ),
                                                  ),

                                                  child: Column(
                                                    children: [
                                                      _buildDateRow(
                                                        'Start Date',

                                                        _formatDate(
                                                          authState
                                                              .membershipData!
                                                              .startDate,
                                                        ),

                                                        Icons.calendar_today,

                                                        Colors.green,

                                                        isSmallScreen,

                                                        screenSize,
                                                      ),

                                                      SizedBox(height: 12),

                                                      _buildDateRow(
                                                        'Expires',

                                                        _formatDate(
                                                          authState
                                                              .membershipData!
                                                              .expirationDate,
                                                        ),

                                                        Icons.event_busy,

                                                        Colors.orange,

                                                        isSmallScreen,

                                                        screenSize,
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                SizedBox(height: 16),

                                                // Membership statistics
                                                if (_isMembershipActive(
                                                  authState
                                                      .membershipData!
                                                      .expirationDate,
                                                )) ...[
                                                  Container(
                                                    padding: EdgeInsets.all(16),

                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),

                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),

                                                      border: Border.all(
                                                        color: Colors.green
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),

                                                        width: 1,
                                                      ),
                                                    ),

                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: _buildStatItem(
                                                            'Days Used',

                                                            '${_getDaysUsed(authState.membershipData!.startDate)}',

                                                            Icons.timer,

                                                            Colors.green,
                                                          ),
                                                        ),

                                                        Expanded(
                                                          child: _buildStatItem(
                                                            'Days Left',

                                                            '${_getDaysLeft(authState.membershipData!.expirationDate)}',

                                                            Icons.schedule,

                                                            Colors.orange,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  SizedBox(height: 16),
                                                ],

                                                // Membership benefits
                                                Container(
                                                  padding: EdgeInsets.all(16),

                                                  decoration: BoxDecoration(
                                                    color: Colors.blue
                                                        .withValues(alpha: 0.1),

                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),

                                                    border: Border.all(
                                                      color: Colors.blue
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),

                                                      width: 1,
                                                    ),
                                                  ),

                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,

                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.star,

                                                            color: Colors.amber,

                                                            size: 20,
                                                          ),

                                                          SizedBox(width: 8),

                                                          Text(
                                                            'Membership Benefits',

                                                            style: TextStyle(
                                                              color:
                                                                  Colors.amber,

                                                              fontSize: 14,

                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      SizedBox(height: 12),

                                                      _buildBenefitItem(
                                                        'Access to all gym equipment',

                                                        Icons.fitness_center,
                                                      ),

                                                      _buildBenefitItem(
                                                        'Group fitness classes',

                                                        Icons.group,
                                                      ),

                                                      _buildBenefitItem(
                                                        'Locker room access',

                                                        Icons.lock,
                                                      ),

                                                      _buildBenefitItem(
                                                        'Free Wi-Fi',

                                                        Icons.wifi,
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                SizedBox(height: 16),
                                              ],
                                            ),
                                          ),
                                        ] else ...[
                                          Text(
                                            'Loading membership details...',

                                            style: TextStyle(
                                              color: Colors.white70,

                                              fontSize:
                                                  (isSmallScreen
                                                      ? (screenSize.width *
                                                              0.035)
                                                          .clamp(12.0, 18.0)
                                                      : (screenSize.width *
                                                              0.024)
                                                          .clamp(14.0, 22.0)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  } else {
                                    // Show login prompt when not logged in

                                    return Column(
                                      children: [
                                        Text(
                                          'Login to Track your Membership',

                                          style: TextStyle(
                                            color: Colors.white,

                                            fontSize:
                                                (isSmallScreen
                                                    ? (screenSize.width * 0.048)
                                                        .clamp(15.0, 22.0)
                                                    : (screenSize.width * 0.032)
                                                        .clamp(16.0, 26.0)),

                                            fontWeight: FontWeight.w500,

                                            height: 1.5,
                                          ),
                                        ),

                                        SizedBox(
                                          height: screenSize.height * 0.012,
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenSize.height * 0.06),

                        EquipmentImagesSection(
                          key: _equipmentImagesKey,

                          isSmallScreen: isSmallScreen,

                          screenWidth: screenSize.width,

                          screenHeight: screenSize.height,
                        ),

                        SizedBox(height: screenSize.height * 0.06),

                        ServicesSection(
                          key: _servicesKey,

                          isSmallScreen: isSmallScreen,

                          screenWidth: screenSize.width,

                          screenHeight: screenSize.height,
                        ),

                        SizedBox(height: screenSize.height * 0.06),

                        ProductsSection(
                          key: _productsKey,

                          isSmallScreen: isSmallScreen,

                          screenWidth: screenSize.width,

                          screenHeight: screenSize.height,
                        ),

                        SizedBox(height: screenSize.height * 0.06),

                        TrainersSection(
                          key: _trainersKey,

                          isSmallScreen: isSmallScreen,

                          screenWidth: screenSize.width,
                        ),

                        SizedBox(height: screenSize.height * 0.06),

                        Footer(
                          isSmallScreen: isSmallScreen,

                          screenWidth: screenSize.width,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  final IconData icon;

  final String label;

  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.icon,

    required this.label,

    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),

      title: Text(
        label,

        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),

      onTap: onTap,
    );
  }
}
