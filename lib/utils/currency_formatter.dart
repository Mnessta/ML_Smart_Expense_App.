import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Utility class for formatting currency throughout the app
class CurrencyFormatter {
  static const String _currencyKey = 'currency';
  static String _currency = 'USD';

  /// Initialize currency from preferences
  static Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedCurrency = prefs.getString(_currencyKey) ?? 'USD';
    // Migrate old 'KES' to 'KSH'
    if (savedCurrency == 'KES') {
      savedCurrency = 'KSH';
      await prefs.setString(_currencyKey, 'KSH');
    }
    _currency = savedCurrency;
  }

  /// Get current currency code
  static String get currency => _currency;

  /// Get currency symbol
  static String get symbol {
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

  /// Format amount with currency symbol
  static String format(double amount) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Format amount with proper locale formatting
  static String formatWithLocale(double amount, {String? locale}) {
    final NumberFormat formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
      locale: locale ?? 'en_US',
    );
    return formatter.format(amount);
  }

  /// Update currency (called when user changes currency in settings)
  static Future<void> updateCurrency(String currency) async {
    _currency = currency;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency);
  }

  /// Get currency name
  static String getCurrencyName(String code) {
    switch (code) {
      case 'USD':
        return 'US Dollar';
      case 'EUR':
        return 'Euro';
      case 'GBP':
        return 'British Pound';
      case 'KSH':
        return 'Kenyan Shilling';
      case 'INR':
        return 'Indian Rupee';
      case 'NGN':
        return 'Nigerian Naira';
      case 'ZAR':
        return 'South African Rand';
      case 'UGX':
        return 'Ugandan Shilling';
      default:
        return code;
    }
  }
}













