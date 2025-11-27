import 'package:flutter/material.dart';
import '../models/expense_model.dart';

class ExpenseInsights extends StatelessWidget {
  const ExpenseInsights({
    super.key,
    required this.expenses,
  });

  final List<ExpenseModel> expenses;

  Future<List<Map<String, dynamic>>> _generateInsights() async {
    final List<Map<String, dynamic>> insights = <Map<String, dynamic>>[];

    // Analyze recurring payments
    final Map<String, List<ExpenseModel>> categoryExpenses = <String, List<ExpenseModel>>{};
    for (final ExpenseModel expense in expenses) {
      if (expense.type == TransactionType.expense) {
        if (!categoryExpenses.containsKey(expense.category)) {
          categoryExpenses[expense.category] = <ExpenseModel>[];
        }
        categoryExpenses[expense.category]!.add(expense);
      }
    }

    // Find weekly recurring patterns
    for (final MapEntry<String, List<ExpenseModel>> entry in categoryExpenses.entries) {
      if (entry.value.length >= 4) {
        // Check if expenses are roughly weekly
        final List<ExpenseModel> sorted = List<ExpenseModel>.from(entry.value)
          ..sort((ExpenseModel a, ExpenseModel b) => a.date.compareTo(b.date));
        
        final double avgAmount = sorted.fold(0.0, (double sum, ExpenseModel e) => sum + e.amount) / sorted.length;
        final double weeklyTotal = avgAmount * 4; // Approximate monthly
        
        if (weeklyTotal > 100) {
          insights.add(<String, dynamic>{
            'type': 'recurring',
            'category': entry.key,
            'amount': weeklyTotal,
            'message': 'You spend \$${weeklyTotal.toStringAsFixed(0)} weekly on ${entry.key} — consider carpooling or bulk buying',
          });
        }
      }
    }

    // Budget forecast
    final DateTime now = DateTime.now();
    final DateTime lastMonth = DateTime(now.year, now.month - 1, 1);
    final DateTime thisMonth = DateTime(now.year, now.month, 1);
    
    final List<ExpenseModel> lastMonthExpenses = expenses.where((ExpenseModel e) {
      return e.date.isAfter(lastMonth) && e.date.isBefore(thisMonth) && e.type == TransactionType.expense;
    }).toList();
    
    if (lastMonthExpenses.isNotEmpty) {
      final double lastMonthTotal = lastMonthExpenses.fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);
      insights.add(<String, dynamic>{
        'type': 'forecast',
        'message': 'Based on last month, you might spend around \$${lastMonthTotal.toStringAsFixed(0)} this month',
      });
    }

    return insights;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _generateInsights(),
      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final List<Map<String, dynamic>> insights = snapshot.data!;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.lightbulb, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Smart Insights',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...insights.take(3).map((Map<String, dynamic> insight) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.amber.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            insight['message'] as String,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

