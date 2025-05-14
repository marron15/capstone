import 'package:flutter/material.dart';
import 'header.dart';
import 'equipment_images.dart';
import 'services.dart';
import 'products.dart';
import 'plans.dart';
import 'trainers.dart';
import 'modals/signup_modal.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      body: Column(
        children: [
          const BlackHeader(),
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
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 20.0 : screenSize.width * 0.1,
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
                              Text(
                                '\nBusiness Hours: 11:00AM - 9:00PM',
                                style: TextStyle(
                                  color: Colors.white.withAlpha((0.9 * 255).toInt()),
                                  fontSize:
                                      (isSmallScreen
                                          ? (screenSize.width * 0.045).clamp(
                                            13.0,
                                            20.0,
                                          )
                                          : (screenSize.width * 0.03).clamp(
                                            14.0,
                                            22.0,
                                          )),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                'Monday to Saturday',
                                style: TextStyle(
                                  color: Colors.white.withAlpha((0.9 * 255).toInt()),
                                  fontSize:
                                      (isSmallScreen
                                          ? (screenSize.width * 0.045).clamp(
                                            13.0,
                                            20.0,
                                          )
                                          : (screenSize.width * 0.03).clamp(
                                            14.0,
                                            22.0,
                                          )),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.04),
                              SizedBox(
                                width: (isSmallScreen
                                        ? screenSize.width * 0.7
                                        : screenSize.width * 0.3)
                                    .clamp(180.0, 340.0),
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black87,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: (screenSize.width * 0.04).clamp(
                                        16.0,
                                        32.0,
                                      ),
                                      vertical: (screenSize.height * 0.025).clamp(
                                        10.0,
                                        22.0,
                                      ),
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
                                  child: Text('Get Started'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenSize.height * 0.06),
                        EquipmentImagesSection(
                          isSmallScreen: isSmallScreen,
                          screenWidth: screenSize.width,
                          screenHeight: screenSize.height,
                        ),
                        SizedBox(height: screenSize.height * 0.06),
                        ServicesSection(
                          isSmallScreen: isSmallScreen,
                          screenWidth: screenSize.width,
                          screenHeight: screenSize.height,
                        ),
                        SizedBox(height: screenSize.height * 0.06),
                        ProductsSection(
                          isSmallScreen: isSmallScreen,
                          screenWidth: screenSize.width,
                          screenHeight: screenSize.height,
                        ),
                        SizedBox(height: screenSize.height * 0.06),
                        PlansSection(
                          isSmallScreen: isSmallScreen,
                          screenWidth: screenSize.width,
                          screenHeight: screenSize.height,
                        ),
                        SizedBox(height: screenSize.height * 0.06),
                        TrainersSection(
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

class Footer extends StatelessWidget {
  final bool isSmallScreen;
  final double screenWidth;
  const Footer({
    Key? key,
    required this.isSmallScreen,
    required this.screenWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: EdgeInsets.symmetric(
        vertical: 32.0,
        horizontal: isSmallScreen ? 16.0 : screenWidth * 0.1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/RNR1.png',
                width: isSmallScreen ? 60 : 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),
              const Text(
                'FITNESS GYM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            '875 RIZAL AVENUE WEST TAPINAC , OLONGAPO CITY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
