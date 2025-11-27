enum TransactionType { expense, income }

class ExpenseModel {
  ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.paymentMethod = 'Cash',
    this.isSynced = false,
    this.type = TransactionType.expense,
  });

  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final String paymentMethod;
  final bool isSynced;
  final TransactionType type;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'amount': amount,
        'category': category,
        'date': date.millisecondsSinceEpoch,
        'note': note,
        'paymentMethod': paymentMethod,
        'isSynced': isSynced ? 1 : 0,
        'type': type == TransactionType.income ? 'income' : 'expense',
      };

  factory ExpenseModel.fromMap(Map<String, dynamic> map) => ExpenseModel(
        id: map['id'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        note: map['note'] as String?,
        paymentMethod: (map['paymentMethod'] as String?) ?? 'Cash',
        isSynced: (map['isSynced'] as int? ?? 0) == 1,
        type: (map['type'] as String?) == 'income' ? TransactionType.income : TransactionType.expense,
      );

  ExpenseModel copyWith({
    String? id,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    String? paymentMethod,
    bool? isSynced,
    TransactionType? type,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isSynced: isSynced ?? this.isSynced,
      type: type ?? this.type,
    );
  }
}


