import 'package:flutter/material.dart';
import '../models/budget_model.dart';

class SmartAlerts extends StatelessWidget {
  const SmartAlerts({
    super.key,
    required this.budgets,
  });

  final List<BudgetModel> budgets;

  List<Map<String, dynamic>> _getAlerts() {
    final List<Map<String, dynamic>> alerts = <Map<String, dynamic>>[];

    for (final BudgetModel budget in budgets) {
      final double percentage = budget.progress * 100;
      
      if (percentage >= 100) {
        alerts.add(<String, dynamic>{
          'type': 'over',
          'category': budget.category,
          'message': '⚠️ You\'ve exceeded your ${budget.category} budget!',
          'color': Colors.red,
        });
      } else if (percentage >= 80) {
        alerts.add(<String, dynamic>{
          'type': 'warning',
          'category': budget.category,
          'message': '⚠️ You\'ve hit ${percentage.toStringAsFixed(0)}% of your ${budget.category} budget',
          'color': Colors.orange,
        });
      }
    }

    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> alerts = _getAlerts();

    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.notifications_active, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Smart Alerts',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...alerts.map((Map<String, dynamic> alert) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: (alert['color'] as Color).withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.warning, color: alert['color'] as Color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        alert['message'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: alert['color'] as Color,
                          fontWeight: FontWeight.w500,
                        ),
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
  }
}

