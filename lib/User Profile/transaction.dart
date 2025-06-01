import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class TransactionProofWidget extends StatefulWidget {
  const TransactionProofWidget({Key? key}) : super(key: key);

  @override
  State<TransactionProofWidget> createState() => _TransactionProofWidgetState();
}

class _TransactionProofWidgetState extends State<TransactionProofWidget> {
  File? _imageFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submitProof() {
    // TODO: Implement backend upload logic here
    if (_imageFile != null) {
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
        color: Colors.white,
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
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              'Please upload an image showing your transaction history as proof.',
              style: TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 160,
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
                  _imageFile == null
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
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 160,
                        ),
                      ),
            ),
          ),
          SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _imageFile != null ? _submitProof : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _imageFile != null ? Colors.blue : Colors.blueGrey[200],
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
