// lib/domain/usecases/review/submit_review.dart
import 'package:uuid/uuid.dart';
import '../../../core/utils/sm2.dart';
import '../../entities/flashcard.dart';
import '../../entities/review_log.dart';
import '../../repositories/flashcard_repository.dart';
import '../../repositories/review_repository.dart';

class SubmitReview {
  final FlashcardRepository _cardRepository;
  final ReviewRepository _reviewRepository;
  final Uuid _uuid;

  SubmitReview({
    required FlashcardRepository cardRepository,
    required ReviewRepository reviewRepository,
    Uuid? uuid,
  })  : _cardRepository = cardRepository,
        _reviewRepository = reviewRepository,
        _uuid = uuid ?? const Uuid();

  Future<Flashcard> execute({
    required Flashcard card,
    required CardRating rating,
  }) async {
    final result = SM2.calculate(
      easeFactor: card.easeFactor,
      interval: card.interval,
      repetitions: card.repetitions,
      rating: rating,
    );

    final nextDue = SM2.nextDueDate(result.interval);
    final updatedCard = card.copyWith(
      easeFactor: result.easeFactor,
      interval: result.interval,
      repetitions: result.repetitions,
      dueDate: nextDue,
    );

    await _cardRepository.updateCard(updatedCard);

    final log = ReviewLog(
      id: _uuid.v4(),
      cardId: card.id,
      deckId: card.deckId,
      rating: rating.value,
      reviewedAt: DateTime.now(),
      intervalAfter: result.interval,
    );
    await _reviewRepository.saveReviewLog(log);

    return updatedCard;
  }
}
