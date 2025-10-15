import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class NewMembersTodayBarGraph extends StatefulWidget {
  final int daily;
  final int halfMonth;
  final int monthly;
  final int expired;
  const NewMembersTodayBarGraph({
    super.key,
    required this.daily,
    required this.halfMonth,
    required this.monthly,
    required this.expired,
  });

  @override
  State<NewMembersTodayBarGraph> createState() =>
      _NewMembersTodayBarGraphState();
}

class _NewMembersTodayBarGraphState extends State<NewMembersTodayBarGraph> {
  late List<_BarData> _data;
  int _yMax = 10;

  @override
  void initState() {
    super.initState();
    _buildData();
  }

  @override
  void didUpdateWidget(covariant NewMembersTodayBarGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.daily != widget.daily ||
        oldWidget.halfMonth != widget.halfMonth ||
        oldWidget.monthly != widget.monthly ||
        oldWidget.expired != widget.expired) {
      _buildData();
    }
  }

  void _buildData() {
    _data = [
      _BarData('Daily', widget.daily),
      _BarData('Half Month', widget.halfMonth),
      _BarData('Monthly', widget.monthly),
      _BarData('Expired', widget.expired),
    ];
    final int maxVal = _data
        .map((e) => e.count)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final int total = _data.fold<int>(0, (sum, e) => sum + e.count);
    // Round up to nearest 20 based on larger of max bar or total; minimum 10
    final int basis = maxVal > total ? maxVal : total;
    final int rounded = basis <= 10 ? 10 : ((basis + 19) ~/ 20) * 20;
    _yMax = rounded;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      title: ChartTitle(
        text: 'New Memberships Today',
        alignment: ChartAlignment.near,
        textStyle: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      primaryXAxis: const CategoryAxis(),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: _yMax.toDouble(),
        interval: (_yMax / 5).ceilToDouble(),
      ),
      series: <CartesianSeries>[
        ColumnSeries<_BarData, String>(
          dataSource: _data,
          xValueMapper: (_BarData d, _) => d.label,
          yValueMapper: (_BarData d, _) => d.count,
          pointColorMapper: (_BarData d, _) {
            switch (d.label) {
              case 'Half Month':
                return Colors.blue;
              case 'Monthly':
                return Colors.green;
              case 'Expired':
                return Colors.red;
              default:
                return Colors.orange;
            }
          },
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }
}

class _BarData {
  final String label;
  final int count;
  const _BarData(this.label, this.count);
}
