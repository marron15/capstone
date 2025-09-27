import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MembershipService {
  // Use computer's IP for mobile testing, localhost for web
  static String _apiHost() {
    if (kIsWeb) return 'localhost';
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Use computer's IP for real device testing
        return '192.168.100.220'; // Replace with your computer's IP
      }
      return '192.168.100.220'; // Use computer's IP for mobile testing
    } catch (_) {
      return '192.168.100.220'; // Fallback to computer's IP
    }
  }

  static String get baseUrl => 'http://' + _apiHost() + '/gym_api/membership';

  static Future<MembershipResult> getMembershipByCustomerId(
    int customerId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getMembershipByCustomerId.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'customer_id': customerId}),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      // Debug logging
      debugPrint('🔍 Membership API Response: $responseData');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return MembershipResult(
          success: true,
          message:
              responseData['message'] ?? 'Membership retrieved successfully',
          membershipData: MembershipData.fromJson(responseData['data']),
        );
      } else {
        return MembershipResult(
          success: false,
          message: responseData['message'] ?? 'Failed to get membership',
          membershipData: null,
        );
      }
    } catch (e) {
      return MembershipResult(
        success: false,
        message: 'Network error: ${e.toString()}',
        membershipData: null,
      );
    }
  }
}

class MembershipResult {
  final bool success;
  final String message;
  final MembershipData? membershipData;

  MembershipResult({
    required this.success,
    required this.message,
    this.membershipData,
  });
}

class MembershipData {
  final int id;
  final int customerId;
  final String membershipType;
  final DateTime startDate;
  final DateTime expirationDate;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  MembershipData({
    required this.id,
    required this.customerId,
    required this.membershipType,
    required this.startDate,
    required this.expirationDate,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory MembershipData.fromJson(Map<String, dynamic> json) {
    return MembershipData(
      id: _safeInt(json['id']),
      customerId: _safeInt(json['customer_id']),
      membershipType: _safeString(json['membership_type']) ?? '',
      startDate: _parseDate(json['start_date']) ?? DateTime.now(),
      expirationDate: _parseDate(json['expiration_date']) ?? DateTime.now(),
      status: _safeString(json['status']) ?? '',
      createdAt: _safeString(json['created_at']),
      updatedAt: _safeString(json['updated_at']),
    );
  }

  // Helper method to safely convert to int
  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Helper method to safely convert to String
  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  // Helper method to parse date strings
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'membership_type': membershipType,
      'start_date': startDate.toIso8601String(),
      'expiration_date': expirationDate.toIso8601String(),
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
