// lib/domain/usecases/review/submit_review.dart
import 'package:uuid/uuid.dart';
import '../../../core/utils/sm2.dart';
import '../../entities/deck_config.dart';
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
    required DeckConfig config,
  }) async {
    final result = AnkiScheduler.schedule(
      card: card,
      rating: rating,
      config: config,
    );

    final updatedCard = card.copyWith(
      easeFactor: result.easeFactor,
      interval: result.interval,
      repetitions: result.repetitions,
      dueDate: result.dueDate,
      queue: result.queue,
      cardType: result.cardType,
      lapses: result.lapses,
      remainingSteps: result.remainingSteps,
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
