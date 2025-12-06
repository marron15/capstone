import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class NewMembersMonthBarGraph extends StatelessWidget {
  final List<Map<String, dynamic>> customers;
  final DateTimeRange range;
  const NewMembersMonthBarGraph({
    super.key,
    required this.customers,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final DateTime end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
    );

    String _fmt(DateTime d) =>
        '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

    List<_BarData> _buildData() {
      final List<_Bucket> buckets = [];
      DateTime cursor = start;
      int bucketIndex = 1;

      while (!cursor.isAfter(end) && buckets.length < 6) {
        final DateTime bucketEnd = cursor.add(const Duration(days: 6));
        buckets.add(
          _Bucket(
            label: 'Week $bucketIndex (${_fmt(cursor)} - ${_fmt(bucketEnd.isAfter(end) ? end : bucketEnd)})',
            start: cursor,
            end: bucketEnd.isAfter(end) ? end : bucketEnd,
          ),
        );
        bucketIndex++;
        cursor = bucketEnd.add(const Duration(days: 1));
      }

      for (final customer in customers) {
        final DateTime? membershipStart = _extractStartDate(customer);
        if (membershipStart == null) continue;
        if (membershipStart.isBefore(start) || membershipStart.isAfter(end)) {
          continue;
        }
        for (int i = 0; i < buckets.length; i++) {
          final _Bucket bucket = buckets[i];
          if (!membershipStart.isBefore(bucket.start) &&
              !membershipStart.isAfter(bucket.end)) {
            buckets[i] = bucket.copyWith(count: bucket.count + 1);
            break;
          }
        }
      }

      return buckets
          .map((b) => _BarData(b.label, b.count))
          .toList(growable: false);
    }

    final List<_BarData> data = _buildData();
    final int maxCount = data.fold<int>(0, (max, d) => d.count > max ? d.count : max);
    final double yMax = (maxCount <= 10 ? 10 : ((maxCount + 9) ~/ 10) * 10)
        .toDouble();

    return SfCartesianChart(
      title: ChartTitle(
        text: 'Selected Range (${_fmt(start)} - ${_fmt(end)})',
        alignment: ChartAlignment.near,
        textStyle: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      primaryXAxis: const CategoryAxis(),
      primaryYAxis: NumericAxis(minimum: 0, maximum: yMax, interval: yMax / 5),
      series: <CartesianSeries>[
        ColumnSeries<_BarData, String>(
          dataSource: data,
          xValueMapper: (_BarData d, _) => d.week,
          yValueMapper: (_BarData d, _) => d.count,
          color: Colors.purple,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }

  DateTime? _extractStartDate(Map<String, dynamic> customer) {
    final dynamic direct = customer['startDate'] ?? customer['start_date'];
    if (direct is DateTime) return direct;
    if (direct is String && direct.isNotEmpty) {
      return DateTime.tryParse(direct);
    }
    final dynamic membership = customer['membership'];
    if (membership is Map<String, dynamic>) {
      final dynamic nested = membership['start_date'] ?? membership['startDate'];
      if (nested is DateTime) return nested;
      if (nested is String && nested.isNotEmpty) {
        return DateTime.tryParse(nested);
      }
    }
    return null;
  }
}

class _Bucket {
  final String label;
  final DateTime start;
  final DateTime end;
  final int count;
  const _Bucket({
    required this.label,
    required this.start,
    required this.end,
    this.count = 0,
  });

  _Bucket copyWith({int? count}) => _Bucket(
        label: label,
        start: start,
        end: end,
        count: count ?? this.count,
      );
}

class _BarData {
  final String week;
  final int count;
  const _BarData(this.week, this.count);
}
