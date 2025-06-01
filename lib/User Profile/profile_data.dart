import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ProfileData {
  final File? imageFile;
  final Uint8List? webImageBytes;
  final String firstName;
  final String middleName;
  final String lastName;
  final String contactNumber;
  final String? email;
  final DateTime? birthdate;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? password;

  ProfileData({
    this.imageFile,
    this.webImageBytes,
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.contactNumber = '',
    this.email,
    this.birthdate,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.password,
  });
}

ValueNotifier<ProfileData> profileNotifier = ValueNotifier(ProfileData());
