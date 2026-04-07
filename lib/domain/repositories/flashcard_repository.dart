// lib/domain/repositories/flashcard_repository.dart
import '../entities/flashcard.dart';

abstract interface class FlashcardRepository {
  Future<List<Flashcard>> getCardsByDeck(String deckId);
  Future<List<Flashcard>> getDueCards(String deckId, DateTime now);
  Future<List<Flashcard>> getAllDueCards(DateTime now);
  Future<void> addCard(Flashcard card);
  Future<void> addCards(List<Flashcard> cards);
  Future<void> updateCard(Flashcard card);
  Future<void> deleteCard(String id);
  Future<int> countCardsByDeck(String deckId);
  Future<int> countDueCardsByDeck(String deckId, DateTime now);
  Future<Map<String, int>> getMasteryDistribution();
  Future<List<MapEntry<DateTime, int>>> getDueForecast(int days);
}
