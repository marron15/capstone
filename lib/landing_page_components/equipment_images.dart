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
              'Services',
              style: TextStyle(
                color: Colors.white,
                fontSize: (isSmallScreen
                        ? screenWidth * 0.08
                        : screenWidth * 0.04)
                    .clamp(28.0, 56.0),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Discover our specialized training areas',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Wrap(
            spacing: 24, // Horizontal spacing between cards
            runSpacing: 24, // Vertical spacing between rows
            alignment: WrapAlignment.center,
            children: const [
              _FlexibleServiceCard(
                imagePath: 'assets/images/services&products/chest.jpeg',
                title: 'Chest',
                description: 'Build core strength and definition.',
              ),
              _FlexibleServiceCard(
                imagePath: 'assets/images/services&products/lower_chest.jpeg',
                title: 'Lower Chest',
                description: 'Targeted lower pectoral development.',
              ),
              _FlexibleServiceCard(
                imagePath: 'assets/images/services&products/back.jpeg',
                title: 'Back',
                description: 'Enhance your posture and back width.',
              ),
              _FlexibleServiceCard(
                imagePath: 'assets/images/services&products/cable_&_legs.jpeg',
                title: 'Cables & Legs',
                description: 'Complete lower body and dynamic movements.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 60),
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

    // Calculate adaptive width:
    // On large screens, cards take up slightly less than half the screen to form a 2x2 grid.
    // On small screens, cards span almost the full width.
    double cardWidth =
        screenWidth >= 900
            ? (screenWidth * 0.45).clamp(300.0, 580.0)
            : (screenWidth * 0.9).clamp(280.0, 500.0);

    // Increase the visual volume of the card with larger height
    double cardHeight = screenWidth >= 900 ? 380 : 340;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: _ServiceCardInteractive(
        imagePath: imagePath,
        title: title,
        description: description,
      ),
    );
  }
}

class _ServiceCardInteractive extends StatefulWidget {
  final String imagePath;
  final String title;
  final String description;

  const _ServiceCardInteractive({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  State<_ServiceCardInteractive> createState() =>
      _ServiceCardInteractiveState();
}

class _ServiceCardInteractiveState extends State<_ServiceCardInteractive> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform:
              Matrix4.identity()..scaleByDouble(
                _isHovered ? 1.02 : 1.0,
                _isHovered ? 1.02 : 1.0,
                1.0,
                1.0,
              ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow:
                _isHovered
                    ? [
                      BoxShadow(
                        color: Colors.black.withAlpha(80),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(widget.imagePath, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(50),
                        Colors.black.withAlpha(200),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _isHovered ? 1.0 : 0.8,
                        child: Text(
                          widget.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
