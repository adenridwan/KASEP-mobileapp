import '../storage/database_helper.dart';
import '../storage/fund_source_repository.dart';
import '../../models/budget.dart';

class BudgetRepository {
  static final BudgetRepository instance = BudgetRepository._init();
  BudgetRepository._init();

  Future<List<Budget>> getByMonth(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'budgets',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
      orderBy: 'createdAt ASC',
    );
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  Future<Budget> create({
    String? name,
    String? category,
    String? fundSourceId,
    required int amount,
    required int year,
    required int month,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final budget = Budget(
      id: 'bgt_${now.microsecondsSinceEpoch}',
      name: name,
      category: category,
      fundSourceId: fundSourceId,
      amount: amount,
      month: month,
      year: year,
      createdAt: now,
    );
    await db.insert('budgets', budget.toMap());
    return budget;
  }

  Future<void> update(Budget budget) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  /// Expense total for a month, optionally limited to a category and/or fund source
  Future<int> getSpent(
    int year,
    int month, {
    String? category,
    String? fundSourceId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    var where = 'isIncome = 0 AND isTransfer = 0 AND dateTime >= ? AND dateTime < ?';
    final args = <Object>[
      startOfMonth.toIso8601String(),
      endOfMonth.toIso8601String(),
    ];
    if (category != null) {
      where += ' AND category = ?';
      args.add(category);
    }
    if (fundSourceId != null) {
      where += ' AND fundSourceId = ?';
      args.add(fundSourceId);
    }

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE $where',
      args,
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Get budgets with spending progress for a month
  Future<List<BudgetProgress>> getBudgetProgress(int year, int month) async {
    final budgets = await getByMonth(year, month);
    if (budgets.isEmpty) return [];

    final sources = await FundSourceRepository.instance.getAllIncludingInactive();
    final sourceNames = {for (final s in sources) s.id: s.name};

    final result = <BudgetProgress>[];
    for (final budget in budgets) {
      final spent = await getSpent(
        year,
        month,
        category: budget.category,
        fundSourceId: budget.fundSourceId,
      );
      result.add(BudgetProgress(
        budget: budget,
        spent: spent,
        fundSourceName: sourceNames[budget.fundSourceId],
      ));
    }
    return result;
  }

  /// Copy budgets from previous month; returns how many were copied
  Future<int> copyFromPreviousMonth(int year, int month) async {
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;

    final prevBudgets = await getByMonth(prevYear, prevMonth);
    for (final budget in prevBudgets) {
      await create(
        name: budget.name,
        category: budget.category,
        fundSourceId: budget.fundSourceId,
        amount: budget.amount,
        year: year,
        month: month,
      );
    }
    return prevBudgets.length;
  }

  /// Get total budget for a month
  Future<int> getTotalBudget(int year, int month) async {
    final budgets = await getByMonth(year, month);
    return budgets.fold<int>(0, (sum, b) => sum + b.amount);
  }
}
