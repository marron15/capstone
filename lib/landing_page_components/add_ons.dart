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
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Center(
            child: Text(
              'Add-Ons',
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
            'Convenient facilities for your comfortable visit',
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
              _FlexibleAddOnCard(
                imagePath: 'assets/images/services&products/Lockers.jpg',
                title: 'Locker Rental',
                description:
                    'Secure your belongings with our lockers. Bring your own lock.',
              ),
              _FlexibleAddOnCard(
                imagePath: 'assets/images/services&products/FreeLockers.jpg',
                title: 'Free Lockers',
                description: 'Free open lockers for your convenience.',
              ),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.06),
      ],
    );
  }
}

class _FlexibleAddOnCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const _FlexibleAddOnCard({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Medium adaptive width:
    double cardWidth =
        screenWidth >= 1100
            ? (screenWidth * 0.25).clamp(250.0, 340.0)
            : screenWidth >= 700
            ? (screenWidth * 0.42).clamp(250.0, 360.0)
            : (screenWidth * 0.85).clamp(240.0, 400.0);

    double cardHeight = screenWidth >= 700 ? 320 : 300;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: _AddOnCardInteractive(
        imagePath: imagePath,
        title: title,
        description: description,
      ),
    );
  }
}

class _AddOnCardInteractive extends StatefulWidget {
  final String imagePath;
  final String title;
  final String description;

  const _AddOnCardInteractive({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  State<_AddOnCardInteractive> createState() => _AddOnCardInteractiveState();
}

class _AddOnCardInteractiveState extends State<_AddOnCardInteractive> {
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
