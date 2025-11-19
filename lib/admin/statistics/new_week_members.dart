import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class NewMembersBarGraph extends StatelessWidget {
  final List<Map<String, dynamic>> customers;
  const NewMembersBarGraph({super.key, required this.customers});

  @override
  Widget build(BuildContext context) {
    List<_BarData> _buildData() {
      final DateTime now = DateTime.now();
      final DateTime startOfWeek = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - DateTime.monday));
      final DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));
      final Map<int, int> counts = {
        DateTime.monday: 0,
        DateTime.tuesday: 0,
        DateTime.wednesday: 0,
        DateTime.thursday: 0,
        DateTime.friday: 0,
        DateTime.saturday: 0,
        DateTime.sunday: 0,
      };

      for (final customer in customers) {
        final DateTime? start = _extractStartDate(customer);
        if (start == null) continue;
        if (start.isBefore(startOfWeek) || !start.isBefore(endOfWeek)) continue;
        counts[start.weekday] = (counts[start.weekday] ?? 0) + 1;
      }

      return [
        _BarData('Mon', counts[DateTime.monday] ?? 0),
        _BarData('Tue', counts[DateTime.tuesday] ?? 0),
        _BarData('Wed', counts[DateTime.wednesday] ?? 0),
        _BarData('Thu', counts[DateTime.thursday] ?? 0),
        _BarData('Fri', counts[DateTime.friday] ?? 0),
        _BarData('Sat', counts[DateTime.saturday] ?? 0),
        _BarData('Sun', counts[DateTime.sunday] ?? 0),
      ];
    }

    String _formatWeekRange(DateTime date) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final DateTime start =
          date.subtract(Duration(days: date.weekday - DateTime.monday));
      final DateTime end = start.add(const Duration(days: 6));
      String fmt(DateTime d) => '${months[d.month - 1]} ${d.day}';
      return '${fmt(start)} - ${fmt(end)}';
    }

    final String subtitle = _formatWeekRange(DateTime.now());
    final List<_BarData> data = _buildData();
    final int maxCount = data.fold<int>(0, (max, d) => d.count > max ? d.count : max);
    final double yMax = (maxCount <= 10 ? 10 : ((maxCount + 9) ~/ 10) * 10)
        .toDouble();

    return SfCartesianChart(
      title: ChartTitle(
        text: subtitle,
        alignment: ChartAlignment.near,
        textStyle: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      primaryXAxis: const CategoryAxis(),
      primaryYAxis: NumericAxis(minimum: 0, maximum: yMax, interval: yMax / 5),
      series: <CartesianSeries>[
        ColumnSeries<_BarData, String>(
          dataSource: data,
          xValueMapper: (_BarData d, _) => d.day,
          yValueMapper: (_BarData d, _) => d.count,
          color: Colors.blueAccent,
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
  final String day;
  final int count;
  const _BarData(this.day, this.count);
}
