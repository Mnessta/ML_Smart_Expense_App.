import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to manage currency settings across the app
class CurrencyProvider extends ChangeNotifier {
  static const String _currencyKey = 'currency';
  String _currency = 'USD';

  CurrencyProvider() {
    _loadCurrency();
  }

  String get currency => _currency;

  /// Get currency symbol
  String get symbol {
    switch (_currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'KSH':
        return 'KSh';
      case 'INR':
        return '₹';
      case 'NGN':
        return '₦';
      case 'ZAR':
        return 'R';
      case 'UGX':
        return 'USh';
      default:
        return '\$';
    }
  }

  /// Get currency code (e.g., USD, EUR)
  String get code => _currency;

  Future<void> _loadCurrency() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedCurrency = prefs.getString(_currencyKey) ?? 'USD';
    // Migrate old 'KES' to 'KSH'
    if (savedCurrency == 'KES') {
      savedCurrency = 'KSH';
      await prefs.setString(_currencyKey, 'KSH');
    }
    _currency = savedCurrency;
    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    if (_currency == currency) return;
    
    _currency = currency;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency);
    notifyListeners();
  }

  /// Format amount with currency symbol
  String formatAmount(double amount) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Format amount with currency code
  String formatAmountWithCode(double amount) {
    return '$symbol${amount.toStringAsFixed(2)} ($_currency)';
  }
}













