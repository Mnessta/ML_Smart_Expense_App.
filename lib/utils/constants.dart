import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF00C9A7);
  static const Color backgroundLight = Color(0xFFF5F6FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color error = Color(0xFFFF6B6B);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF00C9A7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppConstants {
  static const List<String> defaultCategories = <String>[
    'Food',
    'Bills',
    'Transport',
    'Shopping',
    'Entertainment',
    'Health',
    'Education',
    'Other',
  ];

  static const List<String> paymentMethods = <String>[
    'Cash',
    'Card',
    'Mobile Money',
    'Bank Transfer',
    'Other',
  ];

  static const List<String> currencies = <String>[
    'USD', 'EUR', 'GBP', 'KSH', 'INR', 'NGN', 'ZAR', 'UGX'
  ];
}































