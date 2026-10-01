import '../storage/database_helper.dart';
import '../../models/monthly_note.dart';

class MonthlyNoteRepository {
  static final MonthlyNoteRepository instance = MonthlyNoteRepository._init();
  MonthlyNoteRepository._init();

  Future<MonthlyNote?> getByMonth(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'monthly_notes',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );

    if (maps.isEmpty) return null;
    return MonthlyNote.fromMap(maps.first);
  }

  Future<List<MonthlyNote>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'monthly_notes',
      orderBy: 'year DESC, month DESC',
    );
    return maps.map((map) => MonthlyNote.fromMap(map)).toList();
  }

  Future<List<MonthlyNote>> getByYear(int year) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'monthly_notes',
      where: 'year = ?',
      whereArgs: [year],
      orderBy: 'month DESC',
    );
    return maps.map((map) => MonthlyNote.fromMap(map)).toList();
  }

  Future<MonthlyNote> createOrUpdate(int year, int month, String content) async {
    final db = await DatabaseHelper.instance.database;
    final existing = await getByMonth(year, month);
    final now = DateTime.now();

    if (existing != null) {
      // Update existing note
      final updated = existing.copyWith(
        content: content,
        updatedAt: now,
      );
      await db.update(
        'monthly_notes',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return updated;
    } else {
      // Create new note
      final note = MonthlyNote(
        id: 'mn_${now.millisecondsSinceEpoch}',
        year: year,
        month: month,
        content: content,
        createdAt: now,
        updatedAt: now,
      );
      await db.insert('monthly_notes', note.toMap());
      return note;
    }
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'monthly_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteByMonth(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'monthly_notes',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );
  }

  /// Get months that have notes (for navigation)
  Future<List<Map<String, int>>> getMonthsWithNotes() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.rawQuery('''
      SELECT year, month FROM monthly_notes
      WHERE content IS NOT NULL AND content != ''
      ORDER BY year DESC, month DESC
    ''');
    return maps.map((m) => {
      'year': m['year'] as int,
      'month': m['month'] as int,
    }).toList();
  }
}
