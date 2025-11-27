import 'package:flutter/material.dart';
import '../models/expense_model.dart';

class SmartSummaryBar extends StatelessWidget {
  const SmartSummaryBar({
    super.key,
    required this.currentExpenses,
    required this.previousExpenses,
    required this.categoryBreakdown,
  });

  final List<ExpenseModel> currentExpenses;
  final List<ExpenseModel> previousExpenses;
  final Map<String, double> categoryBreakdown;

  String _getSpendingComparison() {
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
      return 'You spent ${change.abs().toStringAsFixed(0)}% less than last month 🎉';
    } else if (change > 10) {
      return 'You spent ${change.toStringAsFixed(0)}% more than last month ⚠️';
    } else {
      return 'Your spending is consistent — great job! ✅';
    }
  }

  String _getTopCategory() {
    if (categoryBreakdown.isEmpty) {
      return 'No spending yet';
    }

    final MapEntry<String, double> topCategory = categoryBreakdown.entries
        .reduce((MapEntry<String, double> a, MapEntry<String, double> b) => 
            a.value > b.value ? a : b);

    final String emoji = _getCategoryEmoji(topCategory.key);
    return 'Most spent on: ${topCategory.key} $emoji';
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍔';
      case 'bills':
        return '💡';
      case 'transport':
        return '🚗';
      case 'shopping':
        return '🛍️';
      case 'entertainment':
        return '🎬';
      case 'health':
        return '🏥';
      case 'education':
        return '📚';
      default:
        return '💰';
    }
  }

  Color _getSummaryColor() {
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getSummaryColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getSummaryColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _getSpendingComparison(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _getSummaryColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getTopCategory(),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

















