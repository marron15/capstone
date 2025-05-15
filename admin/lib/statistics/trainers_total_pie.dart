import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TrainersTotalPieChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<PieData> data = [
      PieData('Personal', 0, Colors.orange),
      PieData('Group', 0, Colors.blue),
      PieData('Online', 0, Colors.green),
    ];
    return SizedBox(
      width: 350,
      height: 350,
      child: SfCircularChart(
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        series: <PieSeries<PieData, String>>[
          PieSeries<PieData, String>(
            dataSource: data,
            xValueMapper: (PieData d, _) => d.label,
            yValueMapper: (PieData d, _) => d.value,
            pointColorMapper: (PieData d, _) => d.color,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
            radius: '98%',
          ),
        ],
      ),
    );
  }
}

class PieData {
  final String label;
  final double value;
  final Color color;
  PieData(this.label, this.value, this.color);
} 