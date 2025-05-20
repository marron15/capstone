import 'package:flutter/material.dart';
import 'sidenav/header.dart';
import 'equipment_images.dart';
import 'services.dart';
import 'products.dart';
import 'plans.dart';
import 'trainers.dart';
import 'modals/signup_modal.dart';
import '../footer.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _equipmentImagesKey = GlobalKey();
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _productsKey = GlobalKey();
  final GlobalKey _plansKey = GlobalKey();
  final GlobalKey _trainersKey = GlobalKey();

  void _scrollToSection(int index) {
    final contextList = [
      _equipmentImagesKey.currentContext,
      _servicesKey.currentContext,
      _productsKey.currentContext,
      _plansKey.currentContext,
      _trainersKey.currentContext,
    ];
    if (index >= 0 && index < contextList.length) {
      final ctx = contextList[index];
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
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
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withAlpha((0.1 * 255).toInt()),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'RNR Fitness Gym',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
              icon: Icons.school,
              label: 'Programs',
              onTap: () {
                Navigator.pop(context);
                _scrollToSection(0);
              },
            ),
            _DrawerNavItem(
              icon: Icons.card_membership,
              label: 'Membership',
              onTap: () {
                Navigator.pop(context);
                _scrollToSection(3);
              },
            ),
            _DrawerNavItem(
              icon: Icons.info_outline,
              label: 'About Us',
              onTap: () {
                Navigator.pop(context);
                _scrollToSection(4);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.black,
            child: SafeArea(child: BlackHeader(onNavTap: _scrollToSection)),
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
                Container(color: Colors.black.withAlpha((0.7 * 255).toInt())),
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
                              Text(
                                'Welcome to RNR FITNESS GYM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      (isSmallScreen
                                          ? (screenSize.width * 0.10).clamp(
                                            28.0,
                                            38.0,
                                          )
                                          : (screenSize.width * 0.06).clamp(
                                            32.0,
                                            48.0,
                                          )),
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.03),
                              Text(
                                'Do you want to get Gym Membership?\nClick Get Started now!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      (isSmallScreen
                                          ? (screenSize.width * 0.048).clamp(
                                            15.0,
                                            22.0,
                                          )
                                          : (screenSize.width * 0.032).clamp(
                                            16.0,
                                            26.0,
                                          )),
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.012),
                              SizedBox(height: screenSize.height * 0.04),
                              SizedBox(
                                width: (isSmallScreen
                                        ? screenSize.width * 0.7
                                        : screenSize.width * 0.3)
                                    .clamp(180.0, 340.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => const SignUpModal(),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black87,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: (screenSize.width * 0.04)
                                          .clamp(16.0, 32.0),
                                      vertical: (screenSize.height * 0.025)
                                          .clamp(10.0, 22.0),
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: (isSmallScreen
                                              ? screenSize.width * 0.055
                                              : screenSize.width * 0.035)
                                          .clamp(16.0, 28.0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: const Text('Get Started'),
                                ),
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
                        PlansSection(
                          key: _plansKey,
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
