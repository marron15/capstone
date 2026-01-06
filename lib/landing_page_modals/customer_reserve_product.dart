import 'package:flutter/material.dart';

class ReserveProductModal extends StatefulWidget {
  final String productName;
  final String description;
  final int availableQuantity;
  final ImageProvider image;

  const ReserveProductModal({
    super.key,
    required this.productName,
    required this.description,
    required this.availableQuantity,
    required this.image,
  });

  @override
  State<ReserveProductModal> createState() => _ReserveProductModalState();
}

class _ReserveProductModalState extends State<ReserveProductModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantityController.text = widget.availableQuantity > 0 ? '1' : '0';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _availabilityLabel() {
    if (widget.availableQuantity <= 0) return 'Sold Out';
    if (widget.availableQuantity == 1) return 'Only 1 left';
    return 'In stock: ${widget.availableQuantity}';
  }

  Future<void> _submit() async {
    if (widget.availableQuantity <= 0) return;
    if (!_formKey.currentState!.validate()) return;
    final int parsedQty = int.parse(_quantityController.text.trim());
    final String notes = _notesController.text.trim();
    Navigator.of(
      context,
    ).pop(<String, dynamic>{'quantity': parsedQty, 'notes': notes});
  }

  @override
  Widget build(BuildContext context) {
    final bool soldOut = widget.availableQuantity <= 0;
    final double maxContentWidth = MediaQuery.of(
      context,
    ).size.width.clamp(320.0, 720.0);
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 600 ? 16 : 64,
        vertical: 24,
      ),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: Colors.black.withAlpha((0.78 * 255).toInt()),
          width: maxContentWidth,
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 600 ? 20 : 32,
            vertical: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image(
                        image: widget.image,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.productName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.description,
                            style: TextStyle(
                              color: Colors.white.withAlpha(
                                (0.85 * 255).toInt(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  soldOut
                                      ? Colors.redAccent.withAlpha(
                                        (0.15 * 255).toInt(),
                                      )
                                      : Colors.greenAccent.withAlpha(
                                        (0.15 * 255).toInt(),
                                      ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              _availabilityLabel(),
                              style: TextStyle(
                                color:
                                    soldOut
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _quantityController,
                  enabled: !soldOut,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withAlpha((0.09 * 255).toInt()),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (soldOut) return 'This product is currently unavailable';
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a quantity';
                    }
                    final parsed = int.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Quantity must be greater than zero';
                    }
                    if (parsed > widget.availableQuantity) {
                      return 'Only ${widget.availableQuantity} available';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Additional notes (optional)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white.withAlpha((0.09 * 255).toInt()),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: soldOut ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              soldOut ? Colors.grey : Colors.orangeAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Submit Reservation'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
