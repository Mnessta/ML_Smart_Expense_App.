import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/db_service.dart';
import '../providers/currency_provider.dart';
import 'package:provider/provider.dart';

/// Planner / Calendar screen
/// - Monthly transaction calendar
/// - Past & future transactions
/// - Upcoming bills (future-dated expenses)
/// - Simple reminders summary
class PlannerCalendarScreen extends StatefulWidget {
  const PlannerCalendarScreen({super.key});

  @override
  State<PlannerCalendarScreen> createState() => _PlannerCalendarScreenState();
}

class _PlannerCalendarScreenState extends State<PlannerCalendarScreen> {
  late DateTime _focusedMonth;
  List<ExpenseModel> _allExpenses = <ExpenseModel>[];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      // Load a wide enough range so we can show past + near‑future data
      final DateTime start = DateTime(_focusedMonth.year, _focusedMonth.month - 2, 1);
      final DateTime end = DateTime(_focusedMonth.year, _focusedMonth.month + 3, 0, 23, 59, 59);

      final List<ExpenseModel> expenses = await DbService().getExpenses(
        fromMs: start.millisecondsSinceEpoch,
        toMs: end.millisecondsSinceEpoch,
      );
      if (!mounted) return;
      setState(() {
        _allExpenses = expenses;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset);
    });
    _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final DateTime startOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final DateTime endOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    // Group expenses by day for the focused month
    final Map<DateTime, List<ExpenseModel>> byDay = <DateTime, List<ExpenseModel>>{};
    for (final ExpenseModel e in _allExpenses) {
      if (e.date.isBefore(startOfMonth) || e.date.isAfter(endOfMonth)) {
        continue;
      }
      final DateTime key = DateTime(e.date.year, e.date.month, e.date.day);
      byDay.putIfAbsent(key, () => <ExpenseModel>[]).add(e);
    }

    // Upcoming bills = future‑dated expenses (after today)
    final List<ExpenseModel> upcomingBills = _allExpenses
        .where(
          (ExpenseModel e) =>
              e.type == TransactionType.expense &&
              e.date.isAfter(DateTime(today.year, today.month, today.day)),
        )
        .toList()
      ..sort((ExpenseModel a, ExpenseModel b) => a.date.compareTo(b.date));

    // Simple reminders summary: days in this month where spending exceeds a threshold
    const double reminderThreshold = 0.0; // > 0 means we only show days that have any spending
    final List<_SpendingAlert> alerts = <_SpendingAlert>[];
    for (final MapEntry<DateTime, List<ExpenseModel>> entry in byDay.entries) {
      final double spent = entry.value
          .where((ExpenseModel e) => e.type == TransactionType.expense)
          .fold(0.0, (double s, ExpenseModel e) => s + e.amount);
      if (spent > reminderThreshold) {
        alerts.add(_SpendingAlert(date: entry.key, amount: spent));
      }
    }
    alerts.sort((a, b) => b.amount.compareTo(a.amount));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner & Calendar'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadExpenses,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildMonthHeader(context),
                const SizedBox(height: 12),
                _buildCalendarGrid(context, startOfMonth, endOfMonth, byDay, today),
                const SizedBox(height: 24),
                _buildRemindersSection(context, alerts),
                const SizedBox(height: 24),
                _buildUpcomingBillsSection(context, upcomingBills),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context) {
    final DateFormat monthFormat = DateFormat.yMMMM();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeMonth(-1),
        ),
        Column(
          children: <Widget>[
            Text(
              monthFormat.format(_focusedMonth),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            if (_isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                'Tap days to see details',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context,
    DateTime startOfMonth,
    DateTime endOfMonth,
    Map<DateTime, List<ExpenseModel>> byDay,
    DateTime today,
  ) {
    final List<String> weekdayLabels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final int daysInMonth = endOfMonth.day;
    // Flutter's DateTime weekday: Monday = 1, Sunday = 7
    final int startWeekdayIndex = startOfMonth.weekday; // 1‑7

    final List<Widget> cells = <Widget>[];

    // Weekday header row
    cells.addAll(
      weekdayLabels.map(
        (String label) => Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
          ),
        ),
      ),
    );

    // Leading blanks before the 1st
    for (int i = 1; i < startWeekdayIndex; i++) {
      cells.add(const SizedBox.shrink());
    }

    final DateFormat dayFormat = DateFormat.d();

    for (int day = 1; day <= daysInMonth; day++) {
      final DateTime date = DateTime(startOfMonth.year, startOfMonth.month, day);
      final List<ExpenseModel> dayTx = byDay[date] ?? <ExpenseModel>[];
      final double spent = dayTx
          .where((ExpenseModel e) => e.type == TransactionType.expense)
          .fold(0.0, (double s, ExpenseModel e) => s + e.amount);
      final double income = dayTx
          .where((ExpenseModel e) => e.type == TransactionType.income)
          .fold(0.0, (double s, ExpenseModel e) => s + e.amount);

      final bool isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      cells.add(
        GestureDetector(
          onTap: dayTx.isEmpty ? null : () => _showDayDetails(context, date, dayTx),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
                width: isToday ? 2 : 1,
              ),
              color: dayTx.isEmpty
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    dayFormat.format(date),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                if (spent > 0)
                  Container(
                    width: double.infinity,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                const SizedBox(height: 2),
                if (income > 0)
                  Container(
                    width: double.infinity,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
      ),
    );
  }

  Future<void> _showDayDetails(
    BuildContext context,
    DateTime date,
    List<ExpenseModel> items,
  ) async {
    final DateFormat dateFormat = DateFormat.yMMMMd();
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      dateFormat.format(date),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _DaySummaryRow(items: items),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ExpenseModel e = items[index];
                      return ListTile(
                        leading: Icon(
                          e.type == TransactionType.income
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: e.type == TransactionType.income
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(
                          e.type == TransactionType.income
                              ? (e.note != null && e.note!.trim().isNotEmpty
                                  ? e.note!
                                  : 'Income')
                              : e.category,
                        ),
                        subtitle: Text(DateFormat.jm().format(e.date)),
                        trailing: Consumer<CurrencyProvider>(
                          builder: (BuildContext context, CurrencyProvider currency, Widget? _) {
                            final String sign = e.type == TransactionType.income ? '+' : '-';
                            return Text(
                              '$sign${currency.symbol}${e.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: e.type == TransactionType.income
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRemindersSection(BuildContext context, List<_SpendingAlert> alerts) {
    if (alerts.isEmpty) {
      return Card(
        color: Colors.blue.withValues(alpha: 0.05),
        child: const ListTile(
          leading: Icon(Icons.lightbulb_outline),
          title: Text('No spending reminders for this month yet.'),
          subtitle: Text('As you spend, we will highlight heavy‑spend days here.'),
        ),
      );
    }

    final DateFormat dateFormat = DateFormat.MMMd();

    return Card(
      color: Colors.blue.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.lightbulb, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Reminders',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...alerts.take(3).map((alert) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notification_important, color: Colors.orange),
                title: Text(
                  'High spending on ${dateFormat.format(alert.date)}',
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Consumer<CurrencyProvider>(
                  builder: (BuildContext context, CurrencyProvider currency, Widget? _) {
                    return Text(
                      'You spent approximately ${currency.symbol}${alert.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingBillsSection(
    BuildContext context,
    List<ExpenseModel> upcomingBills,
  ) {
    final DateFormat dateFormat = DateFormat.MMMd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.event_note),
            const SizedBox(width: 8),
            Text(
              'Upcoming Bills',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (upcomingBills.isEmpty)
          const Text(
            'No upcoming bills detected. Add future‑dated expenses to see them here.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          )
        else
          Card(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcomingBills.length.clamp(0, 5),
              itemBuilder: (BuildContext context, int index) {
                final ExpenseModel e = upcomingBills[index];
                return ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(e.category),
                  subtitle: Text(dateFormat.format(e.date)),
                  trailing: Consumer<CurrencyProvider>(
                    builder: (BuildContext context, CurrencyProvider currency, Widget? _) {
                      return Text(
                        '${currency.symbol}${e.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SpendingAlert {
  _SpendingAlert({required this.date, required this.amount});

  final DateTime date;
  final double amount;
}

class _DaySummaryRow extends StatelessWidget {
  const _DaySummaryRow({required this.items});

  final List<ExpenseModel> items;

  @override
  Widget build(BuildContext context) {
    final double totalExpenses = items
        .where((ExpenseModel e) => e.type == TransactionType.expense)
        .fold(0.0, (double s, ExpenseModel e) => s + e.amount);
    final double totalIncome = items
        .where((ExpenseModel e) => e.type == TransactionType.income)
        .fold(0.0, (double s, ExpenseModel e) => s + e.amount);

    return Consumer<CurrencyProvider>(
      builder: (BuildContext context, CurrencyProvider currency, Widget? _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Income: ${currency.symbol}${totalIncome.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Expenses: ${currency.symbol}${totalExpenses.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}



