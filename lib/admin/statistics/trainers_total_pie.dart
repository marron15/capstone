import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TrainersTotalPieChart extends StatelessWidget {
  const TrainersTotalPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    final List<PieData> data = [PieData('Total', 0, Colors.blue)];
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: SfCartesianChart(
        legend: const Legend(isVisible: false),
        primaryXAxis: const CategoryAxis(),
        primaryYAxis: const NumericAxis(minimum: 0),
        series: <ColumnSeries<PieData, String>>[
          ColumnSeries<PieData, String>(
            dataSource: data,
            xValueMapper: (PieData d, _) => d.label,
            yValueMapper: (PieData d, _) => d.value,
            pointColorMapper: (PieData d, _) => d.color,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            width: 0.6,
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
