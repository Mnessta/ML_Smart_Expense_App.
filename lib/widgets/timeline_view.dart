import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

class TimelineView extends StatelessWidget {
  const TimelineView({super.key, required this.expenses});

  final List<ExpenseModel> expenses;

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat.yMMMd();
    final DateFormat timeFormat = DateFormat.jm();

    // Group expenses by date
    final Map<String, List<ExpenseModel>> groupedExpenses =
        <String, List<ExpenseModel>>{};
    for (final ExpenseModel expense in expenses) {
      final String dateKey = dateFormat.format(expense.date);
      groupedExpenses.putIfAbsent(dateKey, () => <ExpenseModel>[]).add(expense);
    }

    final List<MapEntry<String, List<ExpenseModel>>> sortedEntries =
        groupedExpenses.entries.toList()..sort((
          MapEntry<String, List<ExpenseModel>> a,
          MapEntry<String, List<ExpenseModel>> b,
        ) {
          final DateTime dateA = DateFormat.yMMMd().parse(a.key);
          final DateTime dateB = DateFormat.yMMMd().parse(b.key);
          return dateB.compareTo(dateA);
        });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: sortedEntries.map((MapEntry<String, List<ExpenseModel>> entry) {
        final double dayTotal = entry.value
            .where((ExpenseModel e) => e.type == TransactionType.expense)
            .fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);
        final double dayIncome = entry.value
            .where((ExpenseModel e) => e.type == TransactionType.income)
            .fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 12,
            ),
            leading: CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              entry.key,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${entry.value.length} transactions'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                if (dayIncome > 0)
                  Text(
                    '+\$${dayIncome.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Text(
                  '-\$${dayTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            children: <Widget>[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entry.value.length,
                itemBuilder: (BuildContext context, int index) {
                  final ExpenseModel expense = entry.value[index];
                  return ListTile(
                    leading: Icon(
                      expense.type == TransactionType.income
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: expense.type == TransactionType.income
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text(
                      expense.type == TransactionType.income
                          ? (expense.note != null &&
                                    expense.note!.trim().isNotEmpty
                                ? expense.note!
                                : 'Income')
                          : expense.category,
                    ),
                    subtitle: Text(timeFormat.format(expense.date)),
                    trailing: Text(
                      '${expense.type == TransactionType.income ? "+" : "-"}\$${expense.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: expense.type == TransactionType.income
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
