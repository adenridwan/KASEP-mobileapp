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
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount INTEGER NOT NULL,
        category TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        note TEXT,
        isIncome INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create index for faster date-based queries
    await db.execute('''
      CREATE INDEX idx_transactions_date ON transactions (dateTime)
    ''');

    // Create index for category-based queries
    await db.execute('''
      CREATE INDEX idx_transactions_category ON transactions (category)
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle future database migrations here
    // if (oldVersion < 2) { ... }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
