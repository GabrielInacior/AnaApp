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
}
