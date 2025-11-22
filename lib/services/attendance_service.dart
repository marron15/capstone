import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../admin/services/api_service.dart';

class AttendanceException implements Exception {
  AttendanceException(this.message);
  final String message;

  @override
  String toString() => 'AttendanceException: $message';
}

class AttendanceSnapshot {
  const AttendanceSnapshot({
    required this.customerId,
    required this.isClockedIn,
    this.attendanceId,
    this.lastTimeIn,
    this.lastTimeOut,
    this.verifyingAdminName,
    this.verifyingAdminCode,
    this.statusLabel,
  });

  final int? attendanceId;
  final int customerId;
  final bool isClockedIn;
  final DateTime? lastTimeIn;
  final DateTime? lastTimeOut;
  final String? verifyingAdminName;
  final String? verifyingAdminCode;
  final String? statusLabel;

  String get readableStatus =>
      statusLabel ??
      (isClockedIn ? 'Timed In' : 'Timed Out');

  DateTime? get referenceTimestamp =>
      isClockedIn ? lastTimeIn : lastTimeOut;

  AttendanceSnapshot copyWith({
    int? attendanceId,
    bool? isClockedIn,
    DateTime? lastTimeIn,
    DateTime? lastTimeOut,
    String? verifyingAdminName,
    String? verifyingAdminCode,
    String? statusLabel,
  }) {
    return AttendanceSnapshot(
      attendanceId: attendanceId ?? this.attendanceId,
      customerId: customerId,
      isClockedIn: isClockedIn ?? this.isClockedIn,
      lastTimeIn: lastTimeIn ?? this.lastTimeIn,
      lastTimeOut: lastTimeOut ?? this.lastTimeOut,
      verifyingAdminName: verifyingAdminName ?? this.verifyingAdminName,
      verifyingAdminCode: verifyingAdminCode ?? this.verifyingAdminCode,
      statusLabel: statusLabel ?? this.statusLabel,
    );
  }

  factory AttendanceSnapshot.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String && value.trim().isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    bool clockedInFallback(String? status) {
      if (status == null) return false;
      final normalized = status.trim().toLowerCase();
      return normalized == 'in' ||
          normalized == 'time_in' ||
          normalized == 'timed_in' ||
          normalized == 'entered';
    }

    final bool? explicitClockedIn = json['is_clocked_in'] as bool?;
    final String? textualStatus =
        json['status']?.toString() ?? json['state']?.toString();

    return AttendanceSnapshot(
      attendanceId: json['attendance_id'] as int?,
      customerId: json['customer_id'] is String
          ? int.tryParse(json['customer_id'])
          : json['customer_id'] ?? json['id'] ?? 0,
      isClockedIn: explicitClockedIn ?? clockedInFallback(textualStatus),
      lastTimeIn: parseDate(json['last_time_in'] ?? json['time_in']),
      lastTimeOut: parseDate(json['last_time_out'] ?? json['time_out']),
      verifyingAdminName: json['verified_by']?.toString() ??
          json['admin_name']?.toString(),
      verifyingAdminCode: json['admin_code']?.toString(),
      statusLabel: textualStatus,
    );
  }
}

class AttendanceRecord {
  AttendanceRecord({
    required this.customerId,
    required this.customerName,
    required this.status,
    this.attendanceId,
    this.date,
    this.timeIn,
    this.timeOut,
    this.verifyingAdminName,
  });

  final int? attendanceId;
  final int customerId;
  final String customerName;
  final String status;
  final DateTime? date;
  final DateTime? timeIn;
  final DateTime? timeOut;
  final String? verifyingAdminName;

  Duration? get duration =>
      (timeIn != null && timeOut != null)
          ? timeOut!.difference(timeIn!)
          : null;

  String get statusLabel =>
      status.isEmpty ? 'Unknown' : status.toUpperCase() == 'IN' ? 'Timed In' : 'Timed Out';

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String && value.trim().isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    DateTime? parseTime(dynamic value, DateTime? fallbackDate) {
      if (value == null) return null;
      if (value is String && value.trim().isNotEmpty) {
        final sanitized = value.trim();
        if (sanitized.contains('T') || sanitized.contains('-')) {
          return DateTime.tryParse(sanitized);
        }
        if (fallbackDate != null) {
          final segments = sanitized.split(':');
          if (segments.length >= 2) {
            final hours = int.tryParse(segments[0]) ?? 0;
            final minutes = int.tryParse(segments[1]) ?? 0;
            final seconds =
                segments.length > 2 ? int.tryParse(segments[2]) ?? 0 : 0;
            return DateTime(
              fallbackDate.year,
              fallbackDate.month,
              fallbackDate.day,
              hours,
              minutes,
              seconds,
            );
          }
        }
      }
      return null;
    }

    final DateTime? recordDate =
        parseDate(json['date']) ?? parseDate(json['created_at']);

    final String customerName = [
      json['customer_name'],
      json['full_name'],
      json['name'],
    ].firstWhere(
      (element) => element != null && element.toString().trim().isNotEmpty,
      orElse: () => 'Unknown Member',
    ).toString();

    int resolveId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    final String statusRaw =
        json['status']?.toString() ?? json['state']?.toString() ?? '';

    return AttendanceRecord(
      attendanceId: resolveId(json['attendance_id']),
      customerId: resolveId(json['customer_id'] ?? json['id']),
      customerName: customerName,
      status: statusRaw,
      date: recordDate,
      timeIn: parseTime(json['time_in'], recordDate),
      timeOut: parseTime(json['time_out'], recordDate),
      verifyingAdminName:
          json['verified_by']?.toString() ?? json['admin_name']?.toString(),
    );
  }
}

class AttendanceService {
  AttendanceService._();

  static const Duration _httpTimeout = Duration(seconds: 20);
  static final StreamController<AttendanceSnapshot> _updatesController =
      StreamController<AttendanceSnapshot>.broadcast();

  static Stream<AttendanceSnapshot> get updates => _updatesController.stream;

  static String get _attendanceBase => '${ApiService.baseUrl}/attendance';
  static Uri get _statusUri => Uri.parse('$_attendanceBase/getStatus.php');
  static Uri get _scanUri => Uri.parse('$_attendanceBase/recordScan.php');
  static Uri get _logUri => Uri.parse('$_attendanceBase/getLogs.php');

  static Future<AttendanceSnapshot?> fetchSnapshot(int customerId) async {
    try {
      final uri = _statusUri.replace(
        queryParameters: {'customer_id': customerId.toString()},
      );
      final response = await http
          .get(
            uri,
            headers: {'Accept': 'application/json'},
          )
          .timeout(_httpTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;
        final Map<String, dynamic> parsed =
            jsonDecode(response.body) as Map<String, dynamic>;
        final dynamic payload =
            parsed['snapshot'] ?? parsed['data'] ?? parsed['result'];
        if (payload is Map<String, dynamic>) {
          return AttendanceSnapshot.fromJson(payload);
        }
      } else {
        throw AttendanceException('Unable to load attendance status.');
      }
    } catch (e) {
      debugPrint('fetchSnapshot error: $e');
      rethrow;
    }
    return null;
  }

  static Future<List<AttendanceRecord>> fetchRecords({
    DateTime? date,
    String? searchQuery,
  }) async {
    try {
      final params = <String, String>{};
      if (date != null) params['date'] = date.toIso8601String();
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        params['search'] = searchQuery.trim();
      }

      final uri = _logUri.replace(
        queryParameters: params.isEmpty ? null : params,
      );

      final response = await http
          .get(
            uri,
            headers: {'Accept': 'application/json'},
          )
          .timeout(_httpTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return [];
        final dynamic decoded = jsonDecode(response.body);
        final dynamic collection =
            decoded is Map<String, dynamic> ? decoded['data'] : decoded;

        if (collection is List) {
          return collection
              .whereType<Map<String, dynamic>>()
              .map(AttendanceRecord.fromJson)
              .toList();
        }
      } else {
        throw AttendanceException('Unable to load attendance log.');
      }
    } catch (e) {
      debugPrint('fetchRecords error: $e');
      rethrow;
    }
    return [];
  }

  static Future<AttendanceSnapshot> recordScan({
    required int customerId,
    required String adminPayload,
  }) async {
    try {
      final response = await http
          .post(
            _scanUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'customer_id': customerId,
              'admin_payload': adminPayload,
              'platform': _platformDescriptor(),
            }),
          )
          .timeout(_httpTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          throw AttendanceException('Empty server response.');
        }
        final Map<String, dynamic> parsed =
            jsonDecode(response.body) as Map<String, dynamic>;
        if (parsed['success'] == true) {
          final dynamic payload =
              parsed['snapshot'] ?? parsed['data'] ?? parsed['result'];
          if (payload is Map<String, dynamic>) {
            final snapshot = AttendanceSnapshot.fromJson(payload);
            _updatesController.add(snapshot);
            return snapshot;
          }
          throw AttendanceException(
            parsed['message']?.toString() ?? 'Invalid response payload.',
          );
        } else {
          throw AttendanceException(
            parsed['message']?.toString() ?? 'Attendance scan failed.',
          );
        }
      } else {
        throw AttendanceException('Attendance endpoint unavailable.');
      }
    } catch (e) {
      if (e is AttendanceException) rethrow;
      debugPrint('recordScan error: $e');
      throw AttendanceException('Unable to record attendance. Please try again.');
    }
  }

  static String buildAdminQrPayload(Map<String, dynamic> adminData) {
    final dynamic idRaw = adminData['id'] ?? adminData['admin_id'];
    if (idRaw == null) {
      throw AttendanceException('Admin ID missing for QR generation.');
    }

    final int adminId =
        idRaw is int ? idRaw : int.tryParse(idRaw.toString()) ?? 0;

    final String contact =
        adminData['phone_number']?.toString().trim().isNotEmpty == true
            ? adminData['phone_number'].toString()
            : (adminData['email']?.toString() ?? '');

    final String saltSource =
        adminData['updated_at']?.toString() ??
            adminData['created_at']?.toString() ??
            DateTime.now().toIso8601String();

    final payload = <String, dynamic>{
      'issuer': 'RNR_FITNESS',
      'type': 'admin_attendance',
      'adminId': adminId,
      'contact': contact,
      'salt': base64Url.encode(utf8.encode('$contact|$adminId|$saltSource')),
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
    };

    return jsonEncode(payload);
  }

  static Map<String, dynamic>? tryDecodeAdminPayload(String rawValue) {
    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // ignore
    }
    return null;
  }

  static bool isValidAdminPayload(String payload) {
    final decoded = tryDecodeAdminPayload(payload);
    if (decoded == null) return false;
    return decoded['issuer'] == 'RNR_FITNESS' &&
        decoded['type'] == 'admin_attendance' &&
        decoded['adminId'] != null;
  }

  static String _platformDescriptor() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }
}

