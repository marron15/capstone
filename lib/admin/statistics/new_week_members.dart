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
    _BarData('Sun', 0),
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
        _BarData('Sun', res['Sunday'] ?? 0),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      primaryYAxis: const NumericAxis(minimum: 0, interval: 1),
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
