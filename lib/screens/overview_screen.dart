import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';
import '../services/db_service.dart';
import '../services/local_db.dart';
import '../widgets/expense_card.dart';
import '../widgets/chart_widget.dart';
import '../widgets/wallet_section.dart';
import '../widgets/smart_insights.dart';
import '../widgets/smart_summary_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/expense_insights.dart';
import '../widgets/smart_alerts.dart';
import '../widgets/transaction_timeline.dart';
import '../widgets/home_dashboard.dart';
import '../services/sync_service.dart';
import '../app_router.dart';
import '../services/ai_notification_service.dart';
import '../widgets/ai_notification_banner.dart';
import '../providers/currency_provider.dart';
import '../providers/expense_provider.dart';

enum TimeFilter { day, week, month }

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _data;
  TimeFilter _selectedFilter = TimeFilter.month;
  late AnimationController _gradientController;
  late AnimationController _staggerController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchActive = false;
  List<NotificationMessage> _notifications = <NotificationMessage>[];
  bool _isClearingTransactions = false;

  @override
  void initState() {
    super.initState();
    _data = _loadData();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _checkAndShowNotifications();
  }

  Future<void> _checkAndShowNotifications() async {
    final AINotificationService notificationService = AINotificationService();
    final bool shouldSend = await notificationService.shouldSendNotifications();
    
    if (shouldSend && mounted) {
      final List<NotificationMessage> messages = 
          await notificationService.generateNotifications();
      
      if (mounted && messages.isNotEmpty) {
        setState(() {
          _notifications = messages;
        });
      }
    }
  }

  void _dismissNotification(NotificationMessage message) {
    setState(() {
      _notifications.removeWhere((n) => 
        n.title == message.title && n.message == message.message
      );
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _staggerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _isSearchActive = query.isNotEmpty;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _isSearchActive = false;
    });
  }

  Future<void> _clearAllTransactions() async {
    if (_isClearingTransactions) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all transactions?'),
        content: const Text('This will permanently delete every item in the timeline.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isClearingTransactions = true);
    try {
      final DbService db = DbService();
      final List<ExpenseModel> expenses = await db.getExpenses();

      // Delete all expenses locally and from the server (if synced)
      for (final ExpenseModel expense in expenses) {
        final String? remoteId = await db.getExpenseRemoteId(expense.id);
        await db.deleteExpense(expense.id, syncDelete: false);

        if (remoteId != null) {
          SyncService()
              .deleteExpenseFromServer(expense.id, remoteId: remoteId)
              .catchError((_) {
            // Ignore sync delete errors – local delete has already happened
          });
        }
      }

      // Clear legacy local cache as well
      await LocalDB.deleteAllExpenses(null);

      if (!mounted) return;
      await context.read<ExpenseProvider>().loadExpenses();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('All transactions cleared'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear transactions: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearingTransactions = false);
      }
    }
  }

  List<ExpenseModel> _filterExpenses(List<ExpenseModel> expenses) {
    if (_searchQuery.isEmpty) {
      return expenses;
    }
    
    return expenses.where((expense) {
      // Search by category
      if (expense.category.toLowerCase().contains(_searchQuery)) {
        return true;
      }
      
      // Search by note
      if (expense.note != null && expense.note!.toLowerCase().contains(_searchQuery)) {
        return true;
      }
      
      // Search by amount
      if (expense.amount.toString().contains(_searchQuery)) {
        return true;
      }
      
      // Search by payment method
      if (expense.paymentMethod.toLowerCase().contains(_searchQuery)) {
        return true;
      }
      
      return false;
    }).toList();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;
    
    switch (_selectedFilter) {
      case TimeFilter.day:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case TimeFilter.week:
        final int weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case TimeFilter.month:
        startDate = DateTime(now.year, now.month, 1);
        break;
    }

    final List<ExpenseModel> allExpenses = await DbService().getExpenses();
    
    // Filter by selected period
    final List<ExpenseModel> periodExpenses = allExpenses.where((ExpenseModel e) {
      return e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          e.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Deduplicate any accidentally cloned expenses so they don't appear multiple times
    final Set<String> seenExpenseKeys = <String>{};
    final List<ExpenseModel> filteredExpenses = <ExpenseModel>[];
    for (final ExpenseModel e in periodExpenses) {
      final String key =
          '${e.id}-${e.amount}-${e.category}-${e.date.toIso8601String()}-${e.paymentMethod}-${e.note ?? ''}-${e.type}';
      if (seenExpenseKeys.add(key)) {
        filteredExpenses.add(e);
      }
    }

    final List<ExpenseModel> expenses = filteredExpenses
        .where((ExpenseModel e) => e.type == TransactionType.expense)
        .toList();
    final List<ExpenseModel> incomes = filteredExpenses
        .where((ExpenseModel e) => e.type == TransactionType.income)
        .toList();

    final List<ExpenseModel> recentExpenses = filteredExpenses.take(5).toList();
    final List<BudgetModel> budgets = await DbService().getBudgets(month: now.month, year: now.year);

    final double totalExpenses = expenses.fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);
    final double totalIncome = incomes.fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);
    final double balance = totalIncome - totalExpenses;
    final DateTime today = DateTime(now.year, now.month, now.day);
    final double todaySpending = allExpenses
        .where(
          (ExpenseModel e) =>
              e.type == TransactionType.expense &&
              e.date.year == today.year &&
              e.date.month == today.month &&
              e.date.day == today.day,
        )
        .fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);

    final Map<String, double> categoryBreakdown = <String, double>{};
    for (final ExpenseModel e in expenses) {
      categoryBreakdown[e.category] = (categoryBreakdown[e.category] ?? 0.0) + e.amount;
    }

    // Get previous period data for insights
    DateTime previousStartDate;
    DateTime previousEndDate = startDate.subtract(const Duration(seconds: 1));
    
    switch (_selectedFilter) {
      case TimeFilter.day:
        previousStartDate = startDate.subtract(const Duration(days: 1));
        previousEndDate = startDate.subtract(const Duration(seconds: 1));
        break;
      case TimeFilter.week:
        previousStartDate = startDate.subtract(const Duration(days: 7));
        previousEndDate = startDate.subtract(const Duration(seconds: 1));
        break;
      case TimeFilter.month:
        previousStartDate = DateTime(now.year, now.month - 1, 1);
        previousEndDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
    }

    final List<ExpenseModel> previousExpenses = allExpenses.where((ExpenseModel e) {
      return e.date.isAfter(previousStartDate.subtract(const Duration(days: 1))) &&
          e.date.isBefore(previousEndDate.add(const Duration(days: 1))) &&
          e.type == TransactionType.expense;
    }).toList();

    return <String, dynamic>{
      'totalExpenses': totalExpenses,
      'totalIncome': totalIncome,
      'balance': balance,
      'recentExpenses': recentExpenses,
      'categoryBreakdown': categoryBreakdown,
      'budgets': budgets,
      'expenseCount': expenses.length,
      'allExpenses': filteredExpenses,
      'previousExpenses': previousExpenses,
      'todaySpending': todaySpending,
      'monthlySavings': balance,
    };
  }

  void _refresh() {
    setState(() {
      _data = _loadData();
      _staggerController.reset();
      _staggerController.forward();
    });
    // Sync data in background when refreshing
    // Note: Will use Supabase auth check in future
    SyncService().syncNow().catchError((_) {
      // Sync failed silently
    });
  }

  void _changeFilter(TimeFilter filter) {
    setState(() {
      _selectedFilter = filter;
      _data = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final CurrencyProvider currencyProvider = context.watch<CurrencyProvider>();
    final DateFormat dateFormat = DateFormat.yMMMd();
    final DateFormat timeFormat = DateFormat.jm();

    return AnimatedBuilder(
      animation: _gradientController,
      builder: (BuildContext context, Widget? child) {
        final double animationValue = _gradientController.value;
        final double sinValue = math.sin(animationValue * 2 * math.pi);
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                -1.0 + (0.1 * sinValue),
                -1.0 + (0.1 * sinValue),
              ),
              end: Alignment(
                1.0 - (0.1 * sinValue),
                1.0 - (0.1 * sinValue),
              ),
              colors: <Color>[
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05 + (0.05 * (0.5 + 0.5 * sinValue))),
              ],
            ),
          ),
          child: SafeArea(
            child: RefreshIndicator(
            onRefresh: () async {
              _refresh();
              // Wait a bit for data to load
              await Future<void>.delayed(const Duration(milliseconds: 500));
            },
            child: FutureBuilder<Map<String, dynamic>>(
              future: _data,
              builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final Map<String, dynamic> data = snapshot.data!;
                final List<ExpenseModel> recentExpenses = data['recentExpenses'] as List<ExpenseModel>;
                final Map<String, double> categoryBreakdown = data['categoryBreakdown'] as Map<String, double>;
                final List<ExpenseModel> allExpenses = data['allExpenses'] as List<ExpenseModel>;
                final List<ExpenseModel> previousExpenses = data['previousExpenses'] as List<ExpenseModel>;
                final List<BudgetModel> budgets = data['budgets'] as List<BudgetModel>;
                final List<ExpenseModel> currentExpenses = allExpenses
                    .where((ExpenseModel e) => e.type == TransactionType.expense)
                    .toList();
                
                // Filter expenses based on search query
                final List<ExpenseModel> filteredExpenses = _filterExpenses(allExpenses);
                final List<ExpenseModel> displayExpenses = _isSearchActive 
                    ? filteredExpenses.take(50).toList() 
                    : recentExpenses;

                return CustomScrollView(
                  slivers: <Widget>[
                    // AI Notifications
                    if (_notifications.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Column(
                          children: _notifications.map((notification) {
                            return AINotificationBanner(
                              message: notification,
                              onDismiss: () => _dismissNotification(notification),
                            );
                          }).toList(),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: 16),
                          // Search Bar
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            builder: (BuildContext context, double value, Widget? child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: _onSearchChanged,
                                        decoration: InputDecoration(
                                          hintText: 'Search expenses...',
                                          prefixIcon: Icon(
                                            Icons.search,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          suffixIcon: _isSearchActive
                                              ? IconButton(
                                                  icon: Icon(
                                                    Icons.clear,
                                                    color: Colors.grey[600],
                                                  ),
                                                  onPressed: _clearSearch,
                                                )
                                              : null,
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Hide summary cards when searching
                          if (!_isSearchActive) ...[
                            // Home Dashboard with editable financial cards
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 550),
                              curve: Curves.easeOut,
                              builder: (BuildContext context, double value, Widget? child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: HomeDashboard(
                                balance: data['balance'] as double,
                                totalIncome: data['totalIncome'] as double,
                                totalExpenses: data['totalExpenses'] as double,
                                todaySpending: data['todaySpending'] as double,
                                monthlySavings: data['monthlySavings'] as double,
                              ),
                            ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            // Smart Summary Bar
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOut,
                              builder: (BuildContext context, double value, Widget? child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: SmartSummaryBar(
                                      currentExpenses: currentExpenses,
                                      previousExpenses: previousExpenses,
                                      categoryBreakdown: categoryBreakdown,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            // (Removed Category Carousel as requested)
                            // Time Filter Buttons with staggered animation
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                              builder: (BuildContext context, double value, Widget? child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        children: <Widget>[
                                          _FilterButton(
                                            label: 'Day',
                                            isSelected: _selectedFilter == TimeFilter.day,
                                            onTap: () => _changeFilter(TimeFilter.day),
                                          ),
                                          const SizedBox(width: 8),
                                          _FilterButton(
                                            label: 'Week',
                                            isSelected: _selectedFilter == TimeFilter.week,
                                            onTap: () => _changeFilter(TimeFilter.week),
                                          ),
                                          const SizedBox(width: 8),
                                          _FilterButton(
                                            label: 'Month',
                                            isSelected: _selectedFilter == TimeFilter.month,
                                            onTap: () => _changeFilter(TimeFilter.month),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            // Smart Alerts
                            if (budgets.isNotEmpty)
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 1100),
                                curve: Curves.easeOut,
                                builder: (BuildContext context, double value, Widget? child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: SmartAlerts(budgets: budgets),
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 16),
                            // Expense Insights
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 1200),
                              curve: Curves.easeOut,
                              builder: (BuildContext context, double value, Widget? child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: ExpenseInsights(expenses: allExpenses),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            // Smart Insights with staggered animation
                            if (currentExpenses.isNotEmpty && previousExpenses.isNotEmpty)
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOut,
                                builder: (BuildContext context, double value, Widget? child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: SmartInsights(
                                        currentExpenses: currentExpenses,
                                        previousExpenses: previousExpenses,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            // Wallet Section with staggered animation
                            if (allExpenses.isNotEmpty)
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOut,
                                builder: (BuildContext context, double value, Widget? child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: WalletSection(expenses: allExpenses),
                                    ),
                                  );
                                },
                              ),
                            // Category Breakdown with staggered animation
                            if (categoryBreakdown.isNotEmpty) ...<Widget>[
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOut,
                                builder: (BuildContext context, double value, Widget? child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text(
                                              'Expense Breakdown',
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.easeOut,
                                builder: (BuildContext context, double value, Widget? child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.scale(
                                      scale: 0.95 + (0.05 * value),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: SizedBox(
                                              height: 220,
                                              child: SimplePieChart(data: categoryBreakdown),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                          // Recent Activity / Search Results Header with staggered animation
                          if (!_isSearchActive || displayExpenses.isNotEmpty)
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 1100),
                              curve: Curves.easeOut,
                              builder: (BuildContext context, double value, Widget? child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Text(
                                            _isSearchActive
                                                ? 'Search Results (${displayExpenses.length})'
                                                : 'Recent Activity',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          if (!_isSearchActive && recentExpenses.isNotEmpty)
                                            Row(
                                              children: [
                                                TextButton(
                                                  onPressed: () {},
                                                  child: const Text('View All'),
                                                ),
                                                const SizedBox(width: 4),
                                                _isClearingTransactions
                                                    ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                      )
                                                    : TextButton.icon(
                                                        onPressed: _clearAllTransactions,
                                                        icon: const Icon(
                                                          Icons.delete_sweep_outlined,
                                                          size: 18,
                                                        ),
                                                        label: const Text('Clear All'),
                                                        style: TextButton.styleFrom(
                                                          foregroundColor: Colors.redAccent,
                                                        ),
                                                      ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 8),
                          // Transaction Timeline
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1400),
                            curve: Curves.easeOut,
                            builder: (BuildContext context, double value, Widget? child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: TransactionTimeline(expenses: allExpenses),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                if (displayExpenses.isEmpty)
                  SliverFillRemaining(
                    child: _isSearchActive 
                        ? _buildSearchEmptyState(context)
                        : _buildEmptyState(context),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final ExpenseModel expense = displayExpenses[index];
                        final String displayDate = dateFormat.format(expense.date);
                        final String displayTime = timeFormat.format(expense.date);
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          curve: Curves.easeOut,
                          builder: (BuildContext context, double value, Widget? child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child ?? const SizedBox.shrink(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: ExpenseCard(
                              title: expense.category,
                              amount:
                                  '${expense.type == TransactionType.income ? "+" : "-"}${currencyProvider.formatAmount(expense.amount)}',
                              date: '$displayDate • $displayTime',
                              onTap: () {},
                            ),
                          ),
                        );
                      },
                      childCount: displayExpenses.length,
                    ),
                  ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkGuestMode(),
      builder: (context, snapshot) {
        final bool isGuest = snapshot.data ?? false;
        return _buildEmptyStateContent(context, isGuest);
      },
    );
  }

  Future<bool> _checkGuestMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isGuestMode') ?? false;
  }

  Widget _buildSearchEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (BuildContext context, double value, Widget? child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Icon(
                      Icons.search_off,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (BuildContext context, double value, Widget? child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Text(
                      'No results found',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ) ?? const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (BuildContext context, double value, Widget? child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Text(
                      'Try searching by category, amount, or note',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ) ?? TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (BuildContext context, double value, Widget? child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.95 + (0.05 * value),
                    child: OutlinedButton.icon(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Search'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateContent(BuildContext context, bool isGuest) {

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Welcome Icon
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (BuildContext context, double value, Widget? child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Welcome Text
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (BuildContext context, double value, Widget? child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Text(
                      isGuest ? 'Welcome, Guest!' : 'No expenses yet',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ) ?? const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Description Text
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (BuildContext context, double value, Widget? child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Text(
                      isGuest 
                          ? 'Start tracking your expenses by adding your first one 🚀'
                          : 'Start tracking your expenses by adding your first one 🚀',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ) ?? TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                );
              },
            ),
            // Sign-up prompt card for guest users
            if (isGuest) ...<Widget>[
              const SizedBox(height: 32),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (BuildContext context, double value, Widget? child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.95 + (0.05 * value),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.info_outline,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'You\'re using guest mode',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ) ?? const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Sign up to save your progress and sync across devices.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[700],
                                    ) ?? TextStyle(
                                      color: Colors.grey[700],
                                    ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    context.go(AppRoutes.signup);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Create Account'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _FilterButton extends StatelessWidget {
  const _FilterButton({
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
        : (isLightMode ? Colors.black87 : Colors.grey[300] ?? Colors.grey);
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 2.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : (isLightMode ? Colors.black87 : Colors.grey[700]),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
