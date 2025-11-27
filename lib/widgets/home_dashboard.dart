import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import 'dart:math' as math;

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({
    super.key,
    required this.balance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.todaySpending,
    required this.monthlySavings,
  });

  final double balance;
  final double totalIncome;
  final double totalExpenses;
  final double todaySpending;
  final double monthlySavings;

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> with SingleTickerProviderStateMixin {
  double _savingsGoal = 0;
  double _savedThisMonth = 0;
  bool _isBalanceVisible = true;
  bool _isSavingsVisible = true;
  late AnimationController _gradientController;
  bool _canEditSavings = true;
  static const _goalKey = 'dashboard_goal';
  static const _savedThisMonthKey = 'dashboard_saved_this_month';

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadSavingsGoal();
    _loadVisibilityState();
    _loadSavingsEditPermission();
  }

  double get _computedBalance => widget.balance;
  // Savings values come only from explicit user input, not from balance or other auto calculations.
  double get _computedSavings => _savingsGoal;
  double get _computedMonthlySavings => _savedThisMonth;
  double get _computedDailySpending => widget.todaySpending < 0 ? 0 : widget.todaySpending;

  Future<void> _loadVisibilityState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBalanceVisible = prefs.getBool('balanceVisible') ?? true;
      _isSavingsVisible = prefs.getBool('savingsVisible') ?? true;
    });
  }

  Future<void> _loadSavingsEditPermission() async {
    setState(() {
      // Allow editing savings for all users (including guest mode)
      _canEditSavings = true;
    });
  }

  Future<void> _saveBalanceVisibility(bool isVisible) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('balanceVisible', isVisible);
  }

  Future<void> _saveSavingsVisibility(bool isVisible) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('savingsVisible', isVisible);
  }

  Future<void> _loadSavingsGoal() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savingsGoal = prefs.getDouble(_goalKey) ?? 0;
      _savedThisMonth = prefs.getDouble(_savedThisMonthKey) ?? 0;
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  void openEditSheet(String title, double currentValue, Future<void> Function(double) onSave) {
    final controller = TextEditingController(text: currentValue.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            final double animationValue = _gradientController.value;
            final double sinValue = (math.sin(animationValue * 2 * math.pi) + 1) / 2;

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  stops: <double>[0.0, 0.5 + (0.2 * sinValue), 1.0],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: "Enter new amount",
                          labelStyle: const TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          hintText: "0.00",
                          hintStyle: TextStyle(
                            color: Colors.black.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w500,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black26, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black54, width: 2.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.9),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          final double? newValue = double.tryParse(controller.text);
                          if (newValue == null) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid number'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          try {
                            await onSave(newValue);
                            if (!mounted) return;
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Saved'),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            setState(() {});
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Save",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 0.85,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        BalanceCard(
          balance: _computedBalance,
          isVisible: _isBalanceVisible,
          onToggleVisibility: () {
            setState(() {
              _isBalanceVisible = !_isBalanceVisible;
            });
            _saveBalanceVisibility(_isBalanceVisible);
          },
          onTap: null,
          gradientController: _gradientController,
        ),
        Consumer<CurrencyProvider>(
          builder: (context, currencyProvider, child) {
            return DashboardCard(
              title: "Daily Spending",
              value: "${currencyProvider.symbol}${_computedDailySpending.toStringAsFixed(0)}",
              change: "",
              gradientController: _gradientController,
              onTap: null,
            );
          },
        ),
        SavingsCard(
          savings: _computedSavings,
          savingsGoal: _savingsGoal,
          monthlySavings: _computedMonthlySavings,
          isVisible: _isSavingsVisible,
          onToggleVisibility: () {
            setState(() {
              _isSavingsVisible = !_isSavingsVisible;
            });
            _saveSavingsVisibility(_isSavingsVisible);
          },
          onEditSavingsGoal: _canEditSavings
              ? () => openEditSheet("Edit Savings Goal", _savingsGoal, (double v) async {
                    setState(() {
                      _savingsGoal = v;
                    });
                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setDouble(_goalKey, v);
                  })
              : null,
          // For now, editing "Saved This Month" opens the same goal editor,
          // but now saves a separate, user-controlled "Saved This Month" value.
          onEditMonthlySavings: _canEditSavings
              ? () => openEditSheet("Edit Saved This Month", _savedThisMonth, (double v) async {
                    setState(() {
                      _savedThisMonth = v;
                    });
                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setDouble(_savedThisMonthKey, v);
                  })
              : null,
          onTap: null,
        ),
        FinancialHealthScoreCard(
          balance: _computedBalance,
          totalIncome: widget.totalIncome,
          gradientController: _gradientController,
        ),
      ],
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final VoidCallback? onTap;
  final AnimationController? gradientController;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    this.onTap,
    this.gradientController,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 20,
                ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            change,
            style: TextStyle(
              color: change.startsWith('-') ? Colors.redAccent : Colors.greenAccent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    if (gradientController != null) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: gradientController!,
          builder: (context, child) {
            final double animationValue = gradientController!.value;
            final double sinValue = (math.sin(animationValue * 2 * math.pi) + 1) / 2;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  stops: <double>[0.0, 0.5 + (0.2 * sinValue), 1.0],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: cardContent,
            );
          },
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: cardContent,
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  final double balance;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onTap;
  final AnimationController gradientController;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.isVisible,
    required this.onToggleVisibility,
    this.onTap,
    required this.gradientController,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: gradientController,
        builder: (context, child) {
          final double animationValue = gradientController.value;
          final double sinValue = (math.sin(animationValue * 2 * math.pi) + 1) / 2;

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                ],
                stops: <double>[0.0, 0.5 + (0.2 * sinValue), 1.0],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Balance",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onTap != null)
                          Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 22,
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            isVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: onToggleVisibility,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                Consumer<CurrencyProvider>(
                  builder: (context, currencyProvider, child) {
                    final String balanceText = "${currencyProvider.symbol}${balance.toStringAsFixed(0)}";
                    return isVisible
                        ? Text(
                            balanceText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Text(
                              balanceText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                  },
                ),
                const Text(
                  "+12%",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SavingsCard extends StatelessWidget {
  final double savings;
  final double savingsGoal;
  final double monthlySavings;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onTap;
  final VoidCallback? onEditSavingsGoal;
  final VoidCallback? onEditMonthlySavings;

  const SavingsCard({
    super.key,
    required this.savings,
    required this.savingsGoal,
    required this.monthlySavings,
    required this.isVisible,
    required this.onToggleVisibility,
    this.onTap,
    this.onEditSavingsGoal,
    this.onEditMonthlySavings,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Colors.green[400] ?? Colors.green,
              Colors.teal[400] ?? Colors.teal,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Eye icon at the top
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            // Savings Goal and Monthly Savings in the middle
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer<CurrencyProvider>(
                    builder: (context, currencyProvider, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: onEditSavingsGoal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                  child: Text(
                                    "Savings Goal",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (onEditSavingsGoal != null)
                                  Icon(
                                    Icons.edit,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: onEditSavingsGoal,
                            child: Builder(
                              builder: (context) {
                                final String savingsText = "${currencyProvider.symbol}${savingsGoal.toStringAsFixed(0)}";
                                return isVisible
                                    ? Text(
                                        savingsText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : ImageFiltered(
                                        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                        child: Text(
                                          savingsText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: onEditMonthlySavings,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Saved This Month",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                if (onEditMonthlySavings != null)
                                  Icon(
                                    Icons.edit,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: onEditMonthlySavings,
                            child: Builder(
                              builder: (context) {
                                final String monthlyText = "${currencyProvider.symbol}${monthlySavings.toStringAsFixed(0)}";
                                return isVisible
                                    ? Text(
                                        monthlyText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : ImageFiltered(
                                        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                        child: Text(
                                          monthlyText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            // "Every penny counts" at the bottom
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "🚀",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: const Text(
                    "Every penny counts",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FinancialHealthScoreCard extends StatelessWidget {
  final double balance;
  final double totalIncome;
  final AnimationController gradientController;

  const FinancialHealthScoreCard({
    super.key,
    required this.balance,
    required this.totalIncome,
    required this.gradientController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: gradientController,
      builder: (BuildContext context, Widget? child) {
        final double animationValue = gradientController.value;
        final double sinValue = (math.sin(animationValue * 2 * math.pi) + 1) / 2;

        // Simple financial health score based on balance vs income
        double score = 0;
        if (totalIncome > 0) {
          score = (balance / totalIncome) * 100;
        }
        score = score.clamp(0, 100);

        String scoreLabel;
        Color scoreColor;
        if (score >= 75) {
          scoreLabel = 'Great';
          scoreColor = Colors.greenAccent;
        } else if (score >= 50) {
          scoreLabel = 'Good';
          scoreColor = Colors.lightGreenAccent;
        } else if (score >= 25) {
          scoreLabel = 'Fair';
          scoreColor = Colors.orangeAccent;
        } else {
          scoreLabel = 'Needs Attention';
          scoreColor = Colors.redAccent;
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.9),
                Theme.of(context).colorScheme.primary.withValues(
                  alpha: 0.7 + (0.2 * sinValue),
                ),
              ],
              stops: const <double>[0.0, 0.5, 1.0],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const <Widget>[
                  Flexible(
                    child: Text(
                      'Financial Health',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Text(
                    scoreLabel,
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${score.toStringAsFixed(0)}/100',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep your spending lower than your income to improve your score over time.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}