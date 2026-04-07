import 'package:flutter_test/flutter_test.dart';
import 'package:ana_app/core/utils/sm2.dart';
import 'package:ana_app/domain/entities/deck_config.dart';
import 'package:ana_app/domain/entities/flashcard.dart';

void main() {
  const config = DeckConfig(deckId: 'test');
  final now = DateTime.now();

  Flashcard makeCard({
    CardQueue queue = CardQueue.newCard,
    CardType cardType = CardType.newCard,
    double easeFactor = 2.5,
    int interval = 0,
    int repetitions = 0,
    int lapses = 0,
    int remainingSteps = 0,
  }) {
    return Flashcard(
      id: 'test',
      deckId: 'test',
      front: 'Q',
      back: 'A',
      createdAt: now,
      dueDate: now,
      easeFactor: easeFactor,
      interval: interval,
      repetitions: repetitions,
      queue: queue,
      cardType: cardType,
      lapses: lapses,
      remainingSteps: remainingSteps,
    );
  }

  group('AnkiScheduler - New/Learning cards', () {
    test('again restarts learning steps', () {
      final card = makeCard();
      final result = AnkiScheduler.schedule(
          card: card, rating: CardRating.again, config: config, now: now);
      expect(result.queue, CardQueue.learning);
      expect(result.remainingSteps, 0);
    });

    test('good advances step, then graduates', () {
      final card = makeCard();
      // Step 0 -> step 1
      final r1 = AnkiScheduler.schedule(
          card: card, rating: CardRating.good, config: config, now: now);
      expect(r1.queue, CardQueue.learning);
      expect(r1.remainingSteps, 1);

      // Step 1 -> graduate (2 steps: [1, 10])
      final card2 = card.copyWith(
          queue: r1.queue,
          cardType: r1.cardType,
          remainingSteps: r1.remainingSteps);
      final r2 = AnkiScheduler.schedule(
          card: card2, rating: CardRating.good, config: config, now: now);
      expect(r2.queue, CardQueue.review);
      expect(r2.interval, config.graduatingInterval);
    });

    test('easy graduates immediately with easy interval', () {
      final card = makeCard();
      final result = AnkiScheduler.schedule(
          card: card, rating: CardRating.easy, config: config, now: now);
      expect(result.queue, CardQueue.review);
      expect(result.interval, config.easyInterval);
    });
  });

  group('AnkiScheduler - Review cards', () {
    test('again creates a lapse and moves to relearning', () {
      final card = makeCard(
          queue: CardQueue.review,
          cardType: CardType.review,
          interval: 10,
          repetitions: 5);
      final result = AnkiScheduler.schedule(
          card: card, rating: CardRating.again, config: config, now: now);
      expect(result.queue, CardQueue.relearning);
      expect(result.lapses, card.lapses + 1);
      expect(result.easeFactor, lessThan(card.easeFactor));
    });

    test('good increases interval by easeFactor', () {
      final card = makeCard(
          queue: CardQueue.review,
          cardType: CardType.review,
          interval: 10,
          repetitions: 3);
      final result = AnkiScheduler.schedule(
          card: card, rating: CardRating.good, config: config, now: now);
      expect(result.queue, CardQueue.review);
      expect(result.interval, greaterThan(card.interval));
    });

    test('easy gives larger interval than good', () {
      final card = makeCard(
          queue: CardQueue.review,
          cardType: CardType.review,
          interval: 10,
          repetitions: 3);
      final easy = AnkiScheduler.schedule(
          card: card, rating: CardRating.easy, config: config, now: now);
      final good = AnkiScheduler.schedule(
          card: card, rating: CardRating.good, config: config, now: now);
      expect(easy.interval, greaterThan(good.interval));
    });
  });

  group('AnkiScheduler - Relearning', () {
    test('good in relearning re-graduates to review', () {
      final card = makeCard(
          queue: CardQueue.relearning,
          cardType: CardType.relearning,
          interval: 5,
          remainingSteps: 0);
      // relearningSteps = [10], one step => good graduates
      final result = AnkiScheduler.schedule(
          card: card, rating: CardRating.good, config: config, now: now);
      expect(result.queue, CardQueue.review);
    });
  });

  group('AnkiScheduler - easeFactor bounds', () {
    test('easeFactor never goes below 1.3', () {
      var card = makeCard(
          queue: CardQueue.review,
          cardType: CardType.review,
          easeFactor: 1.4,
          interval: 1,
          repetitions: 1);
      for (int i = 0; i < 20; i++) {
        final result = AnkiScheduler.schedule(
            card: card, rating: CardRating.again, config: config, now: now);
        card = card.copyWith(
          easeFactor: result.easeFactor,
          interval: result.interval,
          queue: CardQueue.review,
          cardType: CardType.review,
        );
      }
      expect(card.easeFactor, greaterThanOrEqualTo(1.3));
    });
  });
}
