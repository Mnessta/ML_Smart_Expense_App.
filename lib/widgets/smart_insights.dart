import 'package:flutter/material.dart';
import '../models/expense_model.dart';

class SmartInsights extends StatelessWidget {
  const SmartInsights({
    super.key,
    required this.currentExpenses,
    required this.previousExpenses,
  });

  final List<ExpenseModel> currentExpenses;
  final List<ExpenseModel> previousExpenses;

  String _generateInsight() {
    final double currentTotal = currentExpenses
        .where((ExpenseModel e) => e.type == TransactionType.expense)
        .fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);
    
    final double previousTotal = previousExpenses
        .where((ExpenseModel e) => e.type == TransactionType.expense)
        .fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);

    if (previousTotal == 0) {
      if (currentTotal == 0) {
        return 'Start tracking your expenses to get insights!';
      }
      return 'Great start! Keep tracking your expenses.';
    }

    final double change = ((currentTotal - previousTotal) / previousTotal) * 100;
    
    if (change < -10) {
      return '🎉 You spent ${change.abs().toStringAsFixed(0)}% less — keep it up!';
    } else if (change > 10) {
      return '⚠️ You spent ${change.toStringAsFixed(0)}% more than before.';
    } else {
      return '✅ Your spending is consistent — great job!';
    }
  }

  IconData _getInsightIcon() {
    final double currentTotal = currentExpenses
        .where((ExpenseModel e) => e.type == TransactionType.expense)
        .fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);
    
    final double previousTotal = previousExpenses
        .where((ExpenseModel e) => e.type == TransactionType.expense)
        .fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);

    if (previousTotal == 0) return Icons.trending_flat;
    
    final double change = ((currentTotal - previousTotal) / previousTotal) * 100;
    
    if (change < -10) return Icons.trending_down;
    if (change > 10) return Icons.trending_up;
    return Icons.trending_flat;
  }

  Color _getInsightColor(BuildContext context) {
    final double currentTotal = currentExpenses
        .where((ExpenseModel e) => e.type == TransactionType.expense)
        .fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);
    
    final double previousTotal = previousExpenses
        .where((ExpenseModel e) => e.type == TransactionType.expense)
        .fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);

    if (previousTotal == 0) return Colors.blue;
    
    final double change = ((currentTotal - previousTotal) / previousTotal) * 100;
    
    if (change < -10) return Colors.green;
    if (change > 10) return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final String insight = _generateInsight();
    final IconData icon = _getInsightIcon();
    final Color color = _getInsightColor(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                insight,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

