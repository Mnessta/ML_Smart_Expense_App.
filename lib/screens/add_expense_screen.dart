import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/currency_provider.dart';
import '../services/db_service.dart';
import '../services/finance_service.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/category_picker.dart';
import '../widgets/quick_add_templates.dart';
import '../widgets/success_animation.dart';
import '../app_router.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.expense, this.onClose});

  final ExpenseModel? expense;
  final VoidCallback? onClose;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  String _category = AppConstants.defaultCategories.first;
  String _payment = AppConstants.paymentMethods.first;
  DateTime _date = DateTime.now();
  bool _saving = false;
  TransactionType _type = TransactionType.expense;
  bool _showSuccess = false;
  late AnimationController _animationController;
  final DraggableScrollableController _draggableController = DraggableScrollableController();
  double _linkedIncome = 0.0;
  double _linkedBalance = 0.0;
  bool _isFinanceSummaryLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Pre-populate fields if editing an expense
    if (widget.expense != null) {
      final ExpenseModel expense = widget.expense!;
      _amount.text = expense.amount.toStringAsFixed(2);
      _note.text = expense.note ?? '';
      _category = expense.category;
      _payment = expense.paymentMethod;
      _date = expense.date;
      _type = expense.type;
    }
    _loadFinanceSnapshot();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _animationController.dispose();
    _draggableController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  void _applyTemplate(QuickAddTemplate template) {
    setState(() {
      _amount.clear();
      _category = template.category;
      _type = TransactionType.expense;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _save() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    
    final double amount = double.parse(_amount.text.trim());
    final ExpenseModel expense = ExpenseModel(
      id: widget.expense?.id ?? 'exp_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      category: _category,
      date: _date,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      paymentMethod: _payment,
      isSynced: widget.expense?.isSynced ?? false, // Keep existing sync status if editing
      type: _type,
    );
    
    await DbService().upsertExpense(expense);
    
    // Update sync fields in database
    final db = await DbService().database;
    final user = AuthService().currentUser;
    if (user != null) {
      await db.update(
        'expenses',
        <String, Object?>{
          'user_id': user.id,
          'created_at': _date.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'isSynced': widget.expense?.isSynced == true ? 1 : 0, // Mark as unsynced if new
        },
        where: 'id = ?',
        whereArgs: <Object?>[expense.id],
      );
    }
    
    // Sync to cloud in background (non-blocking)
    if (widget.expense?.isSynced != true) {
      SyncService().syncExpense(expense).catchError((_) {
        // Sync failed - expense will sync later
      });
    }
    
    if (!mounted) return;
    
    setState(() {
      _saving = false;
      _showSuccess = true;
    });
    
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    setState(() => _showSuccess = false);
    _closeScreen();
  }

  Future<void> _loadFinanceSnapshot() async {
    final double linkedIncome = await FinanceService.getLinkedIncome();
    double remaining = linkedIncome;
    if (linkedIncome > 0) {
      final List<ExpenseModel> expenses = await DbService().getExpenses();
      final double totalExpenses = expenses
          .where((ExpenseModel e) => e.type == TransactionType.expense)
          .fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);
      remaining = linkedIncome - totalExpenses;
    }
    if (!mounted) return;
    setState(() {
      _linkedIncome = linkedIncome;
      _linkedBalance = remaining;
      _isFinanceSummaryLoading = false;
    });
  }

  Future<void> _pickReceipt() async {
    // Placeholder for receipt/image picker functionality
    // Would need image_picker package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt upload coming soon!')),
    );
  }

  /// Full expense page with Quick Add, category, date, payment, etc.
  Widget _buildExpensePage(BuildContext context, CurrencyProvider currencyProvider, DateFormat fmt) {
    return Column(
      key: const ValueKey<String>('expense'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Quick Add Templates
        QuickAddTemplates(
          onTemplateSelected: _applyTemplate,
        ),
        const SizedBox(height: 24),
        // Amount Input
        Text(
          'Amount (${currencyProvider.code})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixText: '${currencyProvider.symbol} ',
            prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          ),
          validator: Validators.amount,
        ),
        const SizedBox(height: 24),
        // Category Picker
        CategoryPicker(
          selectedCategory: _category,
          onCategorySelected: (String category) {
            setState(() => _category = category);
            HapticFeedback.selectionClick();
          },
        ),
        const SizedBox(height: 24),
        // Description
        TextFormField(
          controller: _note,
          decoration: InputDecoration(
            labelText: 'Description (optional)',
            hintText: 'e.g., Lunch with friends',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            prefixIcon: const Icon(Icons.note),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        // Date Selector
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300] ?? Colors.grey),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      fmt.format(_date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Payment Method
        DropdownButtonFormField<String>(
          initialValue: _payment,
          decoration: InputDecoration(
            labelText: 'Payment Method',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            prefixIcon: const Icon(Icons.payment),
          ),
          items: AppConstants.paymentMethods
              .map(
                (String method) => DropdownMenuItem<String>(
                      value: method,
                      child: Text(method),
                    ),
              )
              .toList(),
          onChanged: (String? v) => setState(() => _payment = v ?? _payment),
        ),
        const SizedBox(height: 24),
        // Receipt Upload (Optional)
        OutlinedButton.icon(
          onPressed: _pickReceipt,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Add Receipt (Optional)'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  /// Income page with only amount and optional description.
  Widget _buildIncomePage(BuildContext context, CurrencyProvider currencyProvider) {
    return Column(
      key: const ValueKey<String>('income'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Amount Input
        Text(
          'Amount (${currencyProvider.code})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixText: '${currencyProvider.symbol} ',
            prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          ),
          validator: Validators.amount,
        ),
        const SizedBox(height: 24),
        // Description (optional)
        TextFormField(
          controller: _note,
          decoration: InputDecoration(
            labelText: 'Description (optional)',
            hintText: 'e.g., Salary for November',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            prefixIcon: const Icon(Icons.note),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  void _closeScreen() {
    // Call the onClose callback if provided (for IndexedStack navigation)
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    
    // Otherwise, try to pop the navigator
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // If can't pop, try to navigate to home using go_router
      try {
        context.go(AppRoutes.home);
      } catch (_) {
        // Fallback: just pop if possible
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat fmt = DateFormat.yMMMd();
    final CurrencyProvider currencyProvider = context.watch<CurrencyProvider>();
    
    if (_showSuccess) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const SuccessAnimation(),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          _closeScreen();
        }
      },
      child: SafeArea(
        child: GestureDetector(
          onVerticalDragUpdate: (DragUpdateDetails details) {
            // Detect downward swipe
            if (details.delta.dy > 0) {
              // Swiping down
            }
          },
          onVerticalDragEnd: (DragEndDetails details) {
            // If swiped down significantly, close the screen
            if (details.velocity.pixelsPerSecond.dy > 500) {
              _closeScreen();
            }
          },
          child: DraggableScrollableSheet(
            controller: _draggableController,
            initialChildSize: 0.9,
            minChildSize: 0.1,
            maxChildSize: 0.95,
            snap: true,
            snapSizes: const [0.1, 0.5],
            builder: (BuildContext context, ScrollController scrollController) {
              // Listen to draggable controller to detect when dragged to minimum
              _draggableController.addListener(() {
                if (_draggableController.size <= 0.15) {
                  // User dragged to minimum, close the screen
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _closeScreen();
                    }
                  });
                }
              });
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: <Widget>[
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.expense != null
                            ? (_type == TransactionType.income ? 'Edit Income' : 'Edit Expense')
                            : (_type == TransactionType.income ? 'Add Income' : 'Add Expense'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _closeScreen,
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Type Toggle
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: _TypeToggleButton(
                                  label: 'Expense',
                                  icon: Icons.arrow_downward,
                                  isSelected: _type == TransactionType.expense,
                                  color: Colors.red,
                                  onTap: () => setState(() => _type = TransactionType.expense),
                                ),
                              ),
                              Expanded(
                                child: _TypeToggleButton(
                                  label: 'Income',
                                  icon: Icons.arrow_upward,
                                  isSelected: _type == TransactionType.income,
                                  color: Colors.green,
                                  onTap: () => setState(() => _type = TransactionType.income),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!_isFinanceSummaryLoading && _linkedIncome > 0) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Linked Income',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${currencyProvider.symbol}${_linkedIncome.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Remaining balance: ${currencyProvider.symbol}${_linkedBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: _linkedBalance >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        // Expense / Income pages
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            final bool isExpensePage = (child.key as ValueKey<String>).value == 'expense';
                            final Offset beginOffset = isExpensePage
                                ? const Offset(-0.1, 0) // slide from left for expense
                                : const Offset(0.1, 0); // slide from right for income
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: beginOffset,
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeInOutCubic,
                                  ),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: _type == TransactionType.expense
                              ? _buildExpensePage(context, currencyProvider, fmt)
                              : _buildIncomePage(context, currencyProvider),
                        ),
                        const SizedBox(height: 24),
                        // Save Button (shared for both pages)
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  widget.expense != null
                                      ? (_type == TransactionType.income ? 'Update Income' : 'Update Expense')
                                      : (_type == TransactionType.income ? 'Save Income' : 'Save Expense'),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TypeToggleButton extends StatelessWidget {
  const _TypeToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
