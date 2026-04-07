// lib/domain/usecases/deck/delete_deck.dart
import '../../repositories/deck_repository.dart';

class DeleteDeck {
  final DeckRepository _repository;
  DeleteDeck(this._repository);

  Future<void> execute(String deckId) => _repository.deleteDeck(deckId);
}
