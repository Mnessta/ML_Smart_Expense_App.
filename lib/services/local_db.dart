import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDB {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'ml_expense.db');
    _db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE expenses (
      id TEXT PRIMARY KEY,
      remote_id TEXT,
      user_id TEXT,
      amount REAL,
      category TEXT,
      payment TEXT,
      note TEXT,
      created_at TEXT,
      updated_at TEXT,
      synced INTEGER
    )
    ''');

    await db.execute('''
    CREATE TABLE budgets (
      id TEXT PRIMARY KEY,
      user_id TEXT,
      category TEXT,
      limit_amount REAL,
      period_start TEXT,
      period_end TEXT,
      created_at TEXT
    )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_synced ON expenses(synced)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_remote_id ON expenses(remote_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_created_at ON expenses(created_at)');
  }

  // Insert local expense
  static Future<void> insertExpense(Map<String, dynamic> e) async {
    final dbClient = await db;
    await dbClient.insert('expenses', e, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedExpenses() async {
    final dbClient = await db;
    final res = await dbClient.query('expenses', where: 'synced = ?', whereArgs: [0]);
    return res;
  }

  static Future<void> markExpenseSynced(String localId, String remoteId) async {
    final dbClient = await db;
    await dbClient.update(
      'expenses',
      {'synced': 1, 'remote_id': remoteId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  static Future<List<Map<String, dynamic>>> getAllExpensesForUser(String? userId) async {
    final dbClient = await db;
    if (userId != null) {
      return await dbClient.query(
        'expenses',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    } else {
      return await dbClient.query('expenses', orderBy: 'created_at DESC');
    }
  }

  // Get expenses by date range
  static Future<List<Map<String, dynamic>>> getExpensesByDateRange(
    String? userId,
    DateTime start,
    DateTime end,
  ) async {
    final dbClient = await db;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    if (userId != null) {
      return await dbClient.query(
        'expenses',
        where: 'user_id = ? AND created_at >= ? AND created_at <= ?',
        whereArgs: [userId, startStr, endStr],
        orderBy: 'created_at DESC',
      );
    } else {
      return await dbClient.query(
        'expenses',
        where: 'created_at >= ? AND created_at <= ?',
        whereArgs: [startStr, endStr],
        orderBy: 'created_at DESC',
      );
    }
  }

  // Update expense
  static Future<void> updateExpense(String id, Map<String, dynamic> updates) async {
    final dbClient = await db;
    await dbClient.update('expenses', updates, where: 'id = ?', whereArgs: [id]);
  }

  // Delete expense
  static Future<void> deleteExpense(String id) async {
    final dbClient = await db;
    await dbClient.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteAllExpenses(String? userId) async {
    final dbClient = await db;
    if (userId != null) {
      await dbClient.delete('expenses', where: 'user_id = ?', whereArgs: [userId]);
    } else {
      await dbClient.delete('expenses');
    }
  }

  // Budget methods
  static Future<void> insertBudget(Map<String, dynamic> budget) async {
    final dbClient = await db;
    await dbClient.insert('budgets', budget, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getBudgetsForUser(String? userId) async {
    final dbClient = await db;
    if (userId != null) {
      return await dbClient.query(
        'budgets',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    } else {
      return await dbClient.query('budgets', orderBy: 'created_at DESC');
    }
  }
}














