import 'package:flutter/material.dart';

class ServicesSection extends StatelessWidget {
  final bool isSmallScreen;
  final double screenWidth;
  final double screenHeight;

  const ServicesSection({
    Key? key,
    required this.isSmallScreen,
    required this.screenWidth,
    required this.screenHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20.0 : screenWidth * 0.1,
          ),
          child: Text(
            'Services',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? screenWidth * 0.07 : screenWidth * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.03),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(width: isSmallScreen ? 20.0 : screenWidth * 0.1),
              _ServiceCard(
                imagePath: 'assets/images/services&products/Lockers.jpg',
                title: 'Locker Rental',
                description: 'Secure your belongings with our lockers you can bring your own lock. Rental fee: 50 pesos/month.',
              ),
              SizedBox(width: 16),
              _ServiceCard(
                imagePath: 'assets/images/services&products/FreeLockers.jpg',
                title: 'Free Lockers',
                description: 'Free open lockers for your convenience.',
              ),
              SizedBox(width: isSmallScreen ? 20.0 : screenWidth * 0.1),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.06),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const _ServiceCard({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 220,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              imagePath,
              width: 240,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: 240,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.black.withAlpha((0.45 * 255).toInt()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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
