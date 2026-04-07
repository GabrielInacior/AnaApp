// lib/data/datasources/local/flashcard_dao.dart
import '../../../domain/entities/flashcard.dart';
import '../../models/flashcard_model.dart';
import 'database_helper.dart';

class FlashcardDAO {
  final DatabaseHelper _helper;
  FlashcardDAO(this._helper);

  Future<List<Flashcard>> getByDeck(String deckId) async {
    final db = await _helper.database;
    final maps = await db.query('flashcards',
        where: 'deck_id = ?', whereArgs: [deckId], orderBy: 'created_at ASC');
    return maps.map((m) => FlashcardModel.fromMap(m).toEntity()).toList();
  }

  Future<List<Flashcard>> getDueByDeck(String deckId, DateTime now) async {
    final db = await _helper.database;
    final maps = await db.query('flashcards',
        where: 'deck_id = ? AND due_date <= ?',
        whereArgs: [deckId, now.toIso8601String()],
        orderBy: 'due_date ASC');
    return maps.map((m) => FlashcardModel.fromMap(m).toEntity()).toList();
  }

  /// Get new cards by deck (queue = 0), limited
  Future<List<Flashcard>> getNewByDeck(String deckId, int limit) async {
    final db = await _helper.database;
    final maps = await db.query('flashcards',
        where: 'deck_id = ? AND queue = 0',
        whereArgs: [deckId],
        orderBy: 'created_at ASC',
        limit: limit);
    return maps.map((m) => FlashcardModel.fromMap(m).toEntity()).toList();
  }

  /// Get learning/relearning cards by deck (queue = 1 or 3)
  Future<List<Flashcard>> getLearningByDeck(String deckId) async {
    final db = await _helper.database;
    final maps = await db.query('flashcards',
        where: 'deck_id = ? AND (queue = 1 OR queue = 3)',
        whereArgs: [deckId],
        orderBy: 'due_date ASC');
    return maps.map((m) => FlashcardModel.fromMap(m).toEntity()).toList();
  }

  /// Get review cards due by deck (queue = 2, due <= now), limited
  Future<List<Flashcard>> getReviewByDeck(
      String deckId, DateTime now, int limit) async {
    final db = await _helper.database;
    final maps = await db.query('flashcards',
        where: 'deck_id = ? AND queue = 2 AND due_date <= ?',
        whereArgs: [deckId, now.toIso8601String()],
        orderBy: 'due_date ASC',
        limit: limit);
    return maps.map((m) => FlashcardModel.fromMap(m).toEntity()).toList();
  }

  Future<List<Flashcard>> getAllDue(DateTime now) async {
    final db = await _helper.database;
    final maps = await db.query('flashcards',
        where: 'due_date <= ?',
        whereArgs: [now.toIso8601String()],
        orderBy: 'due_date ASC');
    return maps.map((m) => FlashcardModel.fromMap(m).toEntity()).toList();
  }

  Future<void> insert(Flashcard card) async {
    final db = await _helper.database;
    await db.insert('flashcards', FlashcardModel.fromEntity(card).toMap());
  }

  Future<void> insertAll(List<Flashcard> cards) async {
    final db = await _helper.database;
    final batch = db.batch();
    for (final card in cards) {
      batch.insert('flashcards', FlashcardModel.fromEntity(card).toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> update(Flashcard card) async {
    final db = await _helper.database;
    await db.update('flashcards', FlashcardModel.fromEntity(card).toMap(),
        where: 'id = ?', whereArgs: [card.id]);
  }

  Future<void> delete(String id) async {
    final db = await _helper.database;
    await db.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countByDeck(String deckId) async {
    final db = await _helper.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM flashcards WHERE deck_id = ?', [deckId]);
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> countDueByDeck(String deckId, DateTime now) async {
    final db = await _helper.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM flashcards WHERE deck_id = ? AND due_date <= ?',
        [deckId, now.toIso8601String()]);
    return (result.first['count'] as int?) ?? 0;
  }

  /// Returns mastery distribution using queue-based classification
  Future<Map<String, int>> getMasteryDistribution() async {
    final db = await _helper.database;
    final result = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN queue = 0 THEN 1 ELSE 0 END) as new_count,
        SUM(CASE WHEN queue = 1 OR queue = 3 THEN 1 ELSE 0 END) as learning,
        SUM(CASE WHEN queue = 2 AND interval_days <= 21 THEN 1 ELSE 0 END) as young,
        SUM(CASE WHEN queue = 2 AND interval_days > 21 THEN 1 ELSE 0 END) as mature
      FROM flashcards
    ''');
    final row = result.first;
    return {
      'new': (row['new_count'] as int?) ?? 0,
      'learning': (row['learning'] as int?) ?? 0,
      'young': (row['young'] as int?) ?? 0,
      'mature': (row['mature'] as int?) ?? 0,
    };
  }

  /// Returns cards due per each of next N days
  Future<List<MapEntry<DateTime, int>>> getDueForecast(int days) async {
    final db = await _helper.database;
    final now = DateTime.now();
    final results = <MapEntry<DateTime, int>>[];
    for (int i = 0; i < days; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      final dayEnd = DateTime(now.year, now.month, now.day + i, 23, 59, 59);
      final count = await db.rawQuery(
        'SELECT COUNT(*) as c FROM flashcards WHERE due_date <= ?',
        [dayEnd.toIso8601String()],
      );
      results.add(MapEntry(day, (count.first['c'] as int?) ?? 0));
    }
    return results;
  }

  /// Count reviews done today for a deck
  Future<int> countReviewsDoneToday(String deckId) async {
    final db = await _helper.database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM review_logs WHERE deck_id = ? AND reviewed_at >= ?',
      [deckId, startOfDay.toIso8601String()],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  /// Count new cards studied today for a deck
  Future<int> countNewCardsStudiedToday(String deckId) async {
    final db = await _helper.database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    // New cards that were studied = cards that were queue=0 but got a review log today
    // We track this by looking at review_logs for cards that are no longer new
    final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT r.card_id) as c
      FROM review_logs r
      INNER JOIN flashcards f ON r.card_id = f.id
      WHERE f.deck_id = ? AND r.reviewed_at >= ?
      AND f.queue != 0
      AND NOT EXISTS (
        SELECT 1 FROM review_logs r2
        WHERE r2.card_id = r.card_id AND r2.reviewed_at < ?
      )
    ''', [deckId, startOfDay.toIso8601String(), startOfDay.toIso8601String()]);
    return (result.first['c'] as int?) ?? 0;
  }
}
