// lib/domain/usecases/deck/update_deck.dart
import '../../entities/deck.dart';
import '../../repositories/deck_repository.dart';

class UpdateDeck {
  final DeckRepository _repository;
  UpdateDeck(this._repository);

  Future<void> execute(Deck deck) => _repository.updateDeck(deck);
}
