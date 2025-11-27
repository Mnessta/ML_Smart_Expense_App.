import 'package:flutter_test/flutter_test.dart';
import 'package:ml_smart_expense_track/services/db_service.dart';
import 'package:ml_smart_expense_track/models/expense_model.dart';

void main() {
  group('DbService', () {
    late DbService dbService;

    setUp(() {
      dbService = DbService();
    });

    test('should create expense', () async {
      final ExpenseModel expense = ExpenseModel(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        amount: 100.0,
        category: 'Food',
        date: DateTime.now(),
        type: TransactionType.expense,
      );

      await dbService.upsertExpense(expense);
      final ExpenseModel? retrieved = await dbService.getExpenseById(expense.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.amount, equals(100.0));
      expect(retrieved.category, equals('Food'));
    });

    test('should delete expense', () async {
      final ExpenseModel expense = ExpenseModel(
        id: 'test_delete_${DateTime.now().millisecondsSinceEpoch}',
        amount: 50.0,
        category: 'Transport',
        date: DateTime.now(),
        type: TransactionType.expense,
      );

      await dbService.upsertExpense(expense);
      await dbService.deleteExpense(expense.id);
      final ExpenseModel? retrieved = await dbService.getExpenseById(expense.id);

      expect(retrieved, isNull);
    });
  });
}

















