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
    setState(() {
      _data = [
        _BarData('Week 1', res['1'] ?? res['Week 1'] ?? 0),
        _BarData('Week 2', res['2'] ?? res['Week 2'] ?? 0),
        _BarData('Week 3', res['3'] ?? res['Week 3'] ?? 0),
        _BarData('Week 4', res['4'] ?? res['Week 4'] ?? 0),
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
