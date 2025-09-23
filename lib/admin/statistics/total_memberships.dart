import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/api_service.dart';

class MembershipsTotalBarGraph extends StatefulWidget {
  const MembershipsTotalBarGraph({super.key});

  @override
  State<MembershipsTotalBarGraph> createState() =>
      _MembershipsTotalBarGraphState();
}

class _MembershipsTotalBarGraphState extends State<MembershipsTotalBarGraph> {
  List<_BarData> _data = const [
    _BarData('Daily', 0),
    _BarData('Half Month', 0),
    _BarData('Monthly', 0),
  ];
  int _yMax = 100;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Map<String, int> res = await ApiService.getMembershipTotals();
    setState(() {
      _data = [
        _BarData('Daily', res['Daily'] ?? 0),
        _BarData('Half Month', res['Half Month'] ?? 0),
        _BarData('Monthly', res['Monthly'] ?? 0),
      ];
      final int maxVal = _data
          .map((e) => e.count)
          .fold<int>(0, (a, b) => a > b ? a : b);
      // Base at 100, then jump to the next 50 when exceeding
      final int needed = maxVal <= 100 ? 100 : ((maxVal + 49) ~/ 50) * 50;
      _yMax = needed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: _yMax.toDouble(),
        interval: _yMax <= 100 ? 10 : 25,
      ),
      series: <CartesianSeries>[
        ColumnSeries<_BarData, String>(
          dataSource: _data,
          xValueMapper: (_BarData d, _) => d.day,
          yValueMapper: (_BarData d, _) => d.count,
          color: Colors.green,
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
