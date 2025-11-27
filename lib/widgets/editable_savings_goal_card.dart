import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditableSavingsGoalCard extends StatefulWidget {
  const EditableSavingsGoalCard({
    super.key,
    required this.currentSavings,
    required this.monthlyGoal,
    this.onGoalUpdated,
  });

  final double currentSavings;
  final double monthlyGoal;
  final void Function(double)? onGoalUpdated;

  @override
  State<EditableSavingsGoalCard> createState() => _EditableSavingsGoalCardState();
}

class _EditableSavingsGoalCardState extends State<EditableSavingsGoalCard> {
  bool _isEditingGoal = false;
  final TextEditingController _goalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _goalController.text = widget.monthlyGoal.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    final double? newGoal = double.tryParse(_goalController.text);
    if (newGoal != null && newGoal >= 0) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('savingsGoal', newGoal);
      if (mounted) {
        setState(() {
          _isEditingGoal = false;
        });
        widget.onGoalUpdated?.call(newGoal);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Savings goal updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = widget.monthlyGoal > 0 ? (widget.currentSavings / widget.monthlyGoal).clamp(0.0, 1.0) : 0.0;
    final double percentage = progress * 100;

    String getBadge() {
      if (percentage >= 100) return '🏆 Goal Achieved!';
      if (percentage >= 75) return '🎯 Almost There!';
      if (percentage >= 50) return '💪 Halfway!';
      if (percentage >= 25) return '🌟 Great Start!';
      return '🚀 Keep Going!';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Savings Goal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: <Widget>[
                  Text(
                    getBadge(),
                    style: const TextStyle(fontSize: 20),
                  ),
                  if (!_isEditingGoal)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                      onPressed: () {
                        setState(() {
                          _isEditingGoal = true;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Saved this month',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${widget.currentSavings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  const Text(
                    'Goal',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_isEditingGoal)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: _goalController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              prefixText: '\$',
                              prefixStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.white, size: 18),
                          onPressed: _saveGoal,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 18),
                          onPressed: () {
                            setState(() {
                              _isEditingGoal = false;
                              _goalController.text = widget.monthlyGoal.toStringAsFixed(2);
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    )
                  else
                    Text(
                      '\$${widget.monthlyGoal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: <Widget>[
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                builder: (BuildContext context, double value, Widget? child) {
                  return Container(
                    height: 12,
                    width: MediaQuery.of(context).size.width * value * 0.85,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(0)}% complete',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

















