import 'dart:io';
import 'package:flutter/material.dart';

class ProfileData {
  final File? imageFile;
  final String name;
  final String contactNumber;

  ProfileData({this.imageFile, this.name = '', this.contactNumber = ''});
}

ValueNotifier<ProfileData> profileNotifier = ValueNotifier(ProfileData());
