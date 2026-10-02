import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:cash_flow_app/core/storage/database_helper.dart';
import 'package:cash_flow_app/core/storage/budget_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('v6 -> v7 migration keeps budgets and progress filters work', () async {
    final dbPath = join(await getDatabasesPath(), 'cash_flow.db');
    await deleteDatabase(dbPath);

    // Build a v6-shaped DB by hand
    final v6 = await openDatabase(dbPath, version: 6, onCreate: (db, v) async {
      await db.execute('''CREATE TABLE transactions (id TEXT PRIMARY KEY, title TEXT NOT NULL,
        amount INTEGER NOT NULL, category TEXT NOT NULL, dateTime TEXT NOT NULL, note TEXT,
        isIncome INTEGER NOT NULL DEFAULT 0, fundSource TEXT, fundSourceId TEXT,
        isTransfer INTEGER NOT NULL DEFAULT 0, transferToSourceId TEXT, receiptPath TEXT)''');
      await db.execute('''CREATE TABLE fund_sources (id TEXT PRIMARY KEY, name TEXT NOT NULL, icon TEXT,
        initialBalance INTEGER NOT NULL DEFAULT 0, createdAt TEXT NOT NULL, isActive INTEGER NOT NULL DEFAULT 1)''');
      await db.execute('''CREATE TABLE budgets (id TEXT PRIMARY KEY, category TEXT NOT NULL,
        amount INTEGER NOT NULL, month INTEGER NOT NULL, year INTEGER NOT NULL,
        createdAt TEXT NOT NULL, UNIQUE(category, month, year))''');
      await db.execute('CREATE INDEX idx_budgets_category_month_year ON budgets (category, month, year)');
    });
    final now = DateTime(2026, 9, 10).toIso8601String();
    await v6.insert('fund_sources', {'id': 'fs_gaji', 'name': 'Gaji', 'createdAt': now});
    await v6.insert('fund_sources', {'id': 'fs_bonus', 'name': 'Bonus', 'createdAt': now});
    await v6.insert('budgets', {'id': 'b1', 'category': 'Makan & minum', 'amount': 1000000,
      'month': 9, 'year': 2026, 'createdAt': now});
    Future<void> tx(String id, int amt, String cat, String fs, {int transfer = 0}) =>
        v6.insert('transactions', {'id': id, 'title': id, 'amount': amt, 'category': cat,
          'dateTime': now, 'fundSourceId': fs, 'isTransfer': transfer});
    await tx('t1', 100000, 'Makan & minum', 'fs_gaji');
    await tx('t2', 50000, 'Makan & minum', 'fs_bonus');
    await tx('t3', 30000, 'Transportasi', 'fs_gaji');
    await tx('t4', 999999, 'Transfer', 'fs_gaji', transfer: 1);
    await v6.close();

    final repo = BudgetRepository.instance;
    await DatabaseHelper.instance.database; // triggers upgrade to v7

    final migrated = await repo.getByMonth(2026, 9);
    expect(migrated.single.category, 'Makan & minum');
    expect(migrated.single.fundSourceId, isNull);

    await repo.create(category: 'Makan & minum', fundSourceId: 'fs_gaji', amount: 500000, year: 2026, month: 9);
    await repo.create(name: 'Total Gaji', fundSourceId: 'fs_gaji', amount: 2000000, year: 2026, month: 9);
    await repo.create(amount: 3000000, year: 2026, month: 9);

    final p = await repo.getBudgetProgress(2026, 9);
    expect(p.map((e) => e.spent).toList(), [150000, 100000, 130000, 180000]);
    expect(p[1].fundSourceName, 'Gaji');
    expect(p[2].budget.label, 'Total Gaji');
    expect(p[3].budget.label, 'Semua pengeluaran');

    expect(await repo.copyFromPreviousMonth(2026, 10), 4);
    expect((await repo.getByMonth(2026, 10)).length, 4);
  });
}

