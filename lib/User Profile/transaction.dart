import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb

class TransactionProofWidget extends StatefulWidget {
  const TransactionProofWidget({Key? key}) : super(key: key);

  @override
  State<TransactionProofWidget> createState() => _TransactionProofWidgetState();
}

class _TransactionProofWidgetState extends State<TransactionProofWidget> {
  File? _imageFile;
  Uint8List? _webImageBytes; // Variable to store image bytes for web

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        // For web, get bytes
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _imageFile = null; // Ensure file is null for web
        });
      } else {
        // For mobile, get File
        setState(() {
          _imageFile = File(pickedFile.path);
          _webImageBytes = null; // Ensure bytes are null for mobile
        });
      }
    }
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
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(100),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              'Please upload an image showing your transaction history as proof.',
              style: TextStyle(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                border: Border.all(
                  color: Colors.white30,
                  width: 1,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  _imageFile == null && _webImageBytes == null
                      ? Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_rounded,
                              color: Colors.white54,
                              size: 36,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Click or drag & drop image here',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            kIsWeb
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _webImageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 160,
                                  ),
                                )
                                : ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 160,
                                  ),
                                ),
                      ),
            ),
          ),
          SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _imageFile != null || _webImageBytes != null
                      ? _submitProof
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _imageFile != null || _webImageBytes != null
                        ? Colors.white
                        : Colors.white12,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Submit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      _imageFile != null || _webImageBytes != null
                          ? Colors.black
                          : Colors.white30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
