// test/domain/entities/flashcard_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ana_app/domain/entities/flashcard.dart';

void main() {
  group('Flashcard', () {
    final card = Flashcard(
      id: '1',
      deckId: 'd1',
      front: 'Hello',
      back: 'Olá',
      createdAt: DateTime(2026, 1, 1),
      dueDate: DateTime(2026, 1, 1),
    );

    test('has default SM-2 values', () {
      expect(card.easeFactor, 2.5);
      expect(card.interval, 0);
      expect(card.repetitions, 0);
    });

    test('copyWith updates fields', () {
      final updated = card.copyWith(front: 'Hi', easeFactor: 2.8);
      expect(updated.front, 'Hi');
      expect(updated.easeFactor, 2.8);
      expect(updated.back, card.back);
      expect(updated.id, card.id);
    });
  });
}
