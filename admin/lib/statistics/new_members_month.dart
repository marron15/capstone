import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class NewMembersMonthBarGraph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<_BarData> data = [
      _BarData('Week 1', 0),
      _BarData('Week 2', 0),
      _BarData('Week 3', 0),
      _BarData('Week 4', 0),
    ];

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(minimum: 0, interval: 1),
      series: <CartesianSeries>[
        ColumnSeries<_BarData, String>(
          dataSource: data,
          xValueMapper: (_BarData d, _) => d.week,
          yValueMapper: (_BarData d, _) => d.count,
          color: Colors.purple,
          dataLabelSettings: DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }
}

class _BarData {
  final String week;
  final int count;
  _BarData(this.week, this.count);
}
