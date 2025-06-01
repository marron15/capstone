import 'package:flutter/material.dart';
import 'header.dart';
import 'equipment_images.dart';
import 'add_ons.dart';
import 'products.dart';
import 'plans.dart';
import 'trainers.dart';
import '../modals/signup_modal.dart';
import 'footer.dart';
import '../User Profile/profile.dart';
import '../User Profile/profile_data.dart';

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
              icon: Icons.school,
              label: 'Programs',
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
                        PlansSection(
                          key: _plansKey,
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
