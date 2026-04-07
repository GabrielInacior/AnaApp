// lib/data/repositories/deck_repository_impl.dart
import '../../domain/entities/deck.dart';
import '../../domain/repositories/deck_repository.dart';
import '../datasources/local/deck_dao.dart';
import '../datasources/local/flashcard_dao.dart';

class DeckRepositoryImpl implements DeckRepository {
  final DeckDAO _deckDAO;
  final FlashcardDAO _cardDAO;

  DeckRepositoryImpl(this._deckDAO, this._cardDAO);

  @override
  Future<List<Deck>> getDecks() async {
    final decks = await _deckDAO.getAll();
    final now = DateTime.now();
    final enriched = <Deck>[];
    for (final deck in decks) {
      final total = await _cardDAO.countByDeck(deck.id);
      final due = await _cardDAO.countDueByDeck(deck.id, now);
      enriched.add(deck.copyWith(totalCards: total, dueCards: due));
    }
    return enriched;
  }

  @override
  Future<Deck?> getDeckById(String id) => _deckDAO.getById(id);

  @override
  Future<void> createDeck(Deck deck) => _deckDAO.insert(deck);

  @override
  Future<void> updateDeck(Deck deck) => _deckDAO.update(deck);

  @override
  Future<void> deleteDeck(String id) => _deckDAO.delete(id);
}
