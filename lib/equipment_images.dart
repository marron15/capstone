import 'package:flutter/material.dart';

class EquipmentImagesSection extends StatelessWidget {
  const EquipmentImagesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Equipments',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(width: 20),
              _EquipmentCard(
                imagePath: 'assets/images/gym_equipments/dumbells.jpg',
                title: 'Dumbbells',
                description: 'High quality dumbbells for strength training.',
              ),
              SizedBox(width: 16),
              _EquipmentCard(
                imagePath: 'assets/images/gym_equipments/bike.jpg',
                title: 'Exercise Bike',
                description: 'Cardio equipment for endurance.',
              ),
              SizedBox(width: 16),
              _EquipmentCard(
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
      width: 280,
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              imagePath,
              width: 280,
              height: 320,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: 280,
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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
