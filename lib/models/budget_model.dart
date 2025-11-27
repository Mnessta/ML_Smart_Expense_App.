class BudgetModel {
  BudgetModel({
    required this.id,
    required this.category,
    required this.month,
    required this.year,
    required this.limit,
    this.spent = 0,
  });

  final String id;
  final String category;
  final int month; // 1-12
  final int year;
  final double limit;
  final double spent;

  double get progress => limit == 0 ? 0 : (spent / limit).clamp(0, 1);

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'category': category,
        'month': month,
        'year': year,
        'limit': limit,
        'spent': spent,
      };

  factory BudgetModel.fromMap(Map<String, dynamic> map) => BudgetModel(
        id: map['id'] as String,
        category: map['category'] as String,
        month: map['month'] as int,
        year: map['year'] as int,
        limit: (map['limit'] as num).toDouble(),
        spent: (map['spent'] as num?)?.toDouble() ?? 0,
      );
}































