// lib/data/datasources/local/tag_dao.dart
import 'package:sqflite/sqflite.dart';
import '../../datasources/local/database_helper.dart';
import '../../../core/theme/app_colors.dart';

class TagRecord {
  final String name;
  final int colorValue;
  final bool isPredefined;

  const TagRecord({
    required this.name,
    required this.colorValue,
    this.isPredefined = false,
  });
}

class TagDAO {
  final DatabaseHelper _dbHelper;
  TagDAO(this._dbHelper);

  Future<void> seedPredefinedTags() async {
    final db = await _dbHelper.database;
    final existing = await db.query('tags');
    final existingNames = existing.map((r) => r['name'] as String).toSet();

    final batch = db.batch();
    for (final tag in AppColors.predefinedTags) {
      if (existingNames.contains(tag)) continue;
      final color = AppColors.predefinedTagColors[tag] ?? 0xFF90A4AE;
      batch.insert('tags', {
        'name': tag,
        'color_value': color,
        'is_predefined': 1,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<TagRecord>> getAllTags() async {
    final db = await _dbHelper.database;
    final rows = await db.query('tags', orderBy: 'is_predefined DESC, name ASC');
    return rows
        .map((r) => TagRecord(
              name: r['name'] as String,
              colorValue: r['color_value'] as int,
              isPredefined: (r['is_predefined'] as int) == 1,
            ))
        .toList();
  }

  Future<void> insertTag(String name, int colorValue,
      {bool isPredefined = false}) async {
    final db = await _dbHelper.database;
    await db.insert(
      'tags',
      {
        'name': name,
        'color_value': colorValue,
        'is_predefined': isPredefined ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> deleteTag(String name) async {
    final db = await _dbHelper.database;
    await db.delete('tags', where: 'name = ?', whereArgs: [name]);
  }

  Future<int> countCardsWithTag(String tag) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM flashcards WHERE tag = ?', [tag]);
    return result.first['cnt'] as int;
  }

  Future<void> clearTagFromCards(String tag) async {
    final db = await _dbHelper.database;
    await db.update('flashcards', {'tag': null},
        where: 'tag = ?', whereArgs: [tag]);
  }
}
