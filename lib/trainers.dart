import 'package:flutter/material.dart';

class TrainersSection extends StatelessWidget {
  final bool isSmallScreen;
  final double screenWidth;

  const TrainersSection({
    Key? key,
    required this.isSmallScreen,
    required this.screenWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20.0 : screenWidth * 0.1,
          ),
          child: Text(
            'Trainers',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? screenWidth * 0.06 : screenWidth * 0.04,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20.0 : screenWidth * 0.1,
          ),
          child: Row(
            children: [
              Container(
                width: 220,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marron Jeremy',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Certified fitness trainer with 5+ years of experience helping clients achieve their goals.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
