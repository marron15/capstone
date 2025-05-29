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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20.0 : screenWidth * 0.1,
          ),
          child: Center(
            child: Text(
              'Add-Ons',
              style: TextStyle(
                color: Colors.white,
                fontSize: (isSmallScreen
                        ? screenWidth * 0.07
                        : screenWidth * 0.045)
                    .clamp(22.0, 48.0),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.03),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: isSmallScreen ? 20.0 : screenWidth * 0.1),
              _FlexibleServiceCard(
                imagePath: 'assets/images/services&products/Lockers.jpg',
                title: 'Locker Rental',
                description:
                    'Secure your belongings with our lockers you can bring your own lock. Rental fee: 50 pesos/month.',
              ),
              SizedBox(width: 16),
              _FlexibleServiceCard(
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

class _FlexibleServiceCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const _FlexibleServiceCard({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth < 900 ? screenWidth * 0.5 : 240;
    cardWidth = cardWidth.clamp(160.0, 280.0);
    return SizedBox(
      width: cardWidth,
      height: 220,
      child: _ServiceCard(
        imagePath: imagePath,
        title: title,
        description: description,
      ),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: double.infinity,
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
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
