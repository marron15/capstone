import 'package:flutter/material.dart';

class PaymentModal {
  static Future<void> showGcash(
    BuildContext context, {
    required String planTitle,
    required String amountLabel,
  }) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController numberController = TextEditingController();
    final TextEditingController referenceController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pay with GCash',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Plan: $planTitle',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Amount: $amountLabel',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.15),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Send payment to our official GCash number and input the reference number below.',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'GCash Account Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: numberController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Your GCash Number',
                          prefixIcon: Icon(Icons.phone_iphone),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: referenceController,
                        decoration: const InputDecoration(
                          labelText: 'GCash Reference Number',
                          prefixIcon: Icon(Icons.confirmation_number_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final hasAll =
                                nameController.text.trim().isNotEmpty &&
                                numberController.text.trim().isNotEmpty &&
                                referenceController.text.trim().isNotEmpty;
                            if (!hasAll) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill all fields'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Payment details submitted. We will verify shortly.',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Submit Payment Details'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
