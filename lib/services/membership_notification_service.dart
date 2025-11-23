import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for managing membership email notifications
/// Handles triggering notifications and checking notification status
class MembershipNotificationService {
  // Production: use your domain
  static String _apiHost() {
    return 'rnrgym.com';
  }

  static String get baseUrl =>
      'https://' + _apiHost() + '/gym_api/membership';

  /// Trigger membership notifications manually
  /// 
  /// [notificationType] - '3_days_left', 'expired', or 'all' (default: 'all')
  /// [customerId] - Optional. If provided, only processes notifications for this customer
  /// 
  /// Returns [NotificationTriggerResult] with processing summary
  static Future<NotificationTriggerResult> triggerNotifications({
    String notificationType = 'all',
    int? customerId,
  }) async {
    try {
      final body = <String, dynamic>{
        'notification_type': notificationType,
      };

      if (customerId != null) {
        body['customer_id'] = customerId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/triggerNotifications.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return NotificationTriggerResult(
          success: true,
          message: responseData['message'] ?? 'Notifications processed successfully',
          data: responseData['data'],
          timestamp: responseData['timestamp'],
        );
      } else {
        return NotificationTriggerResult(
          success: false,
          message: responseData['message'] ?? 'Failed to trigger notifications',
          data: null,
          timestamp: null,
        );
      }
    } catch (e) {
      debugPrint('Notification trigger API error: $e');
      return NotificationTriggerResult(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
        timestamp: null,
      );
    }
  }

  /// Get notification history for a customer
  /// 
  /// [customerId] - The customer ID to get notification history for
  /// 
  /// Returns [NotificationHistoryResult] with list of notifications
  static Future<NotificationHistoryResult> getNotificationHistory(
    int customerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getNotificationStatus.php?customer_id=$customerId'),
        headers: {'Content-Type': 'application/json'},
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final List<dynamic> notificationsJson = responseData['data'] ?? [];
        final notifications = notificationsJson
            .map((json) => NotificationRecord.fromJson(json))
            .toList();

        return NotificationHistoryResult(
          success: true,
          message: 'Notification history retrieved successfully',
          notifications: notifications,
          count: responseData['count'] ?? 0,
        );
      } else {
        return NotificationHistoryResult(
          success: false,
          message: responseData['message'] ?? 'Failed to get notification history',
          notifications: [],
          count: 0,
        );
      }
    } catch (e) {
      debugPrint('Notification history API error: $e');
      return NotificationHistoryResult(
        success: false,
        message: 'Network error: ${e.toString()}',
        notifications: [],
        count: 0,
      );
    }
  }

  /// Check if customer has pending notifications
  /// This is a convenience method that checks the latest notification status
  static Future<bool> hasPendingNotifications(int customerId) async {
    try {
      final history = await getNotificationHistory(customerId);
      if (!history.success || history.notifications.isEmpty) {
        return false;
      }

      // Check if there are any failed notifications that might need retry
      final hasFailedNotifications = history.notifications
          .any((n) => n.status == 'failed');

      // If there are failed notifications, they might need retry
      // This is a simple check - you might want to enhance this based on your needs
      return hasFailedNotifications;
    } catch (e) {
      debugPrint('Error checking pending notifications: $e');
      return false;
    }
  }
}

/// Result of triggering notifications
class NotificationTriggerResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String? timestamp;

  NotificationTriggerResult({
    required this.success,
    required this.message,
    this.data,
    this.timestamp,
  });

  /// Get summary statistics from the result data
  NotificationSummary? get summary {
    if (data == null) return null;

    try {
      return NotificationSummary.fromJson(data!);
    } catch (e) {
      debugPrint('Error parsing notification summary: $e');
      return null;
    }
  }
}

/// Summary of notification processing
class NotificationSummary {
  final ThreeDaysLeftSummary? threeDaysLeft;
  final ExpiredSummary? expired;

  NotificationSummary({
    this.threeDaysLeft,
    this.expired,
  });

  factory NotificationSummary.fromJson(Map<String, dynamic> json) {
    return NotificationSummary(
      threeDaysLeft: json['three_days_left'] != null
          ? ThreeDaysLeftSummary.fromJson(json['three_days_left'])
          : null,
      expired: json['expired'] != null
          ? ExpiredSummary.fromJson(json['expired'])
          : null,
    );
  }
}

class ThreeDaysLeftSummary {
  final int processed;
  final int sent;
  final int failed;
  final int skipped;

  ThreeDaysLeftSummary({
    required this.processed,
    required this.sent,
    required this.failed,
    required this.skipped,
  });

  factory ThreeDaysLeftSummary.fromJson(Map<String, dynamic> json) {
    return ThreeDaysLeftSummary(
      processed: json['processed'] ?? 0,
      sent: json['sent'] ?? 0,
      failed: json['failed'] ?? 0,
      skipped: json['skipped'] ?? 0,
    );
  }
}

class ExpiredSummary {
  final int processed;
  final int sent;
  final int failed;
  final int skipped;

  ExpiredSummary({
    required this.processed,
    required this.sent,
    required this.failed,
    required this.skipped,
  });

  factory ExpiredSummary.fromJson(Map<String, dynamic> json) {
    return ExpiredSummary(
      processed: json['processed'] ?? 0,
      sent: json['sent'] ?? 0,
      failed: json['failed'] ?? 0,
      skipped: json['skipped'] ?? 0,
    );
  }
}

/// Result of getting notification history
class NotificationHistoryResult {
  final bool success;
  final String message;
  final List<NotificationRecord> notifications;
  final int count;

  NotificationHistoryResult({
    required this.success,
    required this.message,
    required this.notifications,
    required this.count,
  });
}

/// Individual notification record
class NotificationRecord {
  final int id;
  final int membershipId;
  final String notificationType;
  final DateTime sentAt;
  final String email;
  final DateTime expirationDate;
  final String status;
  final String? errorMessage;

  NotificationRecord({
    required this.id,
    required this.membershipId,
    required this.notificationType,
    required this.sentAt,
    required this.email,
    required this.expirationDate,
    required this.status,
    this.errorMessage,
  });

  factory NotificationRecord.fromJson(Map<String, dynamic> json) {
    return NotificationRecord(
      id: _safeInt(json['id']),
      membershipId: _safeInt(json['membership_id']),
      notificationType: json['notification_type'] ?? '',
      sentAt: _parseDateTime(json['sent_at']) ?? DateTime.now(),
      email: json['email'] ?? '',
      expirationDate: _parseDate(json['expiration_date']) ?? DateTime.now(),
      status: json['status'] ?? 'unknown',
      errorMessage: json['error_message'],
    );
  }

  /// Check if notification was successfully sent
  bool get isSuccessful => status == 'sent';

  /// Check if notification failed
  bool get isFailed => status == 'failed';

  /// Get display name for notification type
  String get typeDisplayName {
    switch (notificationType) {
      case '3_days_left':
        return '3 Days Left';
      case 'expired':
        return 'Expired';
      default:
        return notificationType;
    }
  }

  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        // Handle date-only strings (YYYY-MM-DD)
        if (value.length == 10) {
          return DateTime.parse('$value 00:00:00');
        }
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
      'membership_id': membershipId,
      'notification_type': notificationType,
      'sent_at': sentAt.toIso8601String(),
      'email': email,
      'expiration_date': expirationDate.toIso8601String(),
      'status': status,
      'error_message': errorMessage,
    };
  }
}

