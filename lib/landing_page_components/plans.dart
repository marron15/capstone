import 'package:flutter/material.dart';
import '../modals/payment.dart';

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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20.0 : screenWidth * 0.1,
          ),
          child: Center(
            child: Text(
              'Our Membership Prices',
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
        SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: isSmallScreen ? 20.0 : screenWidth * 0.1),
              _FlexibleMembershipCard(
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
                isSmallScreen: isSmallScreen,
                screenWidth: screenWidth,
              ),
              SizedBox(width: 24),
              _FlexibleMembershipCard(
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
                isSmallScreen: isSmallScreen,
                screenWidth: screenWidth,
              ),
              SizedBox(width: 24),
              _FlexibleMembershipCard(
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
                isSmallScreen: isSmallScreen,
                screenWidth: screenWidth,
              ),
              SizedBox(width: isSmallScreen ? 20.0 : screenWidth * 0.1),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.03),
      ],
    );
  }
}

class _FlexibleMembershipCard extends StatelessWidget {
  final String title;
  final String price;
  final String priceSuffix;
  final List<String> features;
  final String buttonText;
  final Gradient? gradient;
  final Color? backgroundColor;
  final bool isSmallScreen;
  final double screenWidth;

  const _FlexibleMembershipCard({
    required this.title,
    required this.price,
    required this.priceSuffix,
    required this.features,
    required this.buttonText,
    this.gradient,
    this.backgroundColor,
    required this.isSmallScreen,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    double cardWidth = isSmallScreen ? screenWidth * 0.7 : screenWidth * 0.22;
    cardWidth = cardWidth.clamp(180.0, 340.0);
    return SizedBox(
      width: cardWidth,
      child: _MembershipCard(
        title: title,
        price: price,
        priceSuffix: priceSuffix,
        features: features,
        buttonText: buttonText,
        gradient: gradient,
        backgroundColor: backgroundColor,
        isSmallScreen: isSmallScreen,
        screenWidth: screenWidth,
      ),
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
  final bool isSmallScreen;
  final double screenWidth;

  const _MembershipCard({
    required this.title,
    required this.price,
    required this.priceSuffix,
    required this.features,
    required this.buttonText,
    this.gradient,
    this.backgroundColor,
    required this.isSmallScreen,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              fontSize: (isSmallScreen
                      ? screenWidth * 0.045
                      : screenWidth * 0.018)
                  .clamp(16.0, 26.0),
            ),
          ),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  price,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: (isSmallScreen
                            ? screenWidth * 0.09
                            : screenWidth * 0.04)
                        .clamp(22.0, 38.0),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(
                  priceSuffix,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: (isSmallScreen
                            ? screenWidth * 0.025
                            : screenWidth * 0.012)
                        .clamp(12.0, 18.0),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          ...features.map(
            (f) => Padding(
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
                        fontSize: (isSmallScreen
                                ? screenWidth * 0.025
                                : screenWidth * 0.012)
                            .clamp(12.0, 18.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                PaymentModal.showGcash(
                  context,
                  planTitle: title,
                  amountLabel: '$price $priceSuffix',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: (isSmallScreen
                          ? screenWidth * 0.025
                          : screenWidth * 0.012)
                      .clamp(14.0, 18.0),
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
