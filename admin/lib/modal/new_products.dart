import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class AddProductModal extends StatefulWidget {
  final void Function(Uint8List imageBytes, String name, String description)?
      onSave;
  const AddProductModal({Key? key, this.onSave}) : super(key: key);

  @override
  State<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  Uint8List? _imageBytes;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isHovering = false;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  void _handleSave() {
    if (_imageBytes != null &&
        _nameController.text.trim().isNotEmpty &&
        _descController.text.trim().isNotEmpty) {
      widget.onSave?.call(
        _imageBytes!,
        _nameController.text.trim(),
        _descController.text.trim(),
      );
      Navigator.of(context).pop();
    } else {
      // Optionally show a validation error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and select an image.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 56),
        constraints: const BoxConstraints(
          maxWidth: 800,
          minWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add New Product',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF22223B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Center(
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovering = true),
                onExit: (_) => setState(() => _isHovering = false),
                child: GestureDetector(
                  onTap: _pickImage,
                  child: _imageBytes == null
                      ? AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _isHovering
                                  ? Colors.blueAccent
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            boxShadow: _isHovering
                                ? [
                                    BoxShadow(
                                      color:
                                          Colors.blueAccent.withOpacity(0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo_rounded,
                                  size: 64, color: Colors.blueGrey),
                              SizedBox(height: 16),
                              Text(
                                'Upload Image',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.memory(
                            _imageBytes!,
                            width: 320,
                            height: 320,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 56),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Product Name',
                hintText: 'Enter product name',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      const BorderSide(color: Colors.blueAccent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 36),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Enter product description',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      const BorderSide(color: Colors.blueAccent, width: 2),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 56),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueGrey,
                    textStyle: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 28),
                ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 22),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    elevation: 2,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
