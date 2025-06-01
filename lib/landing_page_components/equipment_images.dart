import 'package:flutter/material.dart';

class EquipmentImagesSection extends StatelessWidget {
  const EquipmentImagesSection({
    Key? key,
    required this.isSmallScreen,
    required this.screenWidth,
    required this.screenHeight,
  }) : super(key: key);

  final bool isSmallScreen;
  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Center(
            child: Text(
              'Equipments',
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
        SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 20),
              _FlexibleEquipmentCard(
                imagePath: 'assets/images/gym_equipments/dumbells.jpg',
                title: 'Dumbbells',
                description: 'High quality dumbbells for strength training.',
              ),
              SizedBox(width: 16),
              _FlexibleEquipmentCard(
                imagePath: 'assets/images/gym_equipments/bike.jpg',
                title: 'Exercise Bike',
                description: 'Cardio equipment for endurance.',
              ),
              SizedBox(width: 16),
              _FlexibleEquipmentCard(
                imagePath: 'assets/images/gym_equipments/weights.jpg',
                title: 'Weights',
                description: 'Various weights for all levels.',
              ),
              SizedBox(width: 20),
            ],
          ),
        ),
        SizedBox(height: 40),
      ],
    );
  }
}

class _FlexibleEquipmentCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const _FlexibleEquipmentCard({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth < 900 ? screenWidth * 0.7 : 280;
    cardWidth = cardWidth.clamp(180.0, 320.0);
    return SizedBox(
      width: cardWidth,
      height: 320,
      child: _EquipmentCard(
        imagePath: imagePath,
        title: title,
        description: description,
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const _EquipmentCard({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              height: 320,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: double.infinity,
            height: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black.withAlpha((0.45 * 255).toInt()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
