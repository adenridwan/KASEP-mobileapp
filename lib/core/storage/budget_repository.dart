import '../storage/database_helper.dart';
import '../storage/transaction_repository.dart';
import '../../models/budget.dart';

class BudgetRepository {
  static final BudgetRepository instance = BudgetRepository._init();
  BudgetRepository._init();

  Future<Budget?> getByCategory(String category, int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'budgets',
      where: 'category = ? AND year = ? AND month = ?',
      whereArgs: [category, year, month],
    );

    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  Future<List<Budget>> getByMonth(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'budgets',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
      orderBy: 'category ASC',
    );
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  Future<Budget> createOrUpdate(String category, int amount, int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final existing = await getByCategory(category, year, month);
    final now = DateTime.now();

    if (existing != null) {
      final updated = existing.copyWith(amount: amount);
      await db.update(
        'budgets',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return updated;
    } else {
      final budget = Budget(
        id: 'bgt_${now.millisecondsSinceEpoch}',
        category: category,
        amount: amount,
        month: month,
        year: year,
        createdAt: now,
      );
      await db.insert('budgets', budget.toMap());
      return budget;
    }
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByCategory(String category, int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'budgets',
      where: 'category = ? AND year = ? AND month = ?',
      whereArgs: [category, year, month],
    );
  }

  /// Get budgets with spending progress for a month
  Future<List<BudgetProgress>> getBudgetProgress(int year, int month) async {
    final budgets = await getByMonth(year, month);
    final categoryTotals = await TransactionRepository.instance
        .getTotalByCategoryForMonth(year, month);

    return budgets.map((budget) {
      final spent = categoryTotals[budget.category] ?? 0;
      return BudgetProgress(budget: budget, spent: spent);
    }).toList();
  }

  /// Copy budgets from previous month
  Future<void> copyFromPreviousMonth(int year, int month) async {
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;

    final prevBudgets = await getByMonth(prevYear, prevMonth);
    for (final budget in prevBudgets) {
      await createOrUpdate(budget.category, budget.amount, year, month);
    }
  }

  /// Get total budget for a month
  Future<int> getTotalBudget(int year, int month) async {
    final budgets = await getByMonth(year, month);
    return budgets.fold<int>(0, (sum, b) => sum + b.amount);
  }
}
