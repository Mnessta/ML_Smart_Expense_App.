import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/db_service.dart';
import '../services/sync_service.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../providers/currency_provider.dart';
import '../utils/constants.dart';

enum BudgetCycle { monthly, weekly, custom }

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late Future<Map<String, dynamic>> _data;
  BudgetCycle _selectedCycle = BudgetCycle.monthly;

  @override
  void initState() {
    super.initState();
    _data = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final DateTime now = DateTime.now();
    final List<BudgetModel> budgets = await DbService().getBudgets(month: now.month, year: now.year);
    final List<ExpenseModel> expenses = await DbService().getExpenses();
    
    // Calculate savings
    final double totalBudget = budgets.fold(0.0, (sum, b) => sum + b.limit);
    final double totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);
    final double savings = totalBudget - totalSpent;
    
    // Category ranking by spending
    final Map<String, double> categorySpending = <String, double>{};
    for (final ExpenseModel e in expenses) {
      if (e.type == TransactionType.expense) {
        categorySpending[e.category] = (categorySpending[e.category] ?? 0) + e.amount;
      }
    }
    
    final List<MapEntry<String, double>> sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return <String, dynamic>{
      'budgets': budgets,
      'savings': savings,
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'categoryRanking': sortedCategories,
    };
  }

  void _refresh() {
    setState(() => _data = _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final CurrencyProvider currencyProvider = context.watch<CurrencyProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _data,
          builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final Map<String, dynamic> data = snapshot.data!;
          final List<BudgetModel> budgets = data['budgets'] as List<BudgetModel>;
          final double savings = data['savings'] as double;
          final double totalBudget = data['totalBudget'] as double;
          final List<MapEntry<String, double>> categoryRanking = data['categoryRanking'] as List<MapEntry<String, double>>;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Budget Cycle Selector
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: <Widget>[
                            _CycleButton(
                              label: 'Monthly',
                              isSelected: _selectedCycle == BudgetCycle.monthly,
                              onTap: () => setState(() {
                                _selectedCycle = BudgetCycle.monthly;
                                _data = _loadData();
                              }),
                            ),
                            const SizedBox(width: 8),
                            _CycleButton(
                              label: 'Weekly',
                              isSelected: _selectedCycle == BudgetCycle.weekly,
                              onTap: () => setState(() {
                                _selectedCycle = BudgetCycle.weekly;
                                _data = _loadData();
                              }),
                            ),
                            const SizedBox(width: 8),
                            _CycleButton(
                              label: 'Custom',
                              isSelected: _selectedCycle == BudgetCycle.custom,
                              onTap: () => setState(() {
                                _selectedCycle = BudgetCycle.custom;
                                _data = _loadData();
                              }),
                            ),
                          ],
                        ),
                      ),
                      // Savings Goal Widget
                      if (totalBudget > 0)
                        Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                          color: savings >= 0 ? Colors.green : Colors.red,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    savings >= 0 ? Icons.savings : Icons.warning,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        savings >= 0 ? 'You saved' : 'Over budget by',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        currencyProvider.formatAmount(savings.abs()),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'this month',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Category Ranking
                      if (categoryRanking.isNotEmpty) ...<Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Category Ranking',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: categoryRanking.take(5).map((MapEntry<String, double> entry) {
                                  final int index = categoryRanking.indexOf(entry);
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getRankColor(index).withValues(alpha: 0.2),
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: _getRankColor(index),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(entry.key),
                                    trailing: Text(
                                      currencyProvider.formatAmount(entry.value),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Budget Overview Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Monthly Budget Overview',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                if (budgets.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No budgets yet',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Create a budget to start tracking',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final BudgetModel budget = budgets[index];
                        final double percentage = budget.progress * 100;
                        final bool isWarning = percentage >= 80 && percentage < 100;
                        final bool isOver = budget.spent > budget.limit;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          budget.category,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (isOver)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            '⚠️ Over Budget',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      else if (isWarning)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '⚠️ ${percentage.toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(
                                        currencyProvider.formatAmount(budget.spent),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isOver ? Colors.red : Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        'of ${currencyProvider.formatAmount(budget.limit)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: budget.progress.clamp(0.0, 1.0)),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                    builder: (BuildContext context, double value, Widget? child) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: LinearProgressIndicator(
                                          value: value,
                                          minHeight: 12,
                                          backgroundColor: Colors.grey[200],
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isOver ? Colors.red : (isWarning ? Colors.orange : Colors.green),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}% used',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: budgets.length,
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          );
        },
      ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FloatingActionButton.extended(
            heroTag: 'suggest',
            onPressed: () => _showBudgetSuggestions(context),
            tooltip: 'Suggest Budgets',
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Suggest Budget'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () async {
              await showDialog<void>(context: context, builder: (BuildContext ctx) => const _AddBudgetDialog());
              _refresh();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Budget'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBudgetSuggestions(BuildContext context) async {
    // Load expense data for analysis
    final List<ExpenseModel> allExpenses = await DbService().getExpenses();
    final DateTime now = DateTime.now();
    
    // Get expenses from last 3 months for analysis
    final DateTime threeMonthsAgo = DateTime(now.year, now.month - 3, 1);
    final List<ExpenseModel> recentExpenses = allExpenses.where((ExpenseModel e) {
      return e.type == TransactionType.expense && 
             e.date.isAfter(threeMonthsAgo) &&
             e.date.isBefore(now);
    }).toList();

    if (recentExpenses.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough expense data to suggest budgets. Add some expenses first!'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final double totalIncome = allExpenses
        .where((ExpenseModel e) => e.type == TransactionType.income)
        .fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);
    final double totalExpensesAll = allExpenses
        .where((ExpenseModel e) => e.type == TransactionType.expense)
        .fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);
    final double currentBalance = totalIncome - totalExpensesAll;

    if (currentBalance <= 0) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your balance is zero or negative. Add income before generating smart budgets.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    const double reserveRatio = 0.25;
    final double reservedSavings = currentBalance * reserveRatio;
    final double availableBudgetPool = currentBalance - reservedSavings;

    if (availableBudgetPool <= 0) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to allocate budgets without dipping below the 25% safety buffer.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Calculate average monthly spending per category
    final Map<String, List<double>> categorySpending = <String, List<double>>{};
    for (final ExpenseModel expense in recentExpenses) {
      if (!categorySpending.containsKey(expense.category)) {
        categorySpending[expense.category] = <double>[];
      }
      categorySpending[expense.category]!.add(expense.amount);
    }

    // Calculate number of months in the data range
    final int monthsInRange = _calculateMonthsBetween(threeMonthsAgo, now);
    final int actualMonths = monthsInRange > 0 ? monthsInRange : 1; // Ensure at least 1 month
    
    // Calculate average monthly spending
    final Map<String, double> categoryAverages = <String, double>{};
    for (final MapEntry<String, List<double>> entry in categorySpending.entries) {
      final double total = entry.value.fold(0.0, (double sum, double amount) => sum + amount);
      // Average per month
      categoryAverages[entry.key] = total / actualMonths;
    }

    // Generate suggestions (add 15% buffer above average)
    final List<Map<String, dynamic>> suggestions = <Map<String, dynamic>>[];
    for (final MapEntry<String, double> entry in categoryAverages.entries) {
      final double suggestedBudget = entry.value * 1.15; // 15% buffer
      suggestions.add(<String, dynamic>{
        'category': entry.key,
        'averageSpending': entry.value,
        'suggestedBudget': suggestedBudget,
      });
    }

    // Sort by suggested budget (highest first)
    suggestions.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      return (b['suggestedBudget'] as double).compareTo(a['suggestedBudget'] as double);
    });

    suggestions.removeWhere(
      (Map<String, dynamic> suggestion) => (suggestion['suggestedBudget'] as double) <= 0,
    );

    if (suggestions.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Need more positive spending data to craft meaningful budgets.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    double totalSuggested = suggestions.fold<double>(
      0.0,
      (double sum, Map<String, dynamic> suggestion) => sum + (suggestion['suggestedBudget'] as double),
    );

    if (totalSuggested > availableBudgetPool) {
      final double scaleFactor = availableBudgetPool / totalSuggested;
      for (final Map<String, dynamic> suggestion in suggestions) {
        suggestion['suggestedBudget'] =
            (suggestion['suggestedBudget'] as double) * scaleFactor;
      }
      totalSuggested = availableBudgetPool;
    }

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => _BudgetSuggestionsDialog(
        suggestions: suggestions,
        balance: currentBalance,
        availableBudget: availableBudgetPool,
        reserveAmount: reservedSavings,
        onApply: (List<Map<String, dynamic>> selected) async {
          final DateTime now = DateTime.now();
          for (final Map<String, dynamic> suggestion in selected) {
            final BudgetModel budget = BudgetModel(
              id: 'bud_${DateTime.now().millisecondsSinceEpoch}_${suggestion['category']}',
              category: suggestion['category'] as String,
              month: now.month,
              year: now.year,
              limit: suggestion['suggestedBudget'] as double,
            );
            await DbService().upsertBudget(budget);
          }
          _refresh();
        },
      ),
    );
  }

  int _calculateMonthsBetween(DateTime start, DateTime end) {
    final int yearDiff = end.year - start.year;
    final int monthDiff = end.month - start.month;
    return (yearDiff * 12) + monthDiff + 1; // +1 to include both start and end months
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }
}

class _CycleButton extends StatelessWidget {
  const _CycleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isLightMode = Theme.of(context).brightness == Brightness.light;
    final Color borderColor = isSelected 
        ? Theme.of(context).colorScheme.primary 
        : (isLightMode ? Colors.blue : Colors.grey[300] ?? Colors.grey);
    final Color textColor = isSelected
        ? Colors.white
        : (isLightMode ? Colors.black87 : Colors.white);
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetSuggestionsDialog extends StatefulWidget {
  const _BudgetSuggestionsDialog({
    required this.suggestions,
    required this.balance,
    required this.availableBudget,
    required this.reserveAmount,
    required this.onApply,
  });

  final List<Map<String, dynamic>> suggestions;
  final double balance;
  final double availableBudget;
  final double reserveAmount;
  final void Function(List<Map<String, dynamic>>) onApply;

  @override
  State<_BudgetSuggestionsDialog> createState() => _BudgetSuggestionsDialogState();
}

class _BudgetSuggestionsDialogState extends State<_BudgetSuggestionsDialog> {
  final Map<String, bool> _selectedCategories = <String, bool>{};

  @override
  void initState() {
    super.initState();
    // Select all by default
    for (final Map<String, dynamic> suggestion in widget.suggestions) {
      _selectedCategories[suggestion['category'] as String] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final CurrencyProvider currencyProvider = context.watch<CurrencyProvider>();
    final double selectedTotal = _selectedBudgetTotal();
    final int selectedCount = _selectedCategories.values.where((bool value) => value).length;
    return AlertDialog(
      title: Row(
        children: <Widget>[
          const Icon(Icons.auto_awesome, color: Colors.amber),
          const SizedBox(width: 8),
          const Text('Budget Suggestions'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.suggestions.isEmpty
            ? const Text('No suggestions available')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Based on your expense history, here are suggested monthly budgets:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _BudgetSummaryRow(
                            label: 'Current balance',
                            value: currencyProvider.formatAmount(widget.balance),
                          ),
                          _BudgetSummaryRow(
                            label: 'Reserved savings (25%)',
                            value: currencyProvider.formatAmount(widget.reserveAmount),
                          ),
                          _BudgetSummaryRow(
                            label: 'Available for budgets',
                            value: currencyProvider.formatAmount(widget.availableBudget),
                          ),
                          const Divider(),
                          _BudgetSummaryRow(
                            label: 'Selected allocation',
                            value: currencyProvider.formatAmount(selectedTotal),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.suggestions.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> suggestion = widget.suggestions[index];
                        final String category = suggestion['category'] as String;
                        final double averageSpending = suggestion['averageSpending'] as double;
                        final double suggestedBudget = suggestion['suggestedBudget'] as double;
                        final bool isSelected = _selectedCategories[category] ?? false;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                _selectedCategories[category] = value ?? false;
                              });
                            },
                            title: Text(
                              category,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const SizedBox(height: 4),
                                Text(
                                  'Avg: ${currencyProvider.formatAmount(averageSpending)}/month',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                Text(
                                  'Suggested: ${currencyProvider.formatAmount(suggestedBudget)}/month',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            secondary: const Icon(Icons.insights, color: Colors.amber),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            final List<Map<String, dynamic>> selected = widget.suggestions
                .where((Map<String, dynamic> s) => _selectedCategories[s['category'] as String] ?? false)
                .toList();
            widget.onApply(selected);
            Navigator.of(context).pop();
            HapticFeedback.mediumImpact();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${selected.length} budget(s) created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          icon: const Icon(Icons.check),
          label: Text(
            'Apply ($selectedCount • ${currencyProvider.formatAmount(selectedTotal)})',
          ),
        ),
      ],
    );
  }

  double _selectedBudgetTotal() {
    double total = 0;
    for (final Map<String, dynamic> suggestion in widget.suggestions) {
      if (_selectedCategories[suggestion['category'] as String] ?? false) {
        total += suggestion['suggestedBudget'] as double;
      }
    }
    return total;
  }
}

class _BudgetSummaryRow extends StatelessWidget {
  const _BudgetSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _AddBudgetDialog extends StatefulWidget {
  const _AddBudgetDialog();

  @override
  State<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<_AddBudgetDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _category = TextEditingController();
  final TextEditingController _limit = TextEditingController();
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  @override
  void dispose() {
    _category.dispose();
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CurrencyProvider currencyProvider = context.watch<CurrencyProvider>();
    return AlertDialog(
      title: const Text('New Budget'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              items: AppConstants.defaultCategories
                  .map((String c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                  .toList(),
              onChanged: (String? v) => _category.text = v ?? '',
              validator: (String? v) => (v == null || v.isEmpty) ? 'Select category' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _limit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Budget Limit (${currencyProvider.code})'),
              validator: (String? v) => (double.tryParse(v ?? '') == null) ? 'Enter valid number' : null,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;
            final BudgetModel b = BudgetModel(
              id: 'bud_${DateTime.now().millisecondsSinceEpoch}',
              category: _category.text,
              month: _month,
              year: _year,
              limit: double.parse(_limit.text.trim()),
            );
            await DbService().upsertBudget(b);
            
            // Sync to cloud in background (non-blocking)
            // Note: Will be replaced with Supabase integration in future
            SyncService().syncBudget(b).catchError((_) {
              // Sync failed - budget will sync later
            });
            
            if (!context.mounted) return;
            Navigator.of(context).pop();
            HapticFeedback.mediumImpact();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
