// lib/presentation/providers/review_session_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/sm2.dart';
import '../../domain/entities/flashcard.dart';
import 'repository_providers.dart';
import 'deck_provider.dart';

class ReviewSessionState {
  final List<Flashcard> queue;
  final int currentIndex;
  final bool isFlipped;
  final bool isComplete;
  final int correct;
  final int total;

  const ReviewSessionState({
    required this.queue,
    this.currentIndex = 0,
    this.isFlipped = false,
    this.isComplete = false,
    this.correct = 0,
    this.total = 0,
  });

  Flashcard? get currentCard =>
      currentIndex < queue.length ? queue[currentIndex] : null;

  ReviewSessionState copyWith({
    List<Flashcard>? queue,
    int? currentIndex,
    bool? isFlipped,
    bool? isComplete,
    int? correct,
    int? total,
  }) {
    return ReviewSessionState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      isComplete: isComplete ?? this.isComplete,
      correct: correct ?? this.correct,
      total: total ?? this.total,
    );
  }
}

final reviewSessionProvider =
    StateNotifierProvider.family<ReviewSessionNotifier, ReviewSessionState, String>(
  (ref, deckId) => ReviewSessionNotifier(ref, deckId),
);

class ReviewSessionNotifier extends StateNotifier<ReviewSessionState> {
  final Ref _ref;
  final String _deckId;

  ReviewSessionNotifier(this._ref, this._deckId)
      : super(const ReviewSessionState(queue: [])) {
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards =
        await _ref.read(getDueCardsUseCaseProvider).execute(_deckId);
    state = ReviewSessionState(queue: cards, total: cards.length);
  }

  void flipCard() {
    state = state.copyWith(isFlipped: true);
  }

  Future<void> submitRating(CardRating rating) async {
    final card = state.currentCard;
    if (card == null) return;

    await _ref.read(submitReviewUseCaseProvider).execute(
          card: card,
          rating: rating,
        );

    final isCorrect = rating != CardRating.again;
    final nextIndex = state.currentIndex + 1;
    final isComplete = nextIndex >= state.queue.length;

    state = state.copyWith(
      currentIndex: nextIndex,
      isFlipped: false,
      isComplete: isComplete,
      correct: state.correct + (isCorrect ? 1 : 0),
    );

    if (isComplete) {
      _ref.invalidate(deckProvider);
    }
  }
}
