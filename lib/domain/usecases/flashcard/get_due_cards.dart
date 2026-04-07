// lib/domain/usecases/flashcard/get_due_cards.dart
import '../../entities/flashcard.dart';
import '../../repositories/flashcard_repository.dart';

class GetDueCards {
  final FlashcardRepository _repository;
  GetDueCards(this._repository);

  Future<List<Flashcard>> execute(String deckId) =>
      _repository.getDueCards(deckId, DateTime.now());

  Future<List<Flashcard>> executeAll() =>
      _repository.getAllDueCards(DateTime.now());
}
