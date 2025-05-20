import 'package:flutter/material.dart';

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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20.0 : screenWidth * 0.1,
          ),
          child: Center(
            child: Text(
              'Products',
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
              _FlexibleProductCard(
                imagePath: 'assets/images/services&products/whey.png',
                title: 'Whey Protein',
                description:
                    'Whey protein with vitamins C. Convenient sachets.',
                isSmallScreen: isSmallScreen,
                screenWidth: screenWidth,
              ),
              SizedBox(width: 16),
              _FlexibleProductCard(
                imagePath: 'assets/images/services&products/Mass.png',
                title: 'Serious Mass',
                description:
                    'High-calorie mass gainer. 12 lbs, chocolate flavor.',
                isSmallScreen: isSmallScreen,
                screenWidth: screenWidth,
              ),
              SizedBox(width: 16),
              _FlexibleProductCard(
                imagePath: 'assets/images/services&products/Creatine.png',
                title: 'Prothin Creatine',
                description: 'Monohydrate creatine powder. 60 servings.',
                isSmallScreen: isSmallScreen,
                screenWidth: screenWidth,
              ),
              SizedBox(width: 16),
              _FlexibleProductCard(
                imagePath: 'assets/images/services&products/Amino.png',
                title: 'Amino 2222 Tabs',
                description:
                    'Full spectrum blend micronized aminos. 320 tablets.',
                isSmallScreen: isSmallScreen,
                screenWidth: screenWidth,
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

class _FlexibleProductCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final bool isSmallScreen;
  final double screenWidth;

  const _FlexibleProductCard({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.isSmallScreen,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    double cardWidth = isSmallScreen ? screenWidth * 0.6 : screenWidth * 0.18;
    cardWidth = cardWidth.clamp(150.0, 260.0);
    return SizedBox(
      width: cardWidth,
      height: 260,
      child: _ProductCard(
        imagePath: imagePath,
        title: title,
        description: description,
        isSmallScreen: isSmallScreen,
        screenWidth: screenWidth,
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final bool isSmallScreen;
  final double screenWidth;

  const _ProductCard({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.isSmallScreen,
    required this.screenWidth,
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
              height: 260,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: double.infinity,
            height: 260,
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
                    fontSize: (isSmallScreen
                            ? screenWidth * 0.045
                            : screenWidth * 0.018)
                        .clamp(14.0, 22.0),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (isSmallScreen
                            ? screenWidth * 0.03
                            : screenWidth * 0.012)
                        .clamp(11.0, 16.0),
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
