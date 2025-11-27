import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense_model.dart';
import '../providers/currency_provider.dart';
import '../services/db_service.dart';
import '../services/sync_service.dart';
import '../widgets/expense_card.dart';
import '../screens/add_expense_screen.dart';

class TransactionTimeline extends StatefulWidget {
  const TransactionTimeline({
    super.key,
    required this.expenses,
  });

  final List<ExpenseModel> expenses;

  @override
  State<TransactionTimeline> createState() => _TransactionTimelineState();
}

class _TransactionTimelineState extends State<TransactionTimeline> {
  final Map<String, List<ExpenseModel>> _groupedExpenses = <String, List<ExpenseModel>>{};

  @override
  void initState() {
    super.initState();
    _groupExpenses();
  }

  @override
  void didUpdateWidget(TransactionTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-group expenses when the parent updates the expenses list
    if (oldWidget.expenses != widget.expenses) {
      _groupExpenses();
    }
  }

  void _groupExpenses() {
    _groupedExpenses.clear();
    final DateFormat dateFormat = DateFormat.yMMMd();
    
    for (final ExpenseModel expense in widget.expenses) {
      final String dateKey = dateFormat.format(expense.date);
      if (!_groupedExpenses.containsKey(dateKey)) {
        _groupedExpenses[dateKey] = <ExpenseModel>[];
      }
      _groupedExpenses[dateKey]!.add(expense);
    }

    // Sort each group by time (newest first)
    for (final List<ExpenseModel> group in _groupedExpenses.values) {
      group.sort((ExpenseModel a, ExpenseModel b) => b.date.compareTo(a.date));
    }
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    // Get remote_id before deleting
    final String? remoteId = await DbService().getExpenseRemoteId(expense.id);
    
    // Delete from local database
    await DbService().deleteExpense(expense.id, syncDelete: false);
    
    // Delete from server in background
    if (remoteId != null) {
      SyncService().deleteExpenseFromServer(expense.id, remoteId: remoteId).catchError((_) {
        // Sync delete failed - local delete still happened
      });
    }
    
    if (mounted) {
      setState(() {
        _groupExpenses();
      });
    }
  }

  Future<void> _navigateToEditExpense(ExpenseModel expense, BuildContext context) async {
    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => Scaffold(
          body: AddExpenseScreen(expense: expense),
        ),
      ),
    );
    
    // Refresh the grouped expenses after editing
    if (result == true && mounted) {
      setState(() {
        _groupExpenses();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_groupedExpenses.isEmpty) {
      return const SizedBox.shrink();
    }

    final CurrencyProvider currencyProvider = context.watch<CurrencyProvider>();
    final DateFormat dateFormat = DateFormat.yMMMd();
    final DateFormat timeFormat = DateFormat.jm();
    final List<String> sortedDates = _groupedExpenses.keys.toList()
      ..sort((String a, String b) {
        // Parse dates for proper sorting
        try {
          final DateTime dateA = dateFormat.parse(a);
          final DateTime dateB = dateFormat.parse(b);
          return dateB.compareTo(dateA);
        } catch (_) {
          return b.compareTo(a);
        }
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Transaction Timeline',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...sortedDates.map((String dateKey) {
          final List<ExpenseModel> dayExpenses = _groupedExpenses[dateKey]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  dateKey,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                ),
              ),
              ...dayExpenses.map((ExpenseModel expense) {
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
                    _deleteExpense(expense);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense deleted'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ExpenseCard(
                    title: expense.category,
                    amount:
                        '${expense.type == TransactionType.income ? "+" : "-"}${currencyProvider.formatAmount(expense.amount)}',
                    date: displayTime,
                      onTap: () {
                        _navigateToEditExpense(expense, context);
                      },
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }
}

