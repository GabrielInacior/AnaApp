// lib/domain/usecases/deck/get_decks.dart
import '../../entities/deck.dart';
import '../../repositories/deck_repository.dart';

class GetDecks {
  final DeckRepository _repository;
  GetDecks(this._repository);

  Future<List<Deck>> execute() => _repository.getDecks();
}
