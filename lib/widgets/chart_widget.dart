import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SimplePieChart extends StatefulWidget {
  const SimplePieChart({super.key, this.data});

  final Map<String, double>? data;

  @override
  State<SimplePieChart> createState() => _SimplePieChartState();
}

class _SimplePieChartState extends State<SimplePieChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, double> chartData = widget.data ?? <String, double>{
      'Food': 40,
      'Bills': 25,
      'Transport': 20,
      'Other': 15,
    };

    final List<Color> colors = <Color>[Colors.blue, Colors.purple, Colors.teal, Colors.orange];
    int colorIndex = 0;

    final List<MapEntry<String, double>> entries = chartData.entries.toList();
    final double total = entries.fold(0.0, (double sum, MapEntry<String, double> entry) => sum + entry.value.abs());

    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        colorIndex = 0;
        final List<_LegendItemData> legendItems = <_LegendItemData>[];

        final pieSections = entries.map((MapEntry<String, double> entry) {
          final Color color = colors[colorIndex % colors.length];
          colorIndex++;
          final double percentage = total > 0 ? ((entry.value.abs() / total) * 100).clamp(0, 100) : 0;

          // Collect legend data so even tiny slices have readable labels outside the pie
          legendItems.add(
            _LegendItemData(
              label: entry.key,
              percentage: percentage,
              color: color,
            ),
          );

          final bool showInsideLabel = percentage >= 8;

          return PieChartSectionData(
            value: percentage * _animation.value,
            color: color,
            title: showInsideLabel ? '${entry.key}\n${percentage.toStringAsFixed(0)}%' : '',
            radius: 60,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          );
        }).toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 32,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {},
                  ),
                  sections: pieSections,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: legendItems.map((item) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.label} (${item.percentage.toStringAsFixed(0)}%)',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _LegendItemData {
  const _LegendItemData({
    required this.label,
    required this.percentage,
    required this.color,
  });

  final String label;
  final double percentage;
  final Color color;
}






