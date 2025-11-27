import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';
import 'db_service.dart';

/// Service for managing offline operations and sync queue
class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  
  /// Check if device is online
  Future<bool> isOnline() async {
    final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    _isOnline = results.any((ConnectivityResult result) => 
        result != ConnectivityResult.none);
    return _isOnline;
  }

  /// Stream of connectivity changes
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((List<ConnectivityResult> results) {
      _isOnline = results.any((ConnectivityResult result) => 
          result != ConnectivityResult.none);
      return _isOnline;
    });
  }

  /// Add expense to sync queue
  Future<void> queueExpense(ExpenseModel expense) async {
    if (await isOnline()) {
      return; // Don't queue if online, sync immediately
    }
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList('sync_queue_expenses') ?? <String>[];
    queue.add(expense.id);
    await prefs.setStringList('sync_queue_expenses', queue);
  }

  /// Add budget to sync queue
  Future<void> queueBudget(BudgetModel budget) async {
    if (await isOnline()) {
      return; // Don't queue if online, sync immediately
    }
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList('sync_queue_budgets') ?? <String>[];
    queue.add(budget.id);
    await prefs.setStringList('sync_queue_budgets', queue);
  }

  /// Get queued expense IDs
  Future<List<String>> getQueuedExpenses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('sync_queue_expenses') ?? <String>[];
  }

  /// Get queued budget IDs
  Future<List<String>> getQueuedBudgets() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('sync_queue_budgets') ?? <String>[];
  }

  /// Clear sync queue
  Future<void> clearQueue() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('sync_queue_expenses');
    await prefs.remove('sync_queue_budgets');
  }

  /// Remove expense from queue
  Future<void> removeFromQueue(String expenseId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList('sync_queue_expenses') ?? <String>[];
    queue.remove(expenseId);
    await prefs.setStringList('sync_queue_expenses', queue);
  }

  /// Process sync queue when online
  Future<void> processQueue() async {
    if (!await isOnline()) return;
    
    final List<String> expenseIds = await getQueuedExpenses();
    final List<String> budgetIds = await getQueuedBudgets();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Process expenses
    for (final String expenseId in expenseIds) {
      try {
        final ExpenseModel? expense = await DbService().getExpenseById(expenseId);
        if (expense != null) {
          // Sync expense (this would call your sync service)
          // Note: SyncService will handle the actual sync
          await removeFromQueue(expenseId);
        }
      } catch (_) {
        // Keep in queue if sync fails
      }
    }
    
    // Process budgets
    for (final String budgetId in budgetIds) {
      try {
        // Sync budget logic would go here
        final List<String> queue = prefs.getStringList('sync_queue_budgets') ?? <String>[];
        queue.remove(budgetId);
        await prefs.setStringList('sync_queue_budgets', queue);
      } catch (_) {
        // Keep in queue if sync fails
      }
    }
  }
}

