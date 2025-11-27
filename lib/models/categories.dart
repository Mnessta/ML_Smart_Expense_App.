import 'package:flutter/material.dart';

final List<Map<String, dynamic>> categories = [
  {'key': 'Food', 'icon': Icons.fastfood, 'color': Colors.orange},
  {'key': 'Transport', 'icon': Icons.directions_bus, 'color': Colors.blue},
  {'key': 'Shopping', 'icon': Icons.shopping_bag, 'color': Colors.purple},
  {'key': 'Bills', 'icon': Icons.receipt_long, 'color': Colors.red},
  {'key': 'Airtime', 'icon': Icons.phone_android, 'color': Colors.teal},
  {'key': 'Entertainment', 'icon': Icons.movie, 'color': Colors.pink},
  {'key': 'Other', 'icon': Icons.more_horiz, 'color': Colors.grey},
];

IconData? getCategoryIcon(String category) {
  try {
    return categories.firstWhere((c) => c['key'] == category)['icon'] as IconData;
  } catch (e) {
    return Icons.category;
  }
}

Color? getCategoryColor(String category) {
  try {
    return categories.firstWhere((c) => c['key'] == category)['color'] as Color;
  } catch (e) {
    return Colors.grey;
  }
}














