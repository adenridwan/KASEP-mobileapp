import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cash_flow.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 4, // Upgraded for income_categories table
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount INTEGER NOT NULL,
        category TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        note TEXT,
        isIncome INTEGER NOT NULL DEFAULT 0,
        fundSource TEXT,
        fundSourceId TEXT,
        isTransfer INTEGER NOT NULL DEFAULT 0,
        transferToSourceId TEXT
      )
    ''');

    // Fund sources table
    await db.execute('''
      CREATE TABLE fund_sources (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT,
        initialBalance INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Income categories table
    await db.execute('''
      CREATE TABLE income_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create indexes for transactions
    await db.execute('''
      CREATE INDEX idx_transactions_date ON transactions (dateTime)
    ''');
    await db.execute('''
      CREATE INDEX idx_transactions_category ON transactions (category)
    ''');
    await db.execute('''
      CREATE INDEX idx_transactions_fund_source ON transactions (fundSource)
    ''');
    await db.execute('''
      CREATE INDEX idx_transactions_fund_source_id ON transactions (fundSourceId)
    ''');

    // Create index for fund sources
    await db.execute('''
      CREATE INDEX idx_fund_sources_name ON fund_sources (name)
    ''');

    // Create index for income categories
    await db.execute('''
      CREATE INDEX idx_income_categories_name ON income_categories (name)
    ''');

    // Insert default fund sources
    await _insertDefaultFundSources(db);

    // Insert default income categories
    await _insertDefaultIncomeCategories(db);
  }

  Future<void> _insertDefaultFundSources(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaults = ['Gaji', 'Freelance', 'Bonus', 'Tabungan', 'Lainnya'];

    for (int i = 0; i < defaults.length; i++) {
      await db.insert('fund_sources', {
        'id': 'fs_${i + 1}',
        'name': defaults[i],
        'icon': null,
        'initialBalance': 0,
        'createdAt': now,
        'isActive': 1,
      });
    }
  }

  Future<void> _insertDefaultIncomeCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaults = ['Gaji', 'Lepasan masuk', 'Bonus', 'Penjualan', 'Lainnya'];

    for (int i = 0; i < defaults.length; i++) {
      await db.insert('income_categories', {
        'id': 'ic_${i + 1}',
        'name': defaults[i],
        'createdAt': now,
        'isActive': 1,
      });
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migration v1 -> v2: Add fundSource column
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN fundSource TEXT');
      await db.execute('''
        CREATE INDEX idx_transactions_fund_source ON transactions (fundSource)
      ''');
    }

    // Migration v2 -> v3: Add fund_sources table and transfer columns
    if (oldVersion < 3) {
      // Add new columns to transactions
      await db.execute('ALTER TABLE transactions ADD COLUMN fundSourceId TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN isTransfer INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE transactions ADD COLUMN transferToSourceId TEXT');
      await db.execute('''
        CREATE INDEX idx_transactions_fund_source_id ON transactions (fundSourceId)
      ''');

      // Create fund_sources table
      await db.execute('''
        CREATE TABLE fund_sources (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT,
          initialBalance INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL,
          isActive INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.execute('''
        CREATE INDEX idx_fund_sources_name ON fund_sources (name)
      ''');

      // Insert default fund sources
      await _insertDefaultFundSources(db);

      // Migrate existing fundSource names to fundSourceId
      await _migrateFundSourceNamesToIds(db);
    }

    // Migration v3 -> v4: Add income_categories table
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE income_categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          isActive INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.execute('''
        CREATE INDEX idx_income_categories_name ON income_categories (name)
      ''');
      await _insertDefaultIncomeCategories(db);
    }
  }

  Future<void> _migrateFundSourceNamesToIds(Database db) async {
    // Get all fund sources
    final sources = await db.query('fund_sources');
    final nameToId = <String, String>{};
    for (final source in sources) {
      nameToId[source['name'] as String] = source['id'] as String;
    }

    // Update transactions with fundSourceId based on fundSource name
    final transactions = await db.query('transactions', where: 'fundSource IS NOT NULL');
    for (final tx in transactions) {
      final sourceName = tx['fundSource'] as String?;
      if (sourceName != null && nameToId.containsKey(sourceName)) {
        await db.update(
          'transactions',
          {'fundSourceId': nameToId[sourceName]},
          where: 'id = ?',
          whereArgs: [tx['id']],
        );
      }
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
