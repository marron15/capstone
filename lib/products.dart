import 'package:flutter/material.dart';
import 'plans.dart';

class ProductsSection extends StatelessWidget {
  final bool isSmallScreen;
  final double screenWidth;
  final double screenHeight;

  const ProductsSection({
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(width: isSmallScreen ? 20.0 : screenWidth * 0.1),
              _ProductCard(
                imagePath: 'assets/images/services&products/whey.png',
                title: 'Whey Protein',
                description: 'Whey protein with vitamins C. Convenient sachets.',
              ),
              SizedBox(width: 16),
              _ProductCard(
                imagePath: 'assets/images/services&products/Mass.png',
                title: 'Serious Mass',
                description: 'High-calorie mass gainer. 12 lbs, chocolate flavor.',
              ),
              SizedBox(width: 16),
              _ProductCard(
                imagePath: 'assets/images/services&products/Creatine.png',
                title: 'Prothin Creatine',
                description: 'Monohydrate creatine powder. 60 servings.',
              ),
              SizedBox(width: 16),
              _ProductCard(
                imagePath: 'assets/images/services&products/Amino.png',
                title: 'Amino 2222 Tabs',
                description: 'Full spectrum blend micronized aminos. 320 tablets.',
              ),
              SizedBox(width: isSmallScreen ? 20.0 : screenWidth * 0.1),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.06),
        PlansSection(
          isSmallScreen: isSmallScreen,
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const _ProductCard({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 240,
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
              width: 200,
              height: 240,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: 200,
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.black.withAlpha((0.35 * 255).toInt()),
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
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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
