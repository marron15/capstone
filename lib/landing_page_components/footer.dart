import 'package:flutter/material.dart';

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
        vertical: 28.0,
        horizontal: isSmallScreen ? 16.0 : screenWidth * 0.1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side - Logo and gym name
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
          const Spacer(),
          // Right side - Address and business hours
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '875 RIZAL AVENUE WEST TAPINAC , OLONGAPO CITY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Business Hours: 11:00AM - 9:00PM',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Text(
                'Monday to Saturday',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
