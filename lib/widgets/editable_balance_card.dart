import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import 'animated_counter.dart';

class EditableBalanceCard extends StatefulWidget {
  const EditableBalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expenses,
    required this.savings,
    this.onIncomeUpdated,
  });

  final double balance;
  final double income;
  final double expenses;
  final double savings;
  final void Function(double)? onIncomeUpdated;

  @override
  State<EditableBalanceCard> createState() => _EditableBalanceCardState();
}

class _EditableBalanceCardState extends State<EditableBalanceCard>
    with SingleTickerProviderStateMixin {
  bool _isBalanceVisible = true;
  late AnimationController _gradientController;
  bool _isEditingIncome = false;
  final TextEditingController _incomeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _incomeController.text = widget.income.toStringAsFixed(2);
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
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    final double? newIncome = double.tryParse(_incomeController.text);
    if (newIncome != null && newIncome >= 0) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('userIncome', newIncome);
      if (mounted) {
        setState(() {
          _isEditingIncome = false;
        });
        widget.onIncomeUpdated?.call(newIncome);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Income updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
                          child: _EditableBalanceItem(
                            label: 'Income',
                            value: widget.income,
                            icon: Icons.arrow_upward,
                            color: Colors.green[100] ?? Colors.green,
                            isEditing: _isEditingIncome,
                            controller: _incomeController,
                            currencySymbol: currencyProvider.symbol,
                            onEdit: () {
                              setState(() {
                                _isEditingIncome = true;
                              });
                            },
                            onSave: _saveIncome,
                            onCancel: () {
                              setState(() {
                                _isEditingIncome = false;
                                _incomeController.text = widget.income.toStringAsFixed(2);
                              });
                            },
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

class _EditableBalanceItem extends StatelessWidget {
  const _EditableBalanceItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isEditing,
    required this.controller,
    required this.currencySymbol,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final bool isEditing;
  final TextEditingController controller;
  final String currencySymbol;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
            if (!isEditing)
              GestureDetector(
                onTap: onEdit,
                child: Icon(Icons.edit, color: color, size: 16),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (isEditing)
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    prefixText: currencySymbol,
                    prefixStyle: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: color),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: color),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: color, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.white, size: 18),
                onPressed: onSave,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                onPressed: onCancel,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          )
        else
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





