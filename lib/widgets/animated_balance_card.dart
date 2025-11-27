import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import 'animated_counter.dart';

class AnimatedBalanceCard extends StatefulWidget {
  const AnimatedBalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expenses,
    required this.savings,
  });

  final double balance;
  final double income;
  final double expenses;
  final double savings;

  @override
  State<AnimatedBalanceCard> createState() => _AnimatedBalanceCardState();
}

class _AnimatedBalanceCardState extends State<AnimatedBalanceCard>
    with SingleTickerProviderStateMixin {
  bool _isBalanceVisible = true;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadVisibilityState();
  }

  Future<void> _loadVisibilityState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isBalanceVisible = prefs.getBool('balanceVisible') ?? true;
      });
    }
  }

  Future<void> _saveVisibilityState(bool isVisible) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('balanceVisible', isVisible);
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (BuildContext context, Widget? child) {
        final double animationValue = _gradientController.value;
        final double sinValue = (math.sin(animationValue * 2 * math.pi) + 1) / 2;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Balance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isBalanceVisible = !_isBalanceVisible;
                        });
                        _saveVisibilityState(_isBalanceVisible);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Consumer<CurrencyProvider>(
                  builder: (context, currencyProvider, child) {
                    final String balanceText = "${currencyProvider.symbol}${widget.balance.toStringAsFixed(2)}";
                    return _isBalanceVisible
                        ? AnimatedCounter(
                            value: widget.balance,
                            prefix: currencyProvider.symbol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Text(
                              balanceText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                  },
                ),
                const SizedBox(height: 24),
                Consumer<CurrencyProvider>(
                  builder: (context, currencyProvider, child) {
                    return Row(
                      children: <Widget>[
                        Expanded(
                          child: _BalanceItem(
                            label: 'Income',
                            value: widget.income,
                            icon: Icons.arrow_upward,
                            color: Colors.green[100] ?? Colors.green,
                            currencySymbol: currencyProvider.symbol,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _BalanceItem(
                            label: 'Expenses',
                            value: widget.expenses,
                            icon: Icons.arrow_downward,
                            color: Colors.red[100] ?? Colors.red,
                            currencySymbol: currencyProvider.symbol,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _BalanceItem(
                            label: 'Savings',
                            value: widget.savings,
                            icon: Icons.savings,
                            color: Colors.blue[100] ?? Colors.blue,
                            currencySymbol: currencyProvider.symbol,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BalanceItem extends StatelessWidget {
  const _BalanceItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.currencySymbol,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$currencySymbol${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

