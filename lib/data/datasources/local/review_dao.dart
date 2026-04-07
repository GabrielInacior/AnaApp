// lib/data/datasources/local/review_dao.dart
import '../../../domain/entities/review_log.dart';
import '../../models/review_log_model.dart';
import 'database_helper.dart';

class ReviewDAO {
  final DatabaseHelper _helper;
  ReviewDAO(this._helper);

  Future<void> insert(ReviewLog log) async {
    final db = await _helper.database;
    await db.insert('review_logs', ReviewLogModel.fromEntity(log).toMap());
  }

  Future<List<ReviewLog>> getLogs({DateTime? from, DateTime? to}) async {
    final db = await _helper.database;
    String? where;
    List<dynamic>? whereArgs;

    if (from != null && to != null) {
      where = 'reviewed_at >= ? AND reviewed_at <= ?';
      whereArgs = [from.toIso8601String(), to.toIso8601String()];
    } else if (from != null) {
      where = 'reviewed_at >= ?';
      whereArgs = [from.toIso8601String()];
    }

    final maps = await db.query('review_logs',
        where: where, whereArgs: whereArgs, orderBy: 'reviewed_at DESC');
    return maps.map((m) => ReviewLogModel.fromMap(m).toEntity()).toList();
  }

  Future<List<ReviewLog>> getByDeck(String deckId) async {
    final db = await _helper.database;
    final maps = await db.query('review_logs',
        where: 'deck_id = ?', whereArgs: [deckId]);
    return maps.map((m) => ReviewLogModel.fromMap(m).toEntity()).toList();
  }

  Future<int> countToday() async {
    final db = await _helper.database;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).toIso8601String();
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM review_logs WHERE reviewed_at >= ? AND reviewed_at <= ?',
        [start, end]);
    return (result.first['count'] as int?) ?? 0;
  }
}
