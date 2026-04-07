// lib/domain/usecases/flashcard/delete_card.dart
import '../../repositories/flashcard_repository.dart';

class DeleteCard {
  final FlashcardRepository _repository;
  DeleteCard(this._repository);

  Future<void> execute(String cardId) => _repository.deleteCard(cardId);
}
