import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MembershipsTotalBarGraph extends StatefulWidget {
  final int daily;
  final int halfMonth;
  final int monthly;
  final int expired; // total expired memberships (all plans)
  const MembershipsTotalBarGraph({
    super.key,
    required this.daily,
    required this.halfMonth,
    required this.monthly,
    required this.expired,
  });

  @override
  State<MembershipsTotalBarGraph> createState() =>
      _MembershipsTotalBarGraphState();
}

class _MembershipsTotalBarGraphState extends State<MembershipsTotalBarGraph> {
  List<_BarData> _data = const [
    _BarData('Daily', 0),
    _BarData('Half Month', 0),
    _BarData('Monthly', 0),
    _BarData('Expired', 0),
  ];
  int _yMax = 100;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _data = [
        _BarData('Daily', widget.daily),
        _BarData('Half Month', widget.halfMonth),
        _BarData('Monthly', widget.monthly),
        _BarData('Expired', widget.expired),
      ];
      final int maxVal = _data
          .map((e) => e.count)
          .fold<int>(0, (a, b) => a > b ? a : b);
      final int needed = maxVal <= 100 ? 100 : ((maxVal + 49) ~/ 50) * 50;
      _yMax = needed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int total = _data.fold<int>(0, (sum, e) => sum + e.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SfCartesianChart(
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
                // Color per category: Daily = Orange, Half Month = Blue, Monthly = Green, Expired = Red
                pointColorMapper: (_BarData d, _) {
                  switch (d.day) {
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
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Total memberships: $total',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
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
