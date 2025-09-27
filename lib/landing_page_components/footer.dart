import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  final bool isSmallScreen;
  final double screenWidth;
  const Footer({
    Key? key,
    required this.isSmallScreen,
    required this.screenWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool stackVertically = isSmallScreen || screenWidth < 720;
    return Container(
      width: double.infinity,
      color: Colors.black,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.2,
      ),
      padding: EdgeInsets.symmetric(
        vertical: 28.0,
        horizontal: isSmallScreen ? 16.0 : screenWidth * 0.1,
      ),
      child:
          stackVertically
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/RNR1.png',
                        width: 64,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'FITNESS GYM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '875 RIZAL AVENUE WEST TAPINAC , OLONGAPO CITY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Business Hours: 11:00AM - 9:00PM',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const Text(
                    'Monday to Saturday',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/RNR1.png',
                        width: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'FITNESS GYM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        '875 RIZAL AVENUE WEST TAPINAC , OLONGAPO CITY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          letterSpacing: 1.1,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Business Hours: 11:00AM - 9:00PM',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Monday to Saturday',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
    );
  }
}
