import 'package:flutter/material.dart';

class TermsAndConditionsModal extends StatelessWidget {
  const TermsAndConditionsModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? double.infinity : 800,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      '1. Membership Agreement',
                      'By signing up for a membership at Fitness Gym, you agree to abide by these Terms and Conditions. Your membership is subject to the rules and regulations of the gym.',
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      '2. Membership Types',
                      'We offer various membership types including Daily, Half Month, and Monthly memberships. Each membership type has specific terms regarding duration, access, and pricing.',
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      '3. Business Hours',
                      'Our gym operates from 11:00 AM to 9:00 PM, Monday to Saturday. The gym is closed on Sundays. Daily memberships expire at 9:00 PM on the day of purchase.',
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      '4. Code of Conduct',
                      'All members must conduct themselves in a respectful and appropriate manner. Any behavior that disrupts the gym environment or endangers others will result in immediate termination of membership without refund.',
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      '5. Equipment Usage',
                      'Members are responsible for using gym equipment properly and safely. Any damage to equipment due to misuse will be charged to the member. Please report any equipment malfunctions to staff immediately.',
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      '6. Personal Belongings',
                      'The gym is not responsible for lost, stolen, or damaged personal belongings. Please use lockers provided and do not leave valuables unattended.',
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      '7. Health and Safety',
                      'Members must be in good health to use the gym facilities. If you have any medical conditions, please consult with a physician before beginning any exercise program. The gym is not liable for any injuries that may occur during use of facilities.',
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      '8. Membership Cancellation',
                      'Membership cancellations must be submitted in writing. Refunds are subject to the terms of your specific membership agreement. No refunds will be provided for partially used periods.',
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      '9. Payment Terms',
                      'All membership fees must be paid in full before access is granted. Late payments may result in suspension of membership privileges. We accept cash and electronic payment methods.',
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      '10. Changes to Terms',
                      'Fitness Gym reserves the right to modify these Terms and Conditions at any time. Members will be notified of significant changes. Continued use of the gym after changes constitutes acceptance of the new terms.',
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      '11. Contact Information',
                      'For questions or concerns regarding these Terms and Conditions, please contact us at:\n\n875 Rizal Avenue West Tapinac, Olongapo City\nBusiness Hours: 11:00 AM - 9:00 PM, Monday to Saturday',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Last Updated: ${DateTime.now().year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'I Understand',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

