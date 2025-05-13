import 'package:flutter/material.dart';
import 'sidenav.dart';
import 'equipment_images.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            color: Colors.black.withAlpha((0.5 * 255).toInt()), // 0.5 = 50% opacity, adjust as needed
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 32),
                          Text(
                            'Welcome to RNR FITNESS GYM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Where every drop of sweat brings you closer to the best version of yourself!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 32),
                          SizedBox(
                            width: 180,
                            child: ElevatedButton(
                              onPressed: () {}, // TODO: Add navigation or action
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                                textStyle: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('Get Started'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  EquipmentImagesSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



