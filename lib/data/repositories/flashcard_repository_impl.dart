// lib/data/repositories/flashcard_repository_impl.dart
import '../../domain/entities/flashcard.dart';
import '../../domain/repositories/flashcard_repository.dart';
import '../datasources/local/flashcard_dao.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final FlashcardDAO _dao;
  FlashcardRepositoryImpl(this._dao);

  @override
  Future<List<Flashcard>> getCardsByDeck(String deckId) => _dao.getByDeck(deckId);

  @override
  Future<List<Flashcard>> getDueCards(String deckId, DateTime now) =>
      _dao.getDueByDeck(deckId, now);

  @override
  Future<List<Flashcard>> getAllDueCards(DateTime now) => _dao.getAllDue(now);

  @override
  Future<void> addCard(Flashcard card) => _dao.insert(card);

  @override
  Future<void> addCards(List<Flashcard> cards) => _dao.insertAll(cards);

  @override
  Future<void> updateCard(Flashcard card) => _dao.update(card);

  @override
  Future<void> deleteCard(String id) => _dao.delete(id);

  @override
  Future<int> countCardsByDeck(String deckId) => _dao.countByDeck(deckId);

  @override
  Future<int> countDueCardsByDeck(String deckId, DateTime now) =>
      _dao.countDueByDeck(deckId, now);
}
