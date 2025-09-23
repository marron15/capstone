import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:ui';
import 'dart:typed_data';

class Product {
  final String name;
  final double price;
  final String description;
  final Uint8List imageBytes;
  final String imageFileName;

  Product({
    required this.name,
    required this.price,
    required this.description,
    required this.imageBytes,
    required this.imageFileName,
  });
}

class AddProductModal extends StatefulWidget {
  final Function(Product) onProductAdded;
  final Product? initialProduct;

  const AddProductModal({
    super.key,
    required this.onProductAdded,
    this.initialProduct,
  });

  @override
  State<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageFileName;

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      _nameController.text = widget.initialProduct!.name;
      _priceController.text = widget.initialProduct!.price.toString();
      _descriptionController.text = widget.initialProduct!.description;
      _imageBytes = widget.initialProduct!.imageBytes;
      _imageFileName = widget.initialProduct!.imageFileName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.black.withAlpha((0.3 * 255).toInt()),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.lightBlueAccent, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withAlpha((0.18 * 255).toInt()),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _imageBytes = result.files.single.bytes;
        _imageFileName = result.files.single.name;
      });
    }
  }

  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((0.3 * 255).toInt()),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withAlpha((0.18 * 255).toInt()),
          ),
        ),
        child:
            _imageBytes != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blueAccent.withAlpha((0.25 * 255).toInt()),
                            Colors.lightBlueAccent.withAlpha(
                              (0.18 * 255).toInt(),
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Click to upload image',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _descriptionController.clear();
    setState(() {
      _imageBytes = null;
      _imageFileName = null;
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate() && _imageBytes != null) {
      final newProduct = Product(
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        description: _descriptionController.text,
        imageBytes: _imageBytes!,
        imageFileName: _imageFileName ?? 'image.png',
      );

      widget.onProductAdded(newProduct);
      _clearForm();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialProduct == null
                ? 'Product added successfully!'
                : 'Product updated!',
          ),
          backgroundColor:
              widget.initialProduct == null ? Colors.green : Colors.blue,
        ),
      );
    } else if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image for the product'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title =
        widget.initialProduct == null ? 'Add New Product' : 'Edit Product';
    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Align(
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: 720,
                  constraints: const BoxConstraints(maxWidth: 760),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.black.withAlpha((0.7 * 255).toInt()),
                    border: Border.all(
                      color: Colors.white.withAlpha((0.25 * 255).toInt()),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withAlpha(
                          (0.18 * 255).toInt(),
                        ),
                        blurRadius: 32,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blueAccent.withAlpha(
                                        (0.25 * 255).toInt(),
                                      ),
                                      Colors.lightBlueAccent.withAlpha(
                                        (0.18 * 255).toInt(),
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: Colors.lightBlueAccent,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  Icons.close,
                                  size: 26,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Divider(
                            thickness: 1.5,
                            color: Colors.lightBlueAccent.withAlpha(
                              (0.22 * 255).toInt(),
                            ),
                            height: 24,
                            endIndent: 12,
                            indent: 2,
                          ),
                          const SizedBox(height: 16),
                          _buildImagePreview(),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Product Name'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter product name';
                              }
                              return null;
                            },
                          ),
                          // Price removed per request; defaulting to 0.0 in submission
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Description'),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter product description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _clearForm();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.lightBlueAccent,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  widget.initialProduct == null
                                      ? 'Add Product'
                                      : 'Save Changes',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
