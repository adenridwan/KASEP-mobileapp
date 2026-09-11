import 'package:sqflite/sqflite.dart';
import '../../models/fund_source.dart';
import 'database_helper.dart';

class FundSourceRepository {
  static final FundSourceRepository instance = FundSourceRepository._init();
  FundSourceRepository._init();

  // ==================== CREATE ====================

  /// Insert a new fund source
  Future<void> create(FundSource source) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'fund_sources',
      source.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==================== READ ====================

  /// Get all active fund sources
  Future<List<FundSource>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'fund_sources',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'createdAt ASC',
    );
    return maps.map((map) => FundSource.fromMap(map)).toList();
  }

  /// Get all fund sources including inactive
  Future<List<FundSource>> getAllIncludingInactive() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'fund_sources',
      orderBy: 'createdAt ASC',
    );
    return maps.map((map) => FundSource.fromMap(map)).toList();
  }

  /// Get fund source by ID
  Future<FundSource?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'fund_sources',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return FundSource.fromMap(maps.first);
  }

  /// Get fund source by name
  Future<FundSource?> getByName(String name) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'fund_sources',
      where: 'name = ? AND isActive = 1',
      whereArgs: [name],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return FundSource.fromMap(maps.first);
  }

  // ==================== UPDATE ====================

  /// Update a fund source
  Future<int> update(FundSource source) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'fund_sources',
      source.toMap(),
      where: 'id = ?',
      whereArgs: [source.id],
    );
  }

  /// Deactivate a fund source (soft delete)
  Future<int> deactivate(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'fund_sources',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Reactivate a fund source
  Future<int> activate(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'fund_sources',
      {'isActive': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== DELETE ====================

  /// Hard delete a fund source (use with caution)
  Future<int> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'fund_sources',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== BALANCE CALCULATIONS ====================

  /// Calculate current balance for a fund source
  /// Balance = initialBalance + income to this source - expenses from this source
  Future<int> getBalance(String sourceId) async {
    final db = await DatabaseHelper.instance.database;

    // Get initial balance
    final source = await getById(sourceId);
    if (source == null) return 0;

    int balance = source.initialBalance;

    // Add income where this source is the destination
    // (Income transactions with fundSourceId matching this source)
    final incomeResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE fundSourceId = ? AND isIncome = 1
    ''', [sourceId]);
    balance += (incomeResult.first['total'] as int?) ?? 0;

    // Add transfers TO this source
    final transferInResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE transferToSourceId = ? AND isTransfer = 1
    ''', [sourceId]);
    balance += (transferInResult.first['total'] as int?) ?? 0;

    // Subtract expenses FROM this source
    final expenseResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE fundSourceId = ? AND isIncome = 0 AND isTransfer = 0
    ''', [sourceId]);
    balance -= (expenseResult.first['total'] as int?) ?? 0;

    // Subtract transfers FROM this source
    final transferOutResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE fundSourceId = ? AND isTransfer = 1
    ''', [sourceId]);
    balance -= (transferOutResult.first['total'] as int?) ?? 0;

    return balance;
  }

  /// Get all fund sources with their current balances
  Future<List<Map<String, dynamic>>> getAllWithBalances() async {
    final sources = await getAll();
    final List<Map<String, dynamic>> result = [];

    for (final source in sources) {
      final balance = await getBalance(source.id);
      result.add({
        'source': source,
        'balance': balance,
      });
    }

    return result;
  }

  /// Get total balance across all sources
  Future<int> getTotalBalance() async {
    final sources = await getAll();
    int total = 0;
    for (final source in sources) {
      total += await getBalance(source.id);
    }
    return total;
  }

  /// Get transactions for a specific fund source
  Future<List<Map<String, dynamic>>> getTransactionsForSource(
    String sourceId, {
    int? limit,
  }) async {
    final db = await DatabaseHelper.instance.database;

    String query = '''
      SELECT * FROM transactions
      WHERE fundSourceId = ? OR transferToSourceId = ?
      ORDER BY dateTime DESC
    ''';

    if (limit != null) {
      query += ' LIMIT $limit';
    }

    final maps = await db.rawQuery(query, [sourceId, sourceId]);
    return maps;
  }

  /// Get income total for a fund source in a month
  Future<int> getIncomeForMonth(String sourceId, int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE fundSourceId = ? AND isIncome = 1
      AND dateTime >= ? AND dateTime < ?
    ''', [sourceId, startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

    return (result.first['total'] as int?) ?? 0;
  }

  /// Get expense total for a fund source in a month
  Future<int> getExpenseForMonth(String sourceId, int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE fundSourceId = ? AND isIncome = 0 AND isTransfer = 0
      AND dateTime >= ? AND dateTime < ?
    ''', [sourceId, startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

    return (result.first['total'] as int?) ?? 0;
  }
}
