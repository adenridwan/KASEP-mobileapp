import '../../models/income_category.dart';
import 'database_helper.dart';

class IncomeCategoryRepository {
  static final IncomeCategoryRepository instance = IncomeCategoryRepository._init();
  IncomeCategoryRepository._init();

  Future<void> create(IncomeCategory category) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('income_categories', category.toMap());
  }

  Future<List<IncomeCategory>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'income_categories',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'createdAt ASC',
    );
    return maps.map((map) => IncomeCategory.fromMap(map)).toList();
  }

  Future<List<IncomeCategory>> getAllIncludingInactive() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'income_categories',
      orderBy: 'createdAt ASC',
    );
    return maps.map((map) => IncomeCategory.fromMap(map)).toList();
  }

  Future<IncomeCategory?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'income_categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return IncomeCategory.fromMap(maps.first);
  }

  Future<IncomeCategory?> getByName(String name) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'income_categories',
      where: 'name = ? AND isActive = ?',
      whereArgs: [name, 1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return IncomeCategory.fromMap(maps.first);
  }

  Future<void> update(IncomeCategory category) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'income_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deactivate(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'income_categories',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> activate(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'income_categories',
      {'isActive': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'income_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String> generateId() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM income_categories');
    final count = (result.first['count'] as int) + 1;
    return 'ic_$count';
  }
}
