import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

/// Provider for managing expenses
class ExpenseProvider extends ChangeNotifier {
  List<ExpenseModel> _expenses = <ExpenseModel>[];
  bool _isLoading = false;
  String? _error;

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ExpenseProvider() {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _expenses = await DbService().getExpenses();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      final user = AuthService().currentUser;
      await DbService().upsertExpense(expense, userId: user?.id);
      
      // Sync to cloud in background if user is logged in
      if (user != null && !expense.isSynced) {
        SyncService().syncExpense(expense).catchError((_) {
          // Sync failed - expense will sync later
        });
      }
      
      await loadExpenses();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      final user = AuthService().currentUser;
      await DbService().upsertExpense(expense, userId: user?.id);
      
      // Sync to cloud in background if user is logged in
      if (user != null && !expense.isSynced) {
        SyncService().syncExpense(expense).catchError((_) {
          // Sync failed - expense will sync later
        });
      }
      
      await loadExpenses();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      // Get remote_id before deleting
      final String? remoteId = await DbService().getExpenseRemoteId(id);
      
      // Delete from local database
      await DbService().deleteExpense(id);
      
      // Delete from server in background
      if (remoteId != null) {
        SyncService().deleteExpenseFromServer(id, remoteId: remoteId).catchError((_) {
          // Sync delete failed - local delete still happened
        });
      }
      
      await loadExpenses();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  List<ExpenseModel> getExpensesByCategory(String category) {
    return _expenses.where((ExpenseModel e) => e.category == category).toList();
  }

  List<ExpenseModel> getExpensesByDateRange(DateTime start, DateTime end) {
    return _expenses.where((ExpenseModel e) {
      return e.date.isAfter(start.subtract(const Duration(days: 1))) &&
          e.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  double getTotalExpenses() {
    return _expenses
        .where((ExpenseModel e) => e.type == TransactionType.expense)
        .fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);
  }

  double getTotalIncome() {
    return _expenses
        .where((ExpenseModel e) => e.type == TransactionType.income)
        .fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);
  }

  double getBalance() {
    return getTotalIncome() - getTotalExpenses();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

