import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/api_service.dart';

class NewMembersBarGraph extends StatefulWidget {
  const NewMembersBarGraph({super.key});

  @override
  State<NewMembersBarGraph> createState() => _NewMembersBarGraphState();
}

class _NewMembersBarGraphState extends State<NewMembersBarGraph> {
  List<_BarData> _data = const [
    _BarData('Mon', 0),
    _BarData('Tue', 0),
    _BarData('Wed', 0),
    _BarData('Thu', 0),
    _BarData('Fri', 0),
    _BarData('Sat', 0),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Map<String, int> res = await ApiService.getNewMembersThisWeek();
    setState(() {
      _data = [
        _BarData('Mon', res['Monday'] ?? 0),
        _BarData('Tue', res['Tuesday'] ?? 0),
        _BarData('Wed', res['Wednesday'] ?? 0),
        _BarData('Thu', res['Thursday'] ?? 0),
        _BarData('Fri', res['Friday'] ?? 0),
        _BarData('Sat', res['Saturday'] ?? 0),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
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
      final int weekday = date.weekday; // 1=Mon .. 7=Sun
      final DateTime start = date.subtract(Duration(days: weekday - 1));
      final DateTime end = start.add(const Duration(days: 6));
      String fmt(DateTime d) => '${months[d.month - 1]} ${d.day}';
      return '${fmt(start)} - ${fmt(end)}';
    }

    final String subtitle = _formatWeekRange(DateTime.now());
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
          xValueMapper: (_BarData d, _) => d.day,
          yValueMapper: (_BarData d, _) => d.count,
          color: Colors.blueAccent,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }
}

class _BarData {
  final String day;
  final int count;
  const _BarData(this.day, this.count);
}
