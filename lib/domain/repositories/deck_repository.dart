// lib/domain/repositories/deck_repository.dart
import '../entities/deck.dart';

abstract interface class DeckRepository {
  Future<List<Deck>> getDecks();
  Future<Deck?> getDeckById(String id);
  Future<void> createDeck(Deck deck);
  Future<void> updateDeck(Deck deck);
  Future<void> deleteDeck(String id);
}
