import 'dart:io';
import 'package:flutter/material.dart';

class ProfileData {
  final File? imageFile;
  final String firstName;
  final String middleName;
  final String lastName;
  final String contactNumber;
  final String? email;
  final DateTime? birthdate;

  ProfileData({
    this.imageFile,
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.contactNumber = '',
    this.email,
    this.birthdate,
  });
}

ValueNotifier<ProfileData> profileNotifier = ValueNotifier(ProfileData());
