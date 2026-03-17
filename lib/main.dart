import 'dart:async';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'landing_page_components/landing_page.dart';
import 'admin/login.dart';
import 'admin/dashboard/admin_profile.dart';
import 'admin/dashboard/home.dart';
import 'admin/dashboard/trainers.dart';
import 'admin/dashboard/customers.dart';
import 'admin/dashboard/admin_products.dart';
import 'admin/dashboard/attendance_log.dart';
import 'admin/dashboard/audit_logs.dart';
import 'services/unified_auth_state.dart';
import 'services/auth_guard.dart';
import 'services/attendance_service.dart';
import 'User Profile/profile.dart';
import 'landing_page_modals/login.dart';
import 'landing_page_modals/signup_members.dart';
import 'services/apk_download_button.dart';
import 'landing_page_components/footer.dart';
import 'landing_page_components/add_ons.dart';
import 'landing_page_components/products.dart';
import 'landing_page_components/trainers.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize auth state from stored tokens
  await unifiedAuthState.initializeFromStorage();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RNR Fitness Gym',
      theme: _buildTheme(),
      initialRoute: '/home',
      navigatorKey: navigatorKey,
      routes: {
        '/':
            (context) => AnimatedBuilder(
              animation: unifiedAuthState,
              builder: (context, child) {
                if (!unifiedAuthState.isInitialized) {
                  return const _LoadingScreen();
                }

                if (unifiedAuthState.isCustomerLoggedIn) {
                  return const LoginChoicePage();
                } else if (unifiedAuthState.isAdminLoggedIn) {
                  return const AdminAuthGuard(child: StatisticPage());
                } else {
                  return const LoginChoicePage();
                }
              },
            ),
        '/admin-login': (context) => const LoginPage(checkLoginStatus: false),
        '/home': (context) => const LoginChoicePage(),
        '/customer-landing': (context) => const LandingPage(),
        '/Home-Page': (context) => const LandingPage(),
        '/admin-dashboard':
            (context) => const AdminAuthGuard(child: AdminProfilePage()),
        '/admin-statistics':
            (context) => const AdminAuthGuard(child: StatisticPage()),
        '/admin-trainers':
            (context) => const AdminAuthGuard(child: TrainersPage()),
        '/admin-customers':
            (context) => const AdminAuthGuard(child: CustomersPage()),
        '/admin-attendance':
            (context) => const AdminAuthGuard(child: AttendanceLogPage()),
        '/admin-products':
            (context) => const AdminAuthGuard(child: AdminProductsPage()),
        '/admin-audit-logs':
            (context) => const AdminAuthGuard(child: AuditLogsPage()),
        '/customer-profile':
            (context) => CustomerAuthGuard(child: ProfilePage()),
      },
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _LoadingScreen extends StatefulWidget {
  const _LoadingScreen({Key? key}) : super(key: key);

  @override
  State<_LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<_LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298), Color(0xFF8B5CF6)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Colors.white, Color(0xFF64B5F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'RNR Fitness',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Loading your fitness journey...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginChoicePage extends StatefulWidget {
  const LoginChoicePage({Key? key}) : super(key: key);

  @override
  State<LoginChoicePage> createState() => _LoginChoicePageState();
}

class _LoginChoicePageState extends State<LoginChoicePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    // Listen for PWA install events if running on web
    if (kIsWeb) {
      // Event listeners are handled by JavaScript in index.html
      // The service worker and PWA install functionality will work automatically
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Hero Section
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/gym_view/2.jpg',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.black.withValues(alpha: 0.8),
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                          SafeArea(
                            child: AnimatedBuilder(
                              animation: unifiedAuthState,
                              builder: (context, child) {
                                return Align(
                                  alignment: unifiedAuthState.isCustomerLoggedIn 
                                      ? Alignment.center 
                                      : Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: MediaQuery.of(context).size.width < 600 ? 20 : 80,
                                      right: MediaQuery.of(context).size.width < 600 ? 20 : 80,
                                      top: unifiedAuthState.isCustomerLoggedIn ? 80 : 0, // Extra padding to avoid header overlap
                                    ),
                                    child: unifiedAuthState.isCustomerLoggedIn
                                        ? const SingleChildScrollView(child: HeroMembershipContainer())
                                        : Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'We Are Best Powerful\nSport Nutrition',
                                              style: TextStyle(
                                                fontSize: MediaQuery.of(context).size.width < 600 ? 36 : 64,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                height: 1.1,
                                                letterSpacing: -1.0,
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Text(
                                              'The goal is to provide value, build a community, and showcase\nhost live Q&A sessions, and post about seasonal themes .',
                                              style: TextStyle(
                                                fontSize: MediaQuery.of(context).size.width < 600 ? 16 : 18,
                                                color: Colors.white.withValues(alpha: 0.85),
                                                height: 1.5,
                                              ),
                                            ),
                                            const SizedBox(height: 40),
                                            Row(
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => const SignupMembersModal(),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF3B5998),
                                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                  ),
                                                  child: const Text('Sign Up', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                                                ),
                                                const SizedBox(width: 20),
                                                OutlinedButton(
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => const SignupMembersModal(),
                                                    );
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    side: const BorderSide(color: Colors.white, width: 2),
                                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                  ),
                                                  child: const Text('Register Now', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ) // ends Column
                                  ), // ends Padding
                                ); // ends Align
                              }, // ends builder
                            ), // ends AnimatedBuilder
                          ), // ends SafeArea
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),

                        EquipmentImagesSection(
                          isSmallScreen:
                              MediaQuery.of(context).size.width < 600,
                          screenWidth: MediaQuery.of(context).size.width,
                          screenHeight: MediaQuery.of(context).size.height,
                        ),

                        const SizedBox(height: 50),

                        ServicesSection(
                          isSmallScreen:
                              MediaQuery.of(context).size.width < 600,
                          screenWidth: MediaQuery.of(context).size.width,
                          screenHeight: MediaQuery.of(context).size.height,
                        ),

                        const SizedBox(height: 50),

                        ProductsSection(
                          isSmallScreen:
                              MediaQuery.of(context).size.width < 600,
                          screenWidth: MediaQuery.of(context).size.width,
                          screenHeight: MediaQuery.of(context).size.height,
                        ),

                        const SizedBox(height: 50),

                        TrainersSection(
                          isSmallScreen:
                              MediaQuery.of(context).size.width < 600,
                          screenWidth: MediaQuery.of(context).size.width,
                        ),

                        const SizedBox(height: 50),

                        Footer(
                          isSmallScreen:
                              MediaQuery.of(context).size.width < 600,
                          screenWidth: MediaQuery.of(context).size.width,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          // Header bar with left-aligned logo
          const MainHeader(),
        ],
      ),
    );
  }

  // Legacy builder removed; _ChoiceContainer is used directly
}

class MainHeader extends StatelessWidget {
  const MainHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/RNR1.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
                const Spacer(),
                if (MediaQuery.of(context).size.width >= 900) ...[
                  _HeaderNavTextButton(label: 'Home', onTap: () {}),
                  _HeaderNavTextButton(label: 'About', onTap: () {}),
                  _HeaderNavTextButton(label: 'Service', onTap: () {}),
                  _HeaderNavTextButton(label: 'Trainer', onTap: () {}),
                  _HeaderNavTextButton(label: 'Review', onTap: () {}),
                  _HeaderNavTextButton(label: 'Blog', onTap: () {}),
                  _HeaderNavTextButton(label: 'Contact', onTap: () {}),
                  const Spacer(),
                ],
                AnimatedBuilder(
                  animation: unifiedAuthState,
                  builder: (context, child) {
                    if (unifiedAuthState.isCustomerLoggedIn) {
                      return ElevatedButton(
                        onPressed: () async {
                          await unifiedAuthState.logout();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logged out successfully')),
                            );
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Logout',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const SignupMembersModal(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            side: const BorderSide(color: Colors.white70, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const LoginModal(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 10),
                const ApkDownloadButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// (Removed unused _SideImage widget)

class _SideSlideshow extends StatefulWidget {
  final List<String> imagePaths;
  final double width;
  final double height;

  const _SideSlideshow({
    required this.imagePaths,
    required this.width,
    required this.height,
  });

  @override
  State<_SideSlideshow> createState() => _SideSlideshowState();
}

class _SideSlideshowState extends State<_SideSlideshow>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Auto-rotate every 4 seconds
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      while (mounted) {
        await Future<void>.delayed(const Duration(seconds: 4));
        if (!mounted) break;
        _currentIndex = (_currentIndex + 1) % widget.imagePaths.length;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.18 * 255).toInt()),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.imagePaths.length,
            itemBuilder: (context, index) {
              return Image.asset(widget.imagePaths[index], fit: BoxFit.cover);
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.imagePaths.length, (i) {
            final bool isActive = i == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 12 : 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    isActive
                        ? Colors.black.withAlpha((0.7 * 255).toInt())
                        : Colors.black.withAlpha((0.35 * 255).toInt()),
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BenefitChip extends StatefulWidget {
  final IconData icon;
  final String label;

  const _BenefitChip({required this.icon, required this.label});

  @override
  State<_BenefitChip> createState() => _BenefitChipState();
}

class _BenefitChipState extends State<_BenefitChip> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxChipWidth = screenWidth * 0.9 - 32; // account for margins
    final Color hoverAccent = const Color(0xFFFFA812);
    final Color textColor = _isHovering ? hoverAccent : Colors.black87;
    final Color iconColor = Colors.black87; // Keep icon always black

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxChipWidth.clamp(140, 320)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.15 * 255).toInt()),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Full-screen background slideshow widget
class _BackgroundSlideshow extends StatefulWidget {
  final List<String> imagePaths;
  const _BackgroundSlideshow({required this.imagePaths});

  @override
  State<_BackgroundSlideshow> createState() => _BackgroundSlideshowState();
}

class _BackgroundSlideshowState extends State<_BackgroundSlideshow> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() async {
    while (mounted) {
      await Future<void>.delayed(const Duration(seconds: 4));
      if (!mounted) break;
      setState(() {
        _index = (_index + 1) % widget.imagePaths.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: Container(
        key: ValueKey(_index),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(widget.imagePaths[_index]),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}

// Hover-aware choice container that turns orange on hover
class _ChoiceContainer extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final Color textColor;
  final Color iconColor;
  final Color subtitleColor;

  const _ChoiceContainer({
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.textColor,
    required this.iconColor,
    required this.subtitleColor,
  });

  @override
  State<_ChoiceContainer> createState() => _ChoiceContainerState();
}

class _ChoiceContainerState extends State<_ChoiceContainer> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompact = screenWidth < 420;
    final double containerHeight = isCompact ? 220 : 280;
    final Color baseBg = Colors.black;
    final Color hoverAccent = const Color(0xFFFFA812);
    final Color backgroundColor = baseBg; // keep container black always
    final Color foregroundTextColor = _isHovering ? hoverAccent : Colors.white;
    final Color iconColor = Colors.white;
    final Color subtitleColor = Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          height: containerHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 3),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onTap,
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(isCompact ? 14 : 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.all(isCompact ? 10 : 12),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.icon,
                        color: iconColor,
                        size: isCompact ? 36 : 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isCompact ? 16 : 20,
                        fontWeight: FontWeight.w700,
                        color: foregroundTextColor,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        fontWeight: FontWeight.w400,
                        color: subtitleColor.withValues(alpha: 0.9),
                        letterSpacing: 0.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: (_isHovering ? hoverAccent : Colors.white)
                          .withValues(alpha: 0.9),
                      size: isCompact ? 14 : 16,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EquipmentImagesSection extends StatelessWidget {
  const EquipmentImagesSection({
    Key? key,
    required this.isSmallScreen,
    required this.screenWidth,
    required this.screenHeight,
  }) : super(key: key);

  final bool isSmallScreen;
  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Center(
            child: Text(
              'Equipments',
              style: TextStyle(
                color: Colors.white,
                fontSize: (isSmallScreen
                        ? screenWidth * 0.07
                        : screenWidth * 0.045)
                    .clamp(22.0, 48.0),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 20),
              _FlexibleEquipmentCard(
                imagePath: 'assets/images/gym_equipments/dumbells.jpg',
                title: 'Dumbbells',
                description: 'High quality dumbbells for strength training.',
              ),
              const SizedBox(width: 16),
              _FlexibleEquipmentCard(
                imagePath: 'assets/images/gym_equipments/bike.jpg',
                title: 'Exercise Bike',
                description: 'Cardio equipment for endurance.',
              ),
              const SizedBox(width: 16),
              _FlexibleEquipmentCard(
                imagePath: 'assets/images/gym_equipments/weights.jpg',
                title: 'Weights',
                description: 'Various weights for all levels.',
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _FlexibleEquipmentCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const _FlexibleEquipmentCard({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth < 900 ? screenWidth * 0.7 : 280;
    cardWidth = cardWidth.clamp(180.0, 320.0);
    return SizedBox(
      width: cardWidth,
      height: 320,
      child: _EquipmentCard(
        imagePath: imagePath,
        title: title,
        description: description,
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const _EquipmentCard({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              height: 320,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: double.infinity,
            height: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black.withAlpha((0.45 * 255).toInt()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderNavTextButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderNavTextButton({
    required this.label,
    required this.onTap,
  });

  @override
  State<_HeaderNavTextButton> createState() => _HeaderNavTextButtonState();
}

class _HeaderNavTextButtonState extends State<_HeaderNavTextButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final Color hoverAccent = const Color(0xFFFFA812);
    final Color textColor = _isHovering ? hoverAccent : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        child: TextButton(
          onPressed: widget.onTap,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

class _HeaderNavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_HeaderNavButton> createState() => _HeaderNavButtonState();
}

class _HeaderNavButtonState extends State<_HeaderNavButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final Color hoverAccent = const Color(0xFFFFA812);
    final Color textColor = _isHovering ? hoverAccent : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        child: TextButton.icon(
          onPressed: widget.onTap,
          icon: Icon(widget.icon, color: Colors.white, size: 20),
          label: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            style: TextStyle(color: textColor, fontSize: 16),
            child: Text(widget.label),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }
}


class HeroMembershipContainer extends StatefulWidget {
  const HeroMembershipContainer({Key? key}) : super(key: key);

  @override
  State<HeroMembershipContainer> createState() => _HeroMembershipContainerState();
}

class _HeroMembershipContainerState extends State<HeroMembershipContainer> {
  Timer? _countdownTimer;
  bool _isSubmittingScan = false;
  String? _scanErrorMessage;
  static const Duration _minimumSessionDuration = Duration(minutes: 30);

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

  // (Removed _buildBenefitItem; no longer used)

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

  Future<void> _startScanFlow() async {
    if (!unifiedAuthState.isCustomerLoggedIn) {
      _showScanError('Please login to scan the admin QR code.');
      return;
    }

    // Check if customer has an active membership
    final membershipData = unifiedAuthState.membershipData;
    if (membershipData == null) {
      _showScanError(
        'No membership found. Please contact the gym to activate your membership.',
      );
      return;
    }

    // Check if membership is expired
    if (!_isMembershipActive(membershipData.expirationDate)) {
      _showScanError(
        'Your membership has expired. Please renew your membership to use the QR code scanner.',
      );
      return;
    }

    final String? payload = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _QrScannerDialog(),
    );

    if (!mounted || payload == null || payload.isEmpty) return;
    await _recordAttendanceScan(payload);
  }

  Future<void> _recordAttendanceScan(String payload) async {
    final int? customerId = unifiedAuthState.customerId;
    if (customerId == null) return;

    // Double-check membership status before recording scan
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
        'You need at least 30 minutes between time-in and time-out. '
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

    if (_isSubmittingScan) return;

    setState(() {
      _isSubmittingScan = true;
      _scanErrorMessage = null;
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
        setState(() => _isSubmittingScan = false);
      }
    }
  }

  void _showScanError(String message) {
    if (!mounted) return;
    setState(() => _scanErrorMessage = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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


  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
return Column(
  mainAxisSize: MainAxisSize.min,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text(
      'Welcome back, ${unifiedAuthState.customerName ?? 'Member'}!',

      style: TextStyle(
        color: Colors.white,

        fontSize:
            (isSmallScreen
                ? (screenSize.width *
                        0.048)
                    .clamp(15.0, 22.0)
                : (screenSize.width *
                        0.032)
                    .clamp(
                      16.0,
                      26.0,
                    )),

        fontWeight: FontWeight.w700,

        height: 1.5,
      ),
    ),

    SizedBox(
      height:
          screenSize.height * 0.02,
    ),

    if (unifiedAuthState
            .membershipData !=
        null) ...[
      Container(
        width: double.infinity,

        constraints: BoxConstraints(
          maxWidth:
              isSmallScreen
                  ? 320
                  : 400,
        ),

        padding: EdgeInsets.all(20),

        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: [
              Colors.black.withValues(
                alpha: 0.60,
              ),
              Colors.black.withValues(
                alpha: 0.45,
              ),
            ],
          ),

          borderRadius:
              BorderRadius.circular(
                16,
              ),

          border: Border.all(
            color: Colors.white
                .withValues(
                  alpha: 0.22,
                ),
            width: 1.5,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(
                    alpha: 0.35,
                  ),
              blurRadius: 18,
              spreadRadius: 1,
              offset: Offset(0, 10),
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
                    '${unifiedAuthState.membershipData!.membershipType} Membership',

                    style: TextStyle(
                      color:
                          const Color(
                            0xFFFFA812,
                          ),

                      fontSize:
                          (isSmallScreen
                              ? (screenSize.width *
                                      0.045)
                                  .clamp(
                                    16.0,

                                    22.0,
                                  )
                              : (screenSize.width *
                                      0.03)
                                  .clamp(
                                    18.0,

                                    26.0,
                                  )),

                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),

                Container(
                  padding:
                      EdgeInsets.symmetric(
                        horizontal:
                            12,

                        vertical: 6,
                      ),

                  decoration: BoxDecoration(
                    color:
                        _isMembershipActive(
                              unifiedAuthState
                                  .membershipData!
                                  .expirationDate,
                            )
                            ? Colors
                                .green
                                .withValues(
                                  alpha:
                                      0.9,
                                )
                            : Colors
                                .red
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
                                  unifiedAuthState.membershipData!.expirationDate,
                                )
                                ? Colors
                                    .green
                                : Colors
                                    .red)
                            .withValues(
                              alpha:
                                  0.4,
                            ),

                        blurRadius: 8,

                        spreadRadius:
                            1,
                      ),
                    ],
                  ),

                  child: Row(
                    mainAxisSize:
                        MainAxisSize
                            .min,

                    children: [
                      Icon(
                        _isMembershipActive(
                              unifiedAuthState
                                  .membershipData!
                                  .expirationDate,
                            )
                            ? Icons
                                .check_circle
                            : Icons
                                .warning,

                        color:
                            Colors
                                .white,

                        size: 16,
                      ),

                      SizedBox(
                        width: 6,
                      ),

                      Text(
                        _isMembershipActive(
                              unifiedAuthState
                                  .membershipData!
                                  .expirationDate,
                            )
                            ? 'Active'
                            : 'Expired',

                        style: TextStyle(
                          color:
                              Colors
                                  .white,

                          fontSize:
                              12,

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
              unifiedAuthState
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

                          fontSize:
                              12,

                          fontWeight:
                              FontWeight
                                  .w500,
                        ),
                      ),

                      Text(
                        _getTimeRemaining(
                          unifiedAuthState
                              .membershipData!
                              .expirationDate,
                        ),

                        style: TextStyle(
                          color: const Color(
                            0xFFFFA812,
                          ),

                          fontSize:
                              12,

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
                      unifiedAuthState
                          .membershipData!
                          .startDate,

                      unifiedAuthState
                          .membershipData!
                          .expirationDate,
                    ),

                    backgroundColor:
                        Colors.white
                            .withValues(
                              alpha:
                                  0.8,
                            ),

                    valueColor:
                        AlwaysStoppedAnimation<
                          Color
                        >(
                          const Color(
                            0xFFFFA812,
                          ),
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
              padding: EdgeInsets.all(
                16,
              ),

              decoration: BoxDecoration(
                color: Colors.white
                    .withValues(
                      alpha: 0.1,
                    ),

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
                      unifiedAuthState
                          .membershipData!
                          .startDate,
                    ),

                    Icons
                        .calendar_today,

                    const Color(
                      0xFFFFA812,
                    ),

                    isSmallScreen,

                    screenSize,
                  ),

                  SizedBox(
                    height: 12,
                  ),

                  _buildDateRow(
                    'Expires',
                    unifiedAuthState
                                .membershipData!
                                .membershipType ==
                            'Daily'
                        ? _getTimeRemaining(
                          unifiedAuthState
                              .membershipData!
                              .expirationDate,
                        )
                        : _formatDate(
                          unifiedAuthState
                              .membershipData!
                              .expirationDate,
                        ),
                    Icons.event_busy,
                    const Color(
                      0xFFFFA812,
                    ),
                    isSmallScreen,
                    screenSize,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Membership statistics
            if (_isMembershipActive(
              unifiedAuthState
                  .membershipData!
                  .expirationDate,
            )) ...[
              Container(
                padding:
                    EdgeInsets.all(
                      16,
                    ),

                decoration: BoxDecoration(
                  color: const Color(
                    0xFFFFA812,
                  ).withValues(
                    alpha: 0.1,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                        12,
                      ),

                  border: Border.all(
                    color:
                        const Color(
                          0xFFFFA812,
                        ).withValues(
                          alpha: 0.25,
                        ),

                    width: 1,
                  ),
                ),

                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Days Used',

                        '${_getDaysUsed(unifiedAuthState.membershipData!.startDate)}',

                        Icons.timer,

                        const Color(
                          0xFFFFA812,
                        ),
                      ),
                    ),

                    Expanded(
                      child: _buildStatItem(
                        'Days Left',

                        '${_getDaysLeft(unifiedAuthState.membershipData!.expirationDate)}',

                        Icons
                            .schedule,

                        const Color(
                          0xFFFFA812,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),
            ],

            // Membership benefits
            Container(
              padding: EdgeInsets.all(
                16,
              ),

              decoration: BoxDecoration(
                color: Colors.black
                    .withValues(
                      alpha: 0.25,
                    ),

                borderRadius:
                    BorderRadius.circular(
                      12,
                    ),

                border: Border.all(
                  color: Colors.white
                      .withValues(
                        alpha: 0.15,
                      ),

                  width: 1,
                ),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  _buildAttendanceStatusContent(
                    unifiedAuthState
                        .attendanceSnapshot,
                    isSmallScreen,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Reserve Request Button
            AnimatedBuilder(
              animation:
                  unifiedAuthState,
              builder: (
                context,
                child,
              ) {
                if (!unifiedAuthState
                    .isCustomerLoggedIn) {
                  return const SizedBox.shrink();
                }

                // Check if membership is active for button state
                final bool
                isMembershipActive =
                    unifiedAuthState
                            .membershipData !=
                        null &&
                    _isMembershipActive(
                      unifiedAuthState
                          .membershipData!
                          .expirationDate,
                    );

                return Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
                  children: [
                    OutlinedButton(
                      onPressed:
                          (_isSubmittingScan ||
                                  !isMembershipActive)
                              ? null
                              : _startScanFlow,
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Colors
                                .white,
                        side: BorderSide(
                          color: const Color(
                            0xFFFFA812,
                          ).withValues(
                            alpha:
                                0.9,
                          ),
                          width: 1.4,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              isSmallScreen
                                  ? 16
                                  : 18,
                          vertical:
                              isSmallScreen
                                  ? 12
                                  : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                12,
                              ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          const Icon(
                            Icons
                                .qr_code_scanner,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            _isSubmittingScan
                                ? 'Processing...'
                                : (!isMembershipActive
                                    ? 'Membership Expired'
                                    : 'Scan Admin QR'),
                            style: TextStyle(
                              fontSize:
                                  isSmallScreen
                                      ? 14
                                      : 15,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          if (_isSubmittingScan) ...[
                            const SizedBox(
                              width:
                                  12,
                            ),
                            SizedBox(
                              width:
                                  16,
                              height:
                                  16,
                              child: const CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                valueColor: AlwaysStoppedAnimation<
                                  Color
                                >(
                                  Color(
                                    0xFFFFA812,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_scanErrorMessage !=
                        null) ...[
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        _scanErrorMessage!,
                        textAlign:
                            TextAlign
                                .center,
                        style: const TextStyle(
                          color:
                              Colors
                                  .redAccent,
                          fontSize:
                              12,
                        ),
                      ),
                    ],
                    const SizedBox(
                      height: 12,
                    ),
                  ],
                );
              },
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
                  ? (screenSize
                              .width *
                          0.035)
                      .clamp(
                        12.0,
                        18.0,
                      )
                  : (screenSize
                              .width *
                          0.024)
                      .clamp(
                        14.0,
                        22.0,
                      )),
        ),
      ),
    ],
  ],
);

  }
}

class _QrScannerDialog extends StatefulWidget {
  const _QrScannerDialog();

  @override
  State<_QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<_QrScannerDialog> {
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
                'Align the admin’s QR code inside the frame. On desktop, use the gallery icon to pick an image if your camera is unavailable.',
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

