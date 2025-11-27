import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/expense_model.dart';

class SpendingTrendsChart extends StatelessWidget {
  const SpendingTrendsChart({
    super.key,
    required this.expenses,
    required this.incomes,
    this.linkedIncome,
  });

  final List<ExpenseModel> expenses;
  final List<ExpenseModel> incomes;
  final double? linkedIncome;

  List<FlSpot> _generateSpots(List<ExpenseModel> transactions, int days) {
    final Map<int, double> dailyTotals = <int, double>{};
    final DateTime now = DateTime.now();
    
    for (int i = 0; i < days; i++) {
      dailyTotals[i] = 0.0;
    }

    for (final ExpenseModel transaction in transactions) {
      final int daysDiff = now.difference(transaction.date).inDays;
      if (daysDiff >= 0 && daysDiff < days) {
        final int index = days - 1 - daysDiff;
        dailyTotals[index] = (dailyTotals[index] ?? 0) + transaction.amount;
      }
    }

    return dailyTotals.entries
        .map((MapEntry<int, double> entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
  }

  List<FlSpot> _generateBalanceSpots(int days) {
    if (linkedIncome == null || linkedIncome == 0) {
      return <FlSpot>[];
    }
    final DateTime now = DateTime.now();
    double remaining = linkedIncome!;
    final List<FlSpot> spots = <FlSpot>[];
    for (int i = 0; i < days; i++) {
      final DateTime day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days - 1 - i));
      final double dailySpent = expenses
          .where((ExpenseModel e) =>
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day)
          .fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);
      remaining -= dailySpent;
      if (remaining < 0) {
        remaining = 0;
      }
      spots.add(FlSpot(i.toDouble(), remaining));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> expenseSpots = _generateSpots(expenses, 7);
    final List<FlSpot> incomeSpots = _generateSpots(incomes, 7);
    final List<FlSpot> balanceSpots = _generateBalanceSpots(7);
    
    final List<double> yValues = <double>[
      ...expenseSpots.map((FlSpot s) => s.y),
      ...incomeSpots.map((FlSpot s) => s.y),
      ...balanceSpots.map((FlSpot s) => s.y),
      if (linkedIncome != null && linkedIncome! > 0) linkedIncome!,
    ];
    final double maxY = yValues.isEmpty
        ? 100
        : yValues.reduce((double a, double b) => a > b ? a : b);

    final List<LineChartBarData> series = <LineChartBarData>[
      LineChartBarData(
        spots: expenseSpots,
        isCurved: true,
        color: Colors.red,
        barWidth: 3,
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.red.withValues(alpha: 0.1),
        ),
      ),
      LineChartBarData(
        spots: incomeSpots,
        isCurved: true,
        color: Colors.green,
        barWidth: 3,
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.green.withValues(alpha: 0.1),
        ),
      ),
    ];

    if (balanceSpots.isNotEmpty) {
      series.add(
        LineChartBarData(
          spots: balanceSpots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: false,
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: series,
        minY: 0,
        maxY: maxY * 1.2,
      ),
    );
  }
}

