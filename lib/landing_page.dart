import 'package:flutter/material.dart';
import 'sidenav.dart';

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
          Image.asset(
            'assets/images/gym_view/BACK VIEW OF GYM 2.jpg',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.3), // Optional: darken for readability
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
          // Equipments Section
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(top: 340, left: 20, right: 20),
              child: Text(
                'Equipments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Equipment Cards
          Padding(
            padding: EdgeInsets.only(top: 380),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(width: 20),
                  _EquipmentCard(
                    imagePath: 'assets/images/gym_equipments/dumbells.jpg',
                    tags: ['Product', 'Gift'],
                    title: 'Dumbbells',
                    description: 'High quality dumbbells for strength training.',
                    userName: 'Super user',
                    userAvatar: Icons.person,
                  ),
                  SizedBox(width: 16),
                  _EquipmentCard(
                    imagePath: 'assets/images/gym_equipments/bike.jpg',
                    tags: ['Product', 'Gift'],
                    title: 'Exercise Bike',
                    description: 'Cardio equipment for endurance.',
                    userName: 'Super user',
                    userAvatar: Icons.person,
                  ),
                  SizedBox(width: 16),
                  _EquipmentCard(
                    imagePath: 'assets/images/gym_equipments/weights.jpg',
                    tags: ['Product', 'Gift'],
                    title: 'Weights',
                    description: 'Various weights for all levels.',
                    userName: 'Super user',
                    userAvatar: Icons.person,
                  ),
                  SizedBox(width: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final String imagePath;
  final List<String> tags;
  final String title;
  final String description;
  final String userName;
  final IconData userAvatar;

  const _EquipmentCard({
    required this.imagePath,
    required this.tags,
    required this.title,
    required this.description,
    required this.userName,
    required this.userAvatar,
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
              color: Colors.black.withOpacity(0.45),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: tags.map((tag) => Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  )).toList(),
                ),
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
                SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(userAvatar, color: Colors.black),
                    ),
                    SizedBox(width: 8),
                    Text(
                      userName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
