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
  final String? address;
  final String? street;
  final String? city;
  final String? stateProvince;
  final String? postalCode;
  final String? country;

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
    this.address,
    this.street,
    this.city,
    this.stateProvince,
    this.postalCode,
    this.country,
  });
}

ValueNotifier<ProfileData> profileNotifier = ValueNotifier(ProfileData());
