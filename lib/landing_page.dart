import 'package:flutter/material.dart';
import 'sidenav.dart';
import 'equipment_images.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      drawer: const SideNav(),
      appBar: AppBar(
        title: const Text('RNR Fitness Gym'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 1.0,
            child: Image.asset(
              'assets/images/gym_view/BACK VIEW OF GYM 2.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.black.withAlpha((0.5 * 255).toInt()),
          ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to RNR FITNESS GYM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen 
                                ? screenSize.width * 0.08 
                                : screenSize.width * 0.05,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: screenSize.height * 0.025),
                        Text(
                          'Where every drop of sweat brings you closer to the best version of yourself!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen 
                                ? screenSize.width * 0.05 
                                : screenSize.width * 0.035,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: screenSize.height * 0.045),
                        SizedBox(
                          width: isSmallScreen 
                              ? screenSize.width * 0.6 
                              : screenSize.width * 0.3,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenSize.width * 0.04,
                                vertical: screenSize.height * 0.025,
                              ),
                              textStyle: TextStyle(
                                fontSize: isSmallScreen 
                                    ? screenSize.width * 0.05 
                                    : screenSize.width * 0.035,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Get Started'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.06),
                  EquipmentImagesSection(),
                  SizedBox(height: screenSize.height * 0.06),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



