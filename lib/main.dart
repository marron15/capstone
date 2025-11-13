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
import 'services/unified_auth_state.dart';
import 'services/auth_guard.dart';
import 'User Profile/profile.dart';
import 'services/pwa_service.dart';

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
                  return const LandingPage();
                } else if (unifiedAuthState.isAdminLoggedIn) {
                  return const AdminProfilePage();
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
        '/admin-products':
            (context) => const AdminAuthGuard(child: AdminProductsPage()),
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fullscreen background slideshow
          const _BackgroundSlideshow(
            imagePaths: [
              'assets/images/gym_view/front_view.jpg',
              'assets/images/gym_view/back_view.jpg',
            ],
          ),
          // Lightened gradient overlay: white tint to transparent (no dark tint)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withAlpha((0.08 * 255).toInt()),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Content container on top of background
          Container(
            color: Colors.transparent,
            child: SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hero heading and subheading
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: const [
                                Text(
                                  "Greetings, Welcome to RNR Fitness Gym!",
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Color(0xCC000000),
                                        offset: Offset(0, 2),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 15),
                                Text(
                                  'Access memberships, trainers, and services.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Color(0xCC000000),
                                        offset: Offset(0, 1.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 68),

                        // Choice containers responsive layout
                        AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        // Keep two columns when space allows
                                        const double gap = 40;
                                        final double maxWidth =
                                            constraints.maxWidth;
                                        final double twoColWidth =
                                            (maxWidth - gap) / 2;
                                        final bool forceSingleColumn =
                                            maxWidth < 300;
                                        final double cardWidth =
                                            forceSingleColumn
                                                ? maxWidth
                                                : twoColWidth.clamp(150, 210);
                                        return Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: gap,
                                          runSpacing: 30,
                                          children: [
                                            SizedBox(
                                              width: cardWidth,
                                              child: _ChoiceContainer(
                                                onTap: () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/customer-landing',
                                                  );
                                                },
                                                icon: Icons.person_outline,
                                                title: 'Are you Customer?',
                                                subtitle:
                                                    'Access gym services and membership',
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF36454F),
                                                    Color(0xFF111111),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                textColor: Colors.white,
                                                iconColor: Colors.white,
                                                subtitleColor: Colors.white,
                                              ),
                                            ),
                                            SizedBox(
                                              width: cardWidth,
                                              child: _ChoiceContainer(
                                                onTap: () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/admin-login',
                                                  );
                                                },
                                                icon:
                                                    Icons
                                                        .admin_panel_settings_outlined,
                                                title: 'Are you Admin?',
                                                subtitle:
                                                    'Manage gym operations and members',
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF36454F),
                                                    Color(0xFF111111),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                textColor: Colors.white,
                                                iconColor: Colors.white,
                                                subtitleColor: Colors.white,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 50),

                        // Benefits row (wraps on small screens)
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 18,
                              runSpacing: 12,
                              children: const [
                                _BenefitChip(
                                  icon: Icons.water_drop,
                                  label: 'Free Water',
                                ),
                                _BenefitChip(
                                  icon: Icons.fitness_center,
                                  label: 'Quality Equipment',
                                ),
                                _BenefitChip(
                                  icon: Icons.people,
                                  label: 'Welcoming Environment',
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Lead capture removed
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Header bar with left-aligned logo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255,
                    0,
                    0,
                    0,
                  ).withAlpha((0.92 * 255).toInt()),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.25 * 255).toInt()),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      const Text(
                        'RNR Fitness Gym',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      // PWA Install Button
                      PwaService.buildInstallButton(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Background slideshow replaces side images
        ],
      ),
    );
  }

  // Legacy builder removed; _ChoiceContainer is used directly
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
