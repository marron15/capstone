import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';



class MembershipsTotalBarGraph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<_BarData> data = [
      _BarData('Daily', 0),
      _BarData('Half Month', 0),
      _BarData('1 Month', 0),
    ];

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(minimum: 0, interval: 1),
      series: <CartesianSeries>[
        ColumnSeries<_BarData, String>(
          dataSource: data,
          xValueMapper: (_BarData d, _) => d.day,
          yValueMapper: (_BarData d, _) => d.count,
          color: Colors.green,
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
