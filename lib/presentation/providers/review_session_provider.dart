// lib/presentation/providers/review_session_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/sm2.dart';
import '../../domain/entities/deck_config.dart';
import '../../domain/entities/flashcard.dart';
import 'repository_providers.dart';
import 'deck_provider.dart';
import 'stats_provider.dart';

/// A learning card with its due time within the session
class LearningEntry {
  final Flashcard card;
  final DateTime dueAt;
  LearningEntry(this.card, this.dueAt);
}

class ReviewSessionState {
  final List<Flashcard> newQueue;
  final List<Flashcard> reviewQueue;
  final List<LearningEntry> learningQueue;
  final Flashcard? currentCard;
  final bool isFlipped;
  final bool isComplete;
  final bool isWaiting; // waiting for learning cards to become due
  final int correct;
  final int total; // total cards seen
  final int currentIndex;
  final DeckConfig config;
  final DateTime? waitingUntil;

  const ReviewSessionState({
    this.newQueue = const [],
    this.reviewQueue = const [],
    this.learningQueue = const [],
    this.currentCard,
    this.isFlipped = false,
    this.isComplete = false,
    this.isWaiting = false,
    this.correct = 0,
    this.total = 0,
    this.currentIndex = 0,
    required this.config,
    this.waitingUntil,
  });

  ReviewSessionState copyWith({
    List<Flashcard>? newQueue,
    List<Flashcard>? reviewQueue,
    List<LearningEntry>? learningQueue,
    Flashcard? currentCard,
    bool clearCurrentCard = false,
    bool? isFlipped,
    bool? isComplete,
    bool? isWaiting,
    int? correct,
    int? total,
    int? currentIndex,
    DeckConfig? config,
    DateTime? waitingUntil,
    bool clearWaitingUntil = false,
  }) {
    return ReviewSessionState(
      newQueue: newQueue ?? this.newQueue,
      reviewQueue: reviewQueue ?? this.reviewQueue,
      learningQueue: learningQueue ?? this.learningQueue,
      currentCard: clearCurrentCard ? null : (currentCard ?? this.currentCard),
      isFlipped: isFlipped ?? this.isFlipped,
      isComplete: isComplete ?? this.isComplete,
      isWaiting: isWaiting ?? this.isWaiting,
      correct: correct ?? this.correct,
      total: total ?? this.total,
      currentIndex: currentIndex ?? this.currentIndex,
      config: config ?? this.config,
      waitingUntil: clearWaitingUntil
          ? null
          : (waitingUntil ?? this.waitingUntil),
    );
  }

  // Legacy getters for compatibility with review_screen
  List<Flashcard> get queue =>
      [...newQueue, ...reviewQueue, ...learningQueue.map((e) => e.card)];
}

final reviewSessionProvider =
    StateNotifierProvider.family<ReviewSessionNotifier, ReviewSessionState, String>(
  (ref, deckId) => ReviewSessionNotifier(ref, deckId),
);

class ReviewSessionNotifier extends StateNotifier<ReviewSessionState> {
  final Ref _ref;
  final String _deckId;

  ReviewSessionNotifier(this._ref, this._deckId)
      : super(const ReviewSessionState(
            config: DeckConfig(deckId: ''))) {
    _loadCards();
  }

  Future<void> _loadCards() async {
    // Load deck config
    final config =
        await _ref.read(deckConfigDaoProvider).getConfig(_deckId);

    final flashcardDao = _ref.read(flashcardDaoProvider);
    final now = DateTime.now();

    // Load the 3 sub-queues from DB
    final newCards =
        await flashcardDao.getNewByDeck(_deckId, config.newCardsPerDay);
    final learningCards = await flashcardDao.getLearningByDeck(_deckId);
    final reviewCards = await flashcardDao.getReviewByDeck(
        _deckId, now, config.reviewsPerDay);

    final learningEntries = learningCards
        .map((c) => LearningEntry(c, c.dueDate))
        .toList();

    final totalAvailable =
        newCards.length + reviewCards.length + learningEntries.length;

    state = ReviewSessionState(
      newQueue: newCards,
      reviewQueue: reviewCards,
      learningQueue: learningEntries,
      config: config,
      total: totalAvailable,
    );

    _pickNextCard();
  }

  void _pickNextCard() {
    final now = DateTime.now();

    // Priority 1: Learning/relearning cards that are due
    final dueLearning = state.learningQueue
        .where((e) => !e.dueAt.isAfter(now))
        .toList();
    if (dueLearning.isNotEmpty) {
      // Pick the one due earliest
      dueLearning.sort((a, b) => a.dueAt.compareTo(b.dueAt));
      final entry = dueLearning.first;
      final remaining = List<LearningEntry>.from(state.learningQueue)
        ..remove(entry);
      state = state.copyWith(
        currentCard: entry.card,
        learningQueue: remaining,
        isFlipped: false,
        isWaiting: false,
        clearWaitingUntil: true,
      );
      return;
    }

    // Priority 2: New cards
    if (state.newQueue.isNotEmpty) {
      final card = state.newQueue.first;
      final remaining = state.newQueue.sublist(1);
      state = state.copyWith(
        currentCard: card,
        newQueue: remaining,
        isFlipped: false,
        isWaiting: false,
        clearWaitingUntil: true,
      );
      return;
    }

    // Priority 3: Review cards
    if (state.reviewQueue.isNotEmpty) {
      final card = state.reviewQueue.first;
      final remaining = state.reviewQueue.sublist(1);
      state = state.copyWith(
        currentCard: card,
        reviewQueue: remaining,
        isFlipped: false,
        isWaiting: false,
        clearWaitingUntil: true,
      );
      return;
    }

    // Priority 4: Check if there are learning cards with future due times
    if (state.learningQueue.isNotEmpty) {
      final nextDue =
          state.learningQueue.map((e) => e.dueAt).reduce(
              (a, b) => a.isBefore(b) ? a : b);
      state = state.copyWith(
        clearCurrentCard: true,
        isWaiting: true,
        isFlipped: false,
        waitingUntil: nextDue,
      );
      return;
    }

    // All done!
    state = state.copyWith(
      clearCurrentCard: true,
      isComplete: true,
      isFlipped: false,
    );
    _ref.invalidate(deckProvider);
    _ref.invalidate(statsProvider);
    _ref.invalidate(todayReviewCountProvider);
  }

  void flipCard() {
    state = state.copyWith(isFlipped: true);
  }

  /// Called when the waiting timer fires — re-pick the next card
  void checkWaiting() {
    if (state.isWaiting) {
      _pickNextCard();
    }
  }

  Future<void> submitRating(CardRating rating) async {
    final card = state.currentCard;
    if (card == null) return;

    final updatedCard = await _ref.read(submitReviewUseCaseProvider).execute(
          card: card,
          rating: rating,
          config: state.config,
        );

    final isCorrect = rating != CardRating.again;

    // If the card is still in learning/relearning, re-enqueue it in session
    if (updatedCard.queue == CardQueue.learning ||
        updatedCard.queue == CardQueue.relearning) {
      final newLearning = List<LearningEntry>.from(state.learningQueue)
        ..add(LearningEntry(updatedCard, updatedCard.dueDate));
      state = state.copyWith(
        learningQueue: newLearning,
        correct: state.correct + (isCorrect ? 1 : 0),
        currentIndex: state.currentIndex + 1,
      );
    } else {
      state = state.copyWith(
        correct: state.correct + (isCorrect ? 1 : 0),
        currentIndex: state.currentIndex + 1,
      );
    }

    _pickNextCard();
  }
}
