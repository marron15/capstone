import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LandingVisitStats {
  final int visitCount;
  final DateTime? lastVisited;

  const LandingVisitStats({required this.visitCount, this.lastVisited});

  factory LandingVisitStats.fromJson(Map<String, dynamic> json) {
    final dynamic countRaw = json['visit_count'];
    final int count =
        countRaw is int
            ? countRaw
            : int.tryParse(countRaw?.toString() ?? '') ?? 0;

    DateTime? lastVisited;
    final String? lastRaw = json['last_visited']?.toString();
    if (lastRaw != null && lastRaw.isNotEmpty) {
      lastVisited = DateTime.tryParse(lastRaw);
    }

    return LandingVisitStats(visitCount: count, lastVisited: lastVisited);
  }
}

class LandingVisitService {
  static String _apiHost() => 'rnrgym.com';

  static String get _landingBase =>
      'https://${_apiHost()}/gym_api/landingPageVisitCount';

  static Future<LandingVisitStats?> fetchStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_landingBase/getLandingVisitStats.php'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        debugPrint(
          'LandingVisitService.fetchStats: HTTP ${response.statusCode} ${response.body}',
        );
        return null;
      }

      final Map<String, dynamic> body = json.decode(response.body);
      if (body['success'] != true || body['data'] is! Map) {
        debugPrint('LandingVisitService.fetchStats: ${body['message']}');
        return null;
      }

      return LandingVisitStats.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    } catch (e) {
      debugPrint('LandingVisitService.fetchStats: $e');
      return null;
    }
  }

  /// Records one landing-page visit and returns updated stats.
  static Future<LandingVisitStats?> recordVisit() async {
    try {
      final response = await http.post(
        Uri.parse('$_landingBase/recordLandingVisit.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({}),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'LandingVisitService.recordVisit: HTTP ${response.statusCode} ${response.body}',
        );
        return null;
      }

      final Map<String, dynamic> body = json.decode(response.body);
      if (body['success'] != true || body['data'] is! Map) {
        debugPrint('LandingVisitService.recordVisit: ${body['message']}');
        return null;
      }

      return LandingVisitStats.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    } catch (e) {
      debugPrint('LandingVisitService.recordVisit: $e');
      return null;
    }
  }
}
