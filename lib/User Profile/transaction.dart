import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class TransactionProofWidget extends StatefulWidget {
  const TransactionProofWidget({Key? key}) : super(key: key);

  @override
  State<TransactionProofWidget> createState() => _TransactionProofWidgetState();
}

class _TransactionProofWidgetState extends State<TransactionProofWidget> {
  File? _imageFile;
  Uint8List? _webImageBytes;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    if (kIsWeb) {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
        });
      }
    } else {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      if (kIsWeb) {
        _webImageBytes = null;
      } else {
        _imageFile = null;
      }
    });
  }

  void _submitProof() {
    // TODO: Implement backend upload logic here
    if (_imageFile != null || _webImageBytes != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Proof submitted! (backend logic goes here)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = kIsWeb ? _webImageBytes : _imageFile;
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'Upload Proof of Transaction',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 5),
          Center(
            child: Text(
              'Please upload image(s) showing your transaction history as proof.',
              style: TextStyle(fontSize: 15, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 15),
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              constraints: BoxConstraints(minHeight: 300, maxHeight: 300),
              decoration: BoxDecoration(
                color: Color(0xFFF5FAFF),
                border: Border.all(
                  color: Color(0xFF2196F3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  image == null
                      ? Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_rounded,
                              color: Color(0xFF90CAF9),
                              size: 36,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Click or drag & drop image here',
                              style: TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                      : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return Dialog(
                                        backgroundColor: Colors.transparent,
                                        child: InteractiveViewer(
                                          child:
                                              kIsWeb
                                                  ? Image.memory(
                                                    image as Uint8List,
                                                    fit: BoxFit.contain,
                                                  )
                                                  : Image.file(
                                                    image as File,
                                                    fit: BoxFit.contain,
                                                  ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child:
                                    kIsWeb
                                        ? Center(
                                          child: Image.memory(
                                            image as Uint8List,
                                            fit: BoxFit.contain,
                                            width: 400,
                                            height: 400,
                                          ),
                                        )
                                        : Image.file(
                                          image as File,
                                          fit: BoxFit.contain,
                                          width: 220,
                                          height: 220,
                                        ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ),
          SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: image != null ? _submitProof : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    image != null ? Colors.blue : Colors.blueGrey[200],
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Submit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
