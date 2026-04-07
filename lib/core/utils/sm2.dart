// lib/core/utils/sm2.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../domain/entities/deck_config.dart';
import '../../domain/entities/flashcard.dart';

/// Ratings for card evaluation
enum CardRating {
  again(0), // Failed
  hard(2),  // Remembered with difficulty
  good(3),  // Remembered correctly
  easy(4);  // Remembered easily

  final int value;
  const CardRating(this.value);
}

/// Result of scheduling a card
@immutable
class ScheduleResult {
  final double easeFactor;
  final int interval; // days until next review
  final int repetitions;
  final DateTime dueDate;
  final CardQueue queue;
  final CardType cardType;
  final int lapses;
  final int remainingSteps;

  const ScheduleResult({
    required this.easeFactor,
    required this.interval,
    required this.repetitions,
    required this.dueDate,
    required this.queue,
    required this.cardType,
    required this.lapses,
    required this.remainingSteps,
  });
}

/// Preview of what each rating would produce (for button labels)
@immutable
class RatingPreview {
  final String label; // e.g. "1min", "10min", "1d", "4d"
  final CardRating rating;

  const RatingPreview({required this.label, required this.rating});
}

class AnkiScheduler {
  AnkiScheduler._();

  static const double _minEaseFactor = 1.3;
  static const double _initialEaseFactor = 2.5;
  static final _rng = Random();

  static double get initialEaseFactor => _initialEaseFactor;

  /// Schedule a card based on its current state and the user's rating
  static ScheduleResult schedule({
    required Flashcard card,
    required CardRating rating,
    required DeckConfig config,
    DateTime? now,
  }) {
    final baseNow = now ?? DateTime.now();

    switch (card.queue) {
      case CardQueue.newCard:
      case CardQueue.learning:
        return _scheduleLearning(card, rating, config, baseNow);
      case CardQueue.review:
        return _scheduleReview(card, rating, config, baseNow);
      case CardQueue.relearning:
        return _scheduleRelearning(card, rating, config, baseNow);
    }
  }

  /// Preview intervals for all 4 ratings (for button labels)
  static List<RatingPreview> previewAll({
    required Flashcard card,
    required DeckConfig config,
    DateTime? now,
  }) {
    final baseNow = now ?? DateTime.now();
    return [
      for (final r in CardRating.values)
        RatingPreview(
          rating: r,
          label: _intervalLabel(
            schedule(card: card, rating: r, config: config, now: baseNow),
            baseNow,
          ),
        ),
    ];
  }

  // ─── Learning / New cards ─────────────────────────────────────

  static ScheduleResult _scheduleLearning(
    Flashcard card,
    CardRating rating,
    DeckConfig config,
    DateTime now,
  ) {
    final steps = config.learningSteps;
    final currentStep = card.remainingSteps;

    switch (rating) {
      case CardRating.again:
        // Restart learning steps
        return ScheduleResult(
          easeFactor: card.easeFactor,
          interval: 0,
          repetitions: 0,
          dueDate: now.add(Duration(minutes: steps.isNotEmpty ? steps[0] : 1)),
          queue: CardQueue.learning,
          cardType: CardType.learning,
          lapses: card.lapses,
          remainingSteps: 0,
        );

      case CardRating.hard:
        // Repeat current step at 1.5x duration
        final stepMinutes = currentStep < steps.length
            ? steps[currentStep]
            : (steps.isNotEmpty ? steps.last : 1);
        final hardMinutes = (stepMinutes * 1.5).round().clamp(1, 10080);
        return ScheduleResult(
          easeFactor: card.easeFactor,
          interval: 0,
          repetitions: card.repetitions,
          dueDate: now.add(Duration(minutes: hardMinutes)),
          queue: CardQueue.learning,
          cardType: CardType.learning,
          lapses: card.lapses,
          remainingSteps: currentStep, // stay on same step
        );

      case CardRating.good:
        final nextStep = currentStep + 1;
        if (nextStep >= steps.length) {
          // Graduate!
          return _graduate(card, config, now, isEasy: false);
        }
        return ScheduleResult(
          easeFactor: card.easeFactor,
          interval: 0,
          repetitions: card.repetitions,
          dueDate: now.add(Duration(minutes: steps[nextStep])),
          queue: CardQueue.learning,
          cardType: CardType.learning,
          lapses: card.lapses,
          remainingSteps: nextStep,
        );

      case CardRating.easy:
        // Graduate immediately with easy interval
        return _graduate(card, config, now, isEasy: true);
    }
  }

  static ScheduleResult _graduate(
    Flashcard card,
    DeckConfig config,
    DateTime now, {
    required bool isEasy,
  }) {
    final interval = isEasy ? config.easyInterval : config.graduatingInterval;
    final clamped = interval.clamp(1, config.maxInterval);
    return ScheduleResult(
      easeFactor: card.easeFactor,
      interval: clamped,
      repetitions: card.repetitions + 1,
      dueDate: _nextDueDate(clamped, from: now),
      queue: CardQueue.review,
      cardType: CardType.review,
      lapses: card.lapses,
      remainingSteps: 0,
    );
  }

  // ─── Review cards ─────────────────────────────────────────────

  static ScheduleResult _scheduleReview(
    Flashcard card,
    CardRating rating,
    DeckConfig config,
    DateTime now,
  ) {
    final ef = card.easeFactor;
    final interval = card.interval.clamp(1, config.maxInterval);

    switch (rating) {
      case CardRating.again:
        // LAPSE: move to relearning
        final newEF = (ef - 0.2).clamp(_minEaseFactor, 5.0);
        final newInterval = max(1, (interval * 0.5).round());
        final steps = config.relearningSteps;
        return ScheduleResult(
          easeFactor: newEF,
          interval: newInterval,
          repetitions: 0,
          dueDate: now.add(Duration(
              minutes: steps.isNotEmpty ? steps[0] : 10)),
          queue: CardQueue.relearning,
          cardType: CardType.relearning,
          lapses: card.lapses + 1,
          remainingSteps: 0,
        );

      case CardRating.hard:
        final newEF = (ef - 0.15).clamp(_minEaseFactor, 5.0);
        final raw = (interval * 1.2).round();
        final fuzzed = _fuzz(raw);
        final clamped = fuzzed.clamp(1, config.maxInterval);
        return ScheduleResult(
          easeFactor: newEF,
          interval: clamped,
          repetitions: card.repetitions + 1,
          dueDate: _nextDueDate(clamped, from: now),
          queue: CardQueue.review,
          cardType: CardType.review,
          lapses: card.lapses,
          remainingSteps: 0,
        );

      case CardRating.good:
        final q = rating.value;
        final newEF =
            (ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))
                .clamp(_minEaseFactor, 5.0);
        final raw = (interval * newEF).round();
        final fuzzed = _fuzz(raw);
        final clamped = fuzzed.clamp(1, config.maxInterval);
        return ScheduleResult(
          easeFactor: newEF,
          interval: clamped,
          repetitions: card.repetitions + 1,
          dueDate: _nextDueDate(clamped, from: now),
          queue: CardQueue.review,
          cardType: CardType.review,
          lapses: card.lapses,
          remainingSteps: 0,
        );

      case CardRating.easy:
        final q = rating.value;
        final newEF =
            (ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))
                .clamp(_minEaseFactor, 5.0);
        final raw = (interval * newEF * 1.3).round();
        final fuzzed = _fuzz(raw);
        final clamped = fuzzed.clamp(1, config.maxInterval);
        return ScheduleResult(
          easeFactor: newEF,
          interval: clamped,
          repetitions: card.repetitions + 1,
          dueDate: _nextDueDate(clamped, from: now),
          queue: CardQueue.review,
          cardType: CardType.review,
          lapses: card.lapses,
          remainingSteps: 0,
        );
    }
  }

  // ─── Relearning cards ─────────────────────────────────────────

  static ScheduleResult _scheduleRelearning(
    Flashcard card,
    CardRating rating,
    DeckConfig config,
    DateTime now,
  ) {
    final steps = config.relearningSteps;
    final currentStep = card.remainingSteps;

    switch (rating) {
      case CardRating.again:
        // Restart relearning steps
        return ScheduleResult(
          easeFactor: card.easeFactor,
          interval: card.interval,
          repetitions: 0,
          dueDate: now.add(Duration(minutes: steps.isNotEmpty ? steps[0] : 10)),
          queue: CardQueue.relearning,
          cardType: CardType.relearning,
          lapses: card.lapses,
          remainingSteps: 0,
        );

      case CardRating.hard:
        final stepMinutes = currentStep < steps.length
            ? steps[currentStep]
            : (steps.isNotEmpty ? steps.last : 10);
        final hardMinutes = (stepMinutes * 1.5).round().clamp(1, 10080);
        return ScheduleResult(
          easeFactor: card.easeFactor,
          interval: card.interval,
          repetitions: card.repetitions,
          dueDate: now.add(Duration(minutes: hardMinutes)),
          queue: CardQueue.relearning,
          cardType: CardType.relearning,
          lapses: card.lapses,
          remainingSteps: currentStep,
        );

      case CardRating.good:
        final nextStep = currentStep + 1;
        if (nextStep >= steps.length) {
          // Graduate back to review
          return _regraduateToReview(card, config, now);
        }
        return ScheduleResult(
          easeFactor: card.easeFactor,
          interval: card.interval,
          repetitions: card.repetitions,
          dueDate: now.add(Duration(minutes: steps[nextStep])),
          queue: CardQueue.relearning,
          cardType: CardType.relearning,
          lapses: card.lapses,
          remainingSteps: nextStep,
        );

      case CardRating.easy:
        // Graduate immediately back to review
        return _regraduateToReview(card, config, now);
    }
  }

  static ScheduleResult _regraduateToReview(
    Flashcard card,
    DeckConfig config,
    DateTime now,
  ) {
    // Keep the lapsed interval (already halved on lapse)
    final interval = card.interval.clamp(1, config.maxInterval);
    return ScheduleResult(
      easeFactor: card.easeFactor,
      interval: interval,
      repetitions: card.repetitions + 1,
      dueDate: _nextDueDate(interval, from: now),
      queue: CardQueue.review,
      cardType: CardType.review,
      lapses: card.lapses,
      remainingSteps: 0,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────

  /// Add ±5% fuzz to intervals >= 3 days
  static int _fuzz(int intervalDays) {
    if (intervalDays < 3) return intervalDays;
    final fuzzRange = (intervalDays * 0.05).round().clamp(1, 50);
    return intervalDays + _rng.nextInt(fuzzRange * 2 + 1) - fuzzRange;
  }

  static DateTime _nextDueDate(int intervalDays, {required DateTime from}) {
    return DateTime(from.year, from.month, from.day + intervalDays);
  }

  /// Format an interval for button labels
  static String _intervalLabel(ScheduleResult result, DateTime now) {
    final diff = result.dueDate.difference(now);
    final minutes = diff.inMinutes;

    if (result.queue == CardQueue.learning ||
        result.queue == CardQueue.relearning) {
      if (minutes < 60) return '${max(1, minutes)}min';
      if (minutes < 1440) return '${(minutes / 60).round()}h';
    }

    final days = result.interval;
    if (days == 0 && minutes < 60) return '${max(1, minutes)}min';
    if (days == 0) return '${(minutes / 60).round()}h';
    if (days == 1) return '1d';
    if (days < 30) return '${days}d';
    if (days < 365) return '${(days / 30).round()}m';
    return '${(days / 365.0).toStringAsFixed(1)}a';
  }
}
