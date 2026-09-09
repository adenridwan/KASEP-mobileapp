import 'package:sqflite/sqflite.dart' hide Transaction;
import '../../models/transaction.dart';
import 'database_helper.dart';

class TransactionRepository {
  static final TransactionRepository instance = TransactionRepository._init();
  TransactionRepository._init();

  // ==================== CREATE ====================

  /// Insert a new transaction into the database
  Future<void> create(Transaction transaction) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple transactions at once
  Future<void> createBatch(List<Transaction> transactions) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final transaction in transactions) {
      batch.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // ==================== READ ====================

  /// Get a single transaction by ID
  Future<Transaction?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Transaction.fromMap(maps.first);
  }

  /// Get all transactions ordered by date (newest first)
  Future<List<Transaction>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'transactions',
      orderBy: 'dateTime DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Get transactions for a specific date
  Future<List<Transaction>> getByDate(DateTime date) async {
    final db = await DatabaseHelper.instance.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'transactions',
      where: 'dateTime >= ? AND dateTime < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'dateTime DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Get transactions for a specific month
  Future<List<Transaction>> getByMonth(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final maps = await db.query(
      'transactions',
      where: 'dateTime >= ? AND dateTime < ?',
      whereArgs: [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
      orderBy: 'dateTime DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Get transactions within a date range
  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'transactions',
      where: 'dateTime >= ? AND dateTime < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'dateTime DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Get transactions by category
  Future<List<Transaction>> getByCategory(String category) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'dateTime DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Get only income transactions
  Future<List<Transaction>> getIncomes() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'transactions',
      where: 'isIncome = ?',
      whereArgs: [1],
      orderBy: 'dateTime DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Get only expense transactions
  Future<List<Transaction>> getExpenses() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'transactions',
      where: 'isIncome = ?',
      whereArgs: [0],
      orderBy: 'dateTime DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Get transactions filtered by type (income/expense) for a month
  Future<List<Transaction>> getByMonthAndType({
    required int year,
    required int month,
    required bool isIncome,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final maps = await db.query(
      'transactions',
      where: 'dateTime >= ? AND dateTime < ? AND isIncome = ?',
      whereArgs: [
        startOfMonth.toIso8601String(),
        endOfMonth.toIso8601String(),
        isIncome ? 1 : 0,
      ],
      orderBy: 'dateTime DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  // ==================== UPDATE ====================

  /// Update an existing transaction
  Future<int> update(Transaction transaction) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // ==================== DELETE ====================

  /// Delete a transaction by ID
  Future<int> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all transactions
  Future<int> deleteAll() async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('transactions');
  }

  /// Delete transactions by date range
  Future<int> deleteByDateRange(DateTime start, DateTime end) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'transactions',
      where: 'dateTime >= ? AND dateTime < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
  }

  // ==================== AGGREGATIONS ====================

  /// Get total income for a month
  Future<int> getTotalIncomeByMonth(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE dateTime >= ? AND dateTime < ? AND isIncome = 1
    ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

    return (result.first['total'] as int?) ?? 0;
  }

  /// Get total expenses for a month
  Future<int> getTotalExpensesByMonth(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE dateTime >= ? AND dateTime < ? AND isIncome = 0
    ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

    return (result.first['total'] as int?) ?? 0;
  }

  /// Get total by category for a month
  Future<Map<String, int>> getTotalByCategoryForMonth(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM transactions
      WHERE dateTime >= ? AND dateTime < ? AND isIncome = 0
      GROUP BY category
      ORDER BY total DESC
    ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

    return Map.fromEntries(
      result.map((row) => MapEntry(
        row['category'] as String,
        (row['total'] as int?) ?? 0,
      )),
    );
  }

  /// Get transaction count
  Future<int> getCount() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM transactions');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get transaction count for a month
  Future<int> getCountByMonth(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM transactions
      WHERE dateTime >= ? AND dateTime < ?
    ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

    return (result.first['count'] as int?) ?? 0;
  }

  /// Get category summaries with totals and counts for a month (expenses only)
  Future<List<Map<String, dynamic>>> getCategorySummariesForMonth(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final result = await db.rawQuery('''
      SELECT
        category,
        SUM(amount) as total,
        COUNT(*) as count
      FROM transactions
      WHERE dateTime >= ? AND dateTime < ? AND isIncome = 0
      GROUP BY category
      ORDER BY total DESC
    ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

    return result.map((row) => {
      'category': row['category'] as String,
      'total': (row['total'] as int?) ?? 0,
      'count': (row['count'] as int?) ?? 0,
    }).toList();
  }

  /// Get daily totals for a month (for charts)
  Future<Map<int, int>> getDailyTotalsForMonth(int year, int month, {bool isIncome = false}) async {
    final db = await DatabaseHelper.instance.database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final result = await db.rawQuery('''
      SELECT
        CAST(substr(dateTime, 9, 2) AS INTEGER) as day,
        SUM(amount) as total
      FROM transactions
      WHERE dateTime >= ? AND dateTime < ? AND isIncome = ?
      GROUP BY day
      ORDER BY day ASC
    ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String(), isIncome ? 1 : 0]);

    return Map.fromEntries(
      result.map((row) => MapEntry(
        row['day'] as int,
        (row['total'] as int?) ?? 0,
      )),
    );
  }

  /// Get running daily balance for a month (cumulative income - expense per day)
  Future<List<Map<String, dynamic>>> getDailyRunningBalanceForMonth(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Get all transactions for the month
    final transactions = await db.rawQuery('''
      SELECT
        CAST(substr(dateTime, 9, 2) AS INTEGER) as day,
        amount,
        isIncome
      FROM transactions
      WHERE dateTime >= ? AND dateTime < ?
      ORDER BY day ASC
    ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

    // Calculate daily net and running balance
    final Map<int, int> dailyNet = {};
    for (final tx in transactions) {
      final day = tx['day'] as int;
      final amount = tx['amount'] as int;
      final isIncome = tx['isIncome'] == 1;
      dailyNet[day] = (dailyNet[day] ?? 0) + (isIncome ? amount : -amount);
    }

    // Build running balance
    final List<Map<String, dynamic>> result = [];
    int runningBalance = 0;
    for (int day = 1; day <= daysInMonth; day++) {
      runningBalance += dailyNet[day] ?? 0;
      result.add({'day': day, 'balance': runningBalance});
    }

    return result;
  }

  /// Get weekly totals for a month
  Future<List<Map<String, dynamic>>> getWeeklyTotalsForMonth(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Define weeks (1-7, 8-14, 15-21, 22-end)
    final weeks = [
      {'start': 1, 'end': 7},
      {'start': 8, 'end': 14},
      {'start': 15, 'end': 21},
      {'start': 22, 'end': daysInMonth},
    ];

    final List<Map<String, dynamic>> result = [];

    for (final week in weeks) {
      final weekStart = DateTime(year, month, week['start']!);
      final weekEnd = DateTime(year, month, week['end']!, 23, 59, 59);

      final incomeResult = await db.rawQuery('''
        SELECT COALESCE(SUM(amount), 0) as total
        FROM transactions
        WHERE dateTime >= ? AND dateTime <= ? AND isIncome = 1
      ''', [weekStart.toIso8601String(), weekEnd.toIso8601String()]);

      final expenseResult = await db.rawQuery('''
        SELECT COALESCE(SUM(amount), 0) as total
        FROM transactions
        WHERE dateTime >= ? AND dateTime <= ? AND isIncome = 0
      ''', [weekStart.toIso8601String(), weekEnd.toIso8601String()]);

      result.add({
        'startDay': week['start'],
        'endDay': week['end'],
        'income': (incomeResult.first['total'] as int?) ?? 0,
        'expense': (expenseResult.first['total'] as int?) ?? 0,
      });
    }

    return result;
  }

  /// Get totals by day of week (0=Sunday, 1=Monday, etc.)
  Future<Map<int, int>> getTotalsByWeekdayForMonth(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final endOfMonth = DateTime(year, month + 1, 1);
    final startOfMonth = DateTime(year, month, 1);

    final transactions = await db.query(
      'transactions',
      where: 'dateTime >= ? AND dateTime < ? AND isIncome = 0',
      whereArgs: [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );

    final Map<int, int> weekdayTotals = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};

    for (final tx in transactions) {
      final dateTime = DateTime.parse(tx['dateTime'] as String);
      final weekday = dateTime.weekday % 7; // Convert to 0=Sunday format
      weekdayTotals[weekday] = (weekdayTotals[weekday] ?? 0) + (tx['amount'] as int);
    }

    return weekdayTotals;
  }

  /// Get top N expenses for a month
  Future<List<Transaction>> getTopExpensesForMonth(int year, int month, {int limit = 5}) async {
    final db = await DatabaseHelper.instance.database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final maps = await db.query(
      'transactions',
      where: 'dateTime >= ? AND dateTime < ? AND isIncome = 0',
      whereArgs: [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
      orderBy: 'amount DESC',
      limit: limit,
    );

    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Get category comparison between two months
  Future<List<Map<String, dynamic>>> getCategoryComparisonBetweenMonths(
    int year1, int month1,
    int year2, int month2,
  ) async {
    final currentTotals = await getTotalByCategoryForMonth(year1, month1);
    final prevTotals = await getTotalByCategoryForMonth(year2, month2);

    // Get all unique categories
    final allCategories = {...currentTotals.keys, ...prevTotals.keys};

    final List<Map<String, dynamic>> result = [];
    for (final category in allCategories) {
      final current = currentTotals[category] ?? 0;
      final prev = prevTotals[category] ?? 0;
      final double change = prev > 0 ? ((current - prev) / prev * 100.0) : (current > 0 ? 100.0 : 0.0);

      result.add({
        'category': category,
        'current': current,
        'previous': prev,
        'changePercent': change,
      });
    }

    // Sort by current amount descending
    result.sort((a, b) => (b['current'] as int).compareTo(a['current'] as int));

    return result;
  }
}
