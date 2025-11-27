import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../widgets/expense_card.dart';
import 'package:intl/intl.dart';

/// Optimized expense list with lazy loading
class OptimizedExpenseList extends StatelessWidget {
  const OptimizedExpenseList({
    super.key,
    required this.expenses,
    this.onExpenseTap,
    this.onExpenseDelete,
    this.loadMore,
    this.hasMore = false,
  });

  final List<ExpenseModel> expenses;
  final void Function(ExpenseModel)? onExpenseTap;
  final void Function(ExpenseModel)? onExpenseDelete;
  final VoidCallback? loadMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No expenses found'),
        ),
      );
    }

    return ListView.builder(
      itemCount: expenses.length + (hasMore ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index == expenses.length) {
          // Load more trigger
          WidgetsBinding.instance.addPostFrameCallback((_) {
            loadMore?.call();
          });
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final ExpenseModel expense = expenses[index];
        final DateFormat dateFormat = DateFormat.yMMMd();
        final DateFormat timeFormat = DateFormat.jm();
        final String displayDate = dateFormat.format(expense.date);
        final String displayTime = timeFormat.format(expense.date);

        return Dismissible(
          key: Key(expense.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (DismissDirection direction) {
            onExpenseDelete?.call(expense);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ExpenseCard(
              title: expense.category,
              amount: '${expense.type == TransactionType.income ? "+" : "-"}\$${expense.amount.toStringAsFixed(2)}',
              date: '$displayDate • $displayTime',
              onTap: () => onExpenseTap?.call(expense),
            ),
          ),
        );
      },
    );
  }
}

















