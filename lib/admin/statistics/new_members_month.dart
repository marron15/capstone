import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class NewMembersMonthBarGraph extends StatelessWidget {
  final List<Map<String, dynamic>> customers;
  const NewMembersMonthBarGraph({super.key, required this.customers});

  @override
  Widget build(BuildContext context) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final DateTime now = DateTime.now();
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    List<_BarData> _buildData() {
      String range(int start, int end) =>
          '$start-${end > daysInMonth ? daysInMonth : end}';

      final Map<int, int> buckets = {1: 0, 2: 0, 3: 0, 4: 0};
      for (final customer in customers) {
        final DateTime? start = _extractStartDate(customer);
        if (start == null) continue;
        if (start.year != now.year || start.month != now.month) continue;
        final int day = start.day;
        final int bucket =
            day <= 7 ? 1 : day <= 14 ? 2 : day <= 21 ? 3 : 4;
        buckets[bucket] = (buckets[bucket] ?? 0) + 1;
      }

      return [
        _BarData('Week 1 (${range(1, 7)})', buckets[1] ?? 0),
        _BarData('Week 2 (${range(8, 14)})', buckets[2] ?? 0),
        _BarData('Week 3 (${range(15, 21)})', buckets[3] ?? 0),
        _BarData('Week 4 (${range(22, daysInMonth)})', buckets[4] ?? 0),
      ];
    }

    final List<_BarData> data = _buildData();
    final int maxCount = data.fold<int>(0, (max, d) => d.count > max ? d.count : max);
    final double yMax = (maxCount <= 10 ? 10 : ((maxCount + 9) ~/ 10) * 10)
        .toDouble();

    return SfCartesianChart(
      title: ChartTitle(
        text: months[now.month - 1],
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

class _BarData {
  final String week;
  final int count;
  const _BarData(this.week, this.count);
}
