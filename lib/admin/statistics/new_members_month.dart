import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/api_service.dart';

class NewMembersMonthBarGraph extends StatefulWidget {
  const NewMembersMonthBarGraph({super.key});

  @override
  State<NewMembersMonthBarGraph> createState() =>
      _NewMembersMonthBarGraphState();
}

class _NewMembersMonthBarGraphState extends State<NewMembersMonthBarGraph> {
  List<_BarData> _data = const [
    _BarData('Week 1', 0),
    _BarData('Week 2', 0),
    _BarData('Week 3', 0),
    _BarData('Week 4', 0),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Map<String, int> res = await ApiService.getNewMembersThisMonth();
    // Build week ranges for current month
    final DateTime now = DateTime.now();
    final int year = now.year;
    final int month = now.month;
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    String rng(int s, int e) => '$s-${e > daysInMonth ? daysInMonth : e}';
    final String w1 = rng(1, 7);
    final String w2 = rng(8, 14);
    final String w3 = rng(15, 21);
    final String w4 = rng(22, daysInMonth);
    setState(() {
      _data = [
        _BarData('Week 1 ($w1)', res['1'] ?? res['Week 1'] ?? 0),
        _BarData('Week 2 ($w2)', res['2'] ?? res['Week 2'] ?? 0),
        _BarData('Week 3 ($w3)', res['3'] ?? res['Week 3'] ?? 0),
        _BarData('Week 4 ($w4)', res['4'] ?? res['Week 4'] ?? 0),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    // Helper removed; ranges are computed during load and embedded in labels
    String monthLabel(DateTime d) {
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
      return months[d.month - 1];
    }

    final DateTime nowD = DateTime.now();
    final String subtitle = monthLabel(nowD);
    return SfCartesianChart(
      title: ChartTitle(
        text: subtitle,
        alignment: ChartAlignment.near,
        textStyle: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      primaryXAxis: const CategoryAxis(),
      primaryYAxis: const NumericAxis(minimum: 0, maximum: 50, interval: 10),
      series: <CartesianSeries>[
        ColumnSeries<_BarData, String>(
          dataSource: _data,
          xValueMapper: (_BarData d, _) => d.week,
          yValueMapper: (_BarData d, _) => d.count,
          color: Colors.purple,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }
}

class _BarData {
  final String week;
  final int count;
  const _BarData(this.week, this.count);
}
