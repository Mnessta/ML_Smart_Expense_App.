import 'package:flutter/material.dart';

class CategoryCarousel extends StatelessWidget {
  const CategoryCarousel({
    super.key,
    required this.categoryBreakdown,
    this.onCategoryTap,
  });

  final Map<String, double> categoryBreakdown;
  final void Function(String)? onCategoryTap;

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍔';
      case 'bills':
        return '💡';
      case 'transport':
        return '🚗';
      case 'shopping':
        return '🛍️';
      case 'entertainment':
        return '🎬';
      case 'health':
        return '🏥';
      case 'education':
        return '📚';
      default:
        return '💰';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'bills':
        return Colors.blue;
      case 'transport':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'entertainment':
        return Colors.red;
      case 'health':
        return Colors.green;
      case 'education':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, double>> sortedCategories = categoryBreakdown.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) => 
          b.value.compareTo(a.value));

    if (sortedCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sortedCategories.length,
        itemBuilder: (BuildContext context, int index) {
          final MapEntry<String, double> entry = sortedCategories[index];
          final String category = entry.key;
          final double amount = entry.value;
          final Color color = _getCategoryColor(category);

          return GestureDetector(
            onTap: () => onCategoryTap?.call(category),
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    color,
                    color.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      _getCategoryEmoji(category),
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

