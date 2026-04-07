// lib/data/datasources/local/deck_dao.dart
import '../../../domain/entities/deck.dart';
import '../../models/deck_model.dart';
import 'database_helper.dart';

class DeckDAO {
  final DatabaseHelper _helper;
  DeckDAO(this._helper);

  Future<List<Deck>> getAll() async {
    final db = await _helper.database;
    final maps = await db.query('decks',
        orderBy: 'is_favorite DESC, created_at DESC');
    return maps.map((m) => DeckModel.fromMap(m).toEntity()).toList();
  }

  Future<Deck?> getById(String id) async {
    final db = await _helper.database;
    final maps = await db.query('decks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return DeckModel.fromMap(maps.first).toEntity();
  }

  Future<void> insert(Deck deck) async {
    final db = await _helper.database;
    await db.insert('decks', DeckModel.fromEntity(deck).toMap());
  }

  Future<void> update(Deck deck) async {
    final db = await _helper.database;
    await db.update('decks', DeckModel.fromEntity(deck).toMap(),
        where: 'id = ?', whereArgs: [deck.id]);
  }

  Future<void> delete(String id) async {
    final db = await _helper.database;
    await db.delete('decks', where: 'id = ?', whereArgs: [id]);
  }
}
