import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_model.dart';
import '../providers/currency_provider.dart';

class EditableDailySpendingChart extends StatefulWidget {
  const EditableDailySpendingChart({
    super.key,
    required this.expenses,
    required this.timeFilter,
    this.onLimitUpdated,
  });

  final List<ExpenseModel> expenses;
  final String timeFilter; // 'day', 'week', 'month'
  final void Function(double)? onLimitUpdated;

  @override
  State<EditableDailySpendingChart> createState() => _EditableDailySpendingChartState();
}

class _EditableDailySpendingChartState extends State<EditableDailySpendingChart> {
  bool _isEditingLimit = false;
  final TextEditingController _limitController = TextEditingController();
  double _dailyLimit = 0;

  @override
  void initState() {
    super.initState();
    _loadDailyLimit();
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyLimit() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final double? savedLimit = prefs.getDouble('dailySpendingLimit');
    if (savedLimit != null) {
      setState(() {
        _dailyLimit = savedLimit;
        _limitController.text = savedLimit.toStringAsFixed(2);
      });
    }
  }

  Future<void> _saveLimit() async {
    final double? newLimit = double.tryParse(_limitController.text);
    if (newLimit != null && newLimit >= 0) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('dailySpendingLimit', newLimit);
      if (mounted) {
        setState(() {
          _dailyLimit = newLimit;
          _isEditingLimit = false;
        });
        widget.onLimitUpdated?.call(newLimit);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily spending limit updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<FlSpot> _generateSpots() {
    final DateTime now = DateTime.now();
    final int days = widget.timeFilter == 'day' ? 7 : (widget.timeFilter == 'week' ? 7 : 30);
    
    final Map<int, double> dailyTotals = <int, double>{};
    
    for (int i = 0; i < days; i++) {
      dailyTotals[i] = 0.0;
    }

    for (final ExpenseModel expense in widget.expenses) {
      if (expense.type == TransactionType.expense) {
        final int daysDiff = now.difference(expense.date).inDays;
        if (daysDiff >= 0 && daysDiff < days) {
          final int index = days - 1 - daysDiff;
          dailyTotals[index] = (dailyTotals[index] ?? 0) + expense.amount;
        }
      }
    }

    return dailyTotals.entries
        .map((MapEntry<int, double> entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final CurrencyProvider currency = context.watch<CurrencyProvider>();
    final List<FlSpot> spots = _generateSpots();
    final double maxY = spots.isEmpty 
        ? (_dailyLimit > 0 ? _dailyLimit * 1.2 : 100.0)
        : (spots.map((FlSpot s) => s.y).reduce((double a, double b) => a > b ? a : b) * 1.2).clamp(0.0, _dailyLimit > 0 ? _dailyLimit * 1.5 : double.infinity);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Daily Spending',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Row(
                children: <Widget>[
                  if (_dailyLimit > 0 && !_isEditingLimit)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Limit: ${currency.symbol}${_dailyLimit.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (!_isEditingLimit)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        setState(() {
                          _isEditingLimit = true;
                          if (_dailyLimit == 0) {
                            _limitController.clear();
                          }
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
          if (_isEditingLimit)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _limitController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Daily Spending Limit',
                        prefixText: currency.symbol,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: _saveLimit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _isEditingLimit = false;
                        _limitController.text = _dailyLimit.toStringAsFixed(2);
                      });
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (double value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Day ${value.toInt() + 1}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '${currency.symbol}${value.toInt()}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                    left: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                ),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (FlSpot spot, double percent, LineChartBarData bar, int index) {
                        final bool isOverLimit = _dailyLimit > 0 && spot.y > _dailyLimit;
                        return FlDotCirclePainter(
                          radius: 4,
                          color: isOverLimit ? Colors.red : Theme.of(context).colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  if (_dailyLimit > 0)
                    LineChartBarData(
                      spots: <FlSpot>[
                        FlSpot(0, _dailyLimit),
                        FlSpot(spots.isNotEmpty ? spots.last.x : 30, _dailyLimit),
                      ],
                      isCurved: false,
                      color: Colors.orange,
                      barWidth: 2,
                      dashArray: <int>[5, 5],
                      dotData: const FlDotData(show: false),
                    ),
                ],
                minY: 0,
                maxY: maxY,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

















