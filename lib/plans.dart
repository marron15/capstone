import 'package:flutter/material.dart';
import 'trainers.dart';

class PlansSection extends StatelessWidget {
  final bool isSmallScreen;
  final double screenWidth;
  final double screenHeight;

  const PlansSection({
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
            'Our Membership Prices',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? screenWidth * 0.07 : screenWidth * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: isSmallScreen ? 20.0 : screenWidth * 0.1),
              _MembershipCard(
                title: 'Daily',
                price: '₱50.00',
                priceSuffix: '/day',
                features: [
                  'For Membership - You can walk in Gym for paying Cash or Through G-Cash.',
                  'No Annual',
                  'Add-Ons: Personal Trainer - ₱2,500 Total (Membership Included)',
                ],
                buttonText: 'Get Membership Now',
                gradient: null,
                backgroundColor: Colors.black,
              ),
              SizedBox(width: 24),
              _MembershipCard(
                title: 'Half Month',
                price: '₱175.00',
                priceSuffix: '/month',
                features: [
                  'For Membership - You can walk in Gym for paying Cash or Through G-Cash.',
                  'No Annual',
                  'Add-Ons: Personal Trainer - ₱2,500 Total (Membership Included)',
                ],
                buttonText: 'Get Membership Now',
                gradient: null,
                backgroundColor: Colors.black,
              ),
              SizedBox(width: 24),
              _MembershipCard(
                title: '1 Month',
                price: '₱400.00',
                priceSuffix: '/month',
                features: [
                  'For Membership - You can walk in Gym for paying Cash or Through G-Cash.',
                  'Renew for 1 Month Membership  ₱350.00',
                  'No Annual',
                  'Add-Ons: Personal Trainer - ₱2,500 Total (Membership Included)',
                ],
                buttonText: 'Get Membership Now',
                gradient: null,
                backgroundColor: Colors.black,
              ),
              SizedBox(width: isSmallScreen ? 20.0 : screenWidth * 0.1),
            ],
          ),
        ),
        TrainersSection(
          isSmallScreen: isSmallScreen,
          screenWidth: screenWidth,
        ),
        SizedBox(height: screenHeight * 0.03),
      ],
    );
  }
}

class _MembershipCard extends StatelessWidget {
  final String title;
  final String price;
  final String priceSuffix;
  final List<String> features;
  final String buttonText;
  final Gradient? gradient;
  final Color? backgroundColor;

  const _MembershipCard({
    required this.title,
    required this.price,
    required this.priceSuffix,
    required this.features,
    required this.buttonText,
    this.gradient,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: gradient,
        color: backgroundColor,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                ),
              ),
              SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(
                  priceSuffix,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 10),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}
