import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class NewMembersBarGraph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<_BarData> data = [
      _BarData('Mon', 0),
      _BarData('Tue', 0),
      _BarData('Wed', 0),
      _BarData('Thu', 0),
      _BarData('Fri', 0),
      _BarData('Sat', 0),
    ];

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(minimum: 0, interval: 1),
      series: <CartesianSeries>[
        ColumnSeries<_BarData, String>(
          dataSource: data,
          xValueMapper: (_BarData d, _) => d.day,
          yValueMapper: (_BarData d, _) => d.count,
          color: Colors.blueAccent,
          dataLabelSettings: DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }
}

class _BarData {
  final String day;
  final int count;
  _BarData(this.day, this.count);
}