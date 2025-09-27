import 'package:flutter/material.dart';
import 'unified_auth_state.dart';

/// Authentication guard widget that protects routes requiring authentication
/// Redirects unauthenticated users to the login page
class AuthGuard extends StatelessWidget {
  final Widget child;
  final UserType requiredUserType;
  final String? redirectRoute;

  const AuthGuard({
    Key? key,
    required this.child,
    required this.requiredUserType,
    this.redirectRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: unifiedAuthState,
      builder: (context, _) {
        // Show loading screen while auth state is initializing
        if (!unifiedAuthState.isInitialized) {
          return const _LoadingScreen();
        }

        // Check if user is logged in and has the required user type
        if (!unifiedAuthState.isLoggedIn ||
            unifiedAuthState.userType != requiredUserType) {
          // Redirect to appropriate login page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _redirectToLogin(context);
          });

          // Show loading while redirecting
          return const _LoadingScreen();
        }

        // User is authenticated and has correct user type
        return child;
      },
    );
  }

  void _redirectToLogin(BuildContext context) {
    // Determine the appropriate login route based on required user type
    String loginRoute;
    switch (requiredUserType) {
      case UserType.admin:
        loginRoute = '/admin-login';
        break;
      case UserType.customer:
        loginRoute = '/';
        break;
      case UserType.none:
        loginRoute = '/';
        break;
    }

    // Use the provided redirect route or the default login route
    final targetRoute = redirectRoute ?? loginRoute;

    // Navigate to login page and clear the navigation stack
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(targetRoute, (route) => false);
  }
}

/// Admin-specific authentication guard
class AdminAuthGuard extends StatelessWidget {
  final Widget child;

  const AdminAuthGuard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthGuard(requiredUserType: UserType.admin, child: child);
  }
}

/// Customer-specific authentication guard
class CustomerAuthGuard extends StatelessWidget {
  final Widget child;

  const CustomerAuthGuard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthGuard(requiredUserType: UserType.customer, child: child);
  }
}

/// Loading screen shown during authentication checks
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
                'Verifying access...',
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
