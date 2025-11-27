import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense_model.dart';
import '../providers/currency_provider.dart';
import '../utils/constants.dart';

class WalletSection extends StatelessWidget {
  const WalletSection({
    super.key,
    required this.expenses,
  });

  final List<ExpenseModel> expenses;

  Map<String, double> _calculateWalletBalances() {
    final Map<String, double> balances = <String, double>{};
    
    for (final ExpenseModel expense in expenses) {
      final String wallet = expense.paymentMethod;
      if (expense.type == TransactionType.income) {
        balances[wallet] = (balances[wallet] ?? 0) + expense.amount;
      } else {
        balances[wallet] = (balances[wallet] ?? 0) - expense.amount;
      }
    }
    
    // Ensure all payment methods are shown
    for (final String method in AppConstants.paymentMethods) {
      balances.putIfAbsent(method, () => 0);
    }
    
    return balances;
  }

  IconData _getWalletIcon(String wallet) {
    switch (wallet.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'mobile money':
      case 'm-pesa':
        return Icons.phone_android;
      case 'bank transfer':
        return Icons.account_balance;
      default:
        return Icons.wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final CurrencyProvider currencyProvider = context.watch<CurrencyProvider>();
    final Map<String, double> balances = _calculateWalletBalances();
    final List<MapEntry<String, double>> sortedBalances = balances.entries
        .where((MapEntry<String, double> e) => e.value != 0 || balances.length <= 3)
        .toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) => b.value.compareTo(a.value));

    if (sortedBalances.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Wallet Balance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: sortedBalances.take(4).map((MapEntry<String, double> entry) {
                final bool isPositive = entry.value >= 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPositive ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        _getWalletIcon(entry.key),
                        size: 20,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            currencyProvider.formatAmount(entry.value.abs()),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPositive ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

