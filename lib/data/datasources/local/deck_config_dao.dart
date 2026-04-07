// lib/data/datasources/local/deck_config_dao.dart
import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/deck_config.dart';
import '../../models/deck_config_model.dart';
import 'database_helper.dart';

class DeckConfigDAO {
  final DatabaseHelper _helper;
  DeckConfigDAO(this._helper);

  Future<DeckConfig> getConfig(String deckId) async {
    final db = await _helper.database;
    final maps = await db.query(
      'deck_config',
      where: 'deck_id = ?',
      whereArgs: [deckId],
    );
    if (maps.isEmpty) {
      return DeckConfig(deckId: deckId);
    }
    return DeckConfigModel.fromMap(maps.first).toEntity();
  }

  Future<void> upsert(DeckConfig config) async {
    final db = await _helper.database;
    await db.insert(
      'deck_config',
      DeckConfigModel.fromEntity(config).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
