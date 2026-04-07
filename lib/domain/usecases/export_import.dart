// lib/domain/usecases/export_import.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../entities/deck.dart';
import '../entities/flashcard.dart';
import '../repositories/deck_repository.dart';
import '../repositories/flashcard_repository.dart';
import '../../core/utils/sm2.dart';

class ExportImport {
  final DeckRepository _deckRepo;
  final FlashcardRepository _cardRepo;
  final Uuid _uuid;

  ExportImport({
    required DeckRepository deckRepo,
    required FlashcardRepository cardRepo,
    Uuid? uuid,
  })  : _deckRepo = deckRepo,
        _cardRepo = cardRepo,
        _uuid = uuid ?? const Uuid();

  Future<void> exportAll() async {
    final decks = await _deckRepo.getDecks();
    final List<Map<String, dynamic>> deckData = [];

    for (final deck in decks) {
      final cards = await _cardRepo.getCardsByDeck(deck.id);
      deckData.add({
        'id': deck.id,
        'name': deck.name,
        'description': deck.description,
        'createdAt': deck.createdAt.toIso8601String(),
        'cards': cards
            .map((c) => {
                  'id': c.id,
                  'front': c.front,
                  'back': c.back,
                  'createdAt': c.createdAt.toIso8601String(),
                  'easeFactor': c.easeFactor,
                  'interval': c.interval,
                  'repetitions': c.repetitions,
                  'dueDate': c.dueDate.toIso8601String(),
                })
            .toList(),
      });
    }

    final json = jsonEncode({'version': 1, 'decks': deckData});
    final bytes = Uint8List.fromList(utf8.encode(json));
    final now = DateTime.now();
    final fileName =
        'anaapp_backup_${now.year}${now.month}${now.day}.anaapp.json';

    if (kIsWeb) {
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], subject: 'AnaApp Backup');
  }

  Future<int> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.first.bytes == null) return 0;

    final content = utf8.decode(result.files.first.bytes!);
    final data = jsonDecode(content) as Map<String, dynamic>;

    if (data['version'] != 1 || data['decks'] == null) {
      throw const FormatException('Arquivo de backup inválido.');
    }

    int imported = 0;
    final now = DateTime.now();

    for (final deckData in data['decks'] as List) {
      final deck = Deck(
        id: _uuid.v4(),
        name: deckData['name'] as String,
        description: deckData['description'] as String?,
        createdAt:
            DateTime.tryParse(deckData['createdAt'] as String? ?? '') ?? now,
      );
      await _deckRepo.createDeck(deck);

      final cardsList = (deckData['cards'] as List?) ?? [];
      final cards = cardsList.map<Flashcard>((c) {
        return Flashcard(
          id: _uuid.v4(),
          deckId: deck.id,
          front: c['front'] as String,
          back: c['back'] as String,
          createdAt:
              DateTime.tryParse(c['createdAt'] as String? ?? '') ?? now,
          easeFactor:
              (c['easeFactor'] as num?)?.toDouble() ?? SM2.initialEaseFactor,
          interval: (c['interval'] as int?) ?? 0,
          repetitions: (c['repetitions'] as int?) ?? 0,
          dueDate: DateTime.tryParse(c['dueDate'] as String? ?? '') ?? now,
        );
      }).toList();

      await _cardRepo.addCards(cards);
      imported += cards.length;
    }

    return imported;
  }
}
