import 'package:flutter_test/flutter_test.dart';
import 'package:ana_app/core/utils/sm2.dart';

void main() {
  group('SM2.calculate', () {
    test('again resets repetitions and sets interval to 1', () {
      final result = SM2.calculate(
        easeFactor: 2.5,
        interval: 10,
        repetitions: 5,
        rating: CardRating.again,
      );
      expect(result.repetitions, 0);
      expect(result.interval, 1);
      expect(result.easeFactor, lessThan(2.5));
    });

    test('first good review gives interval 1', () {
      final result = SM2.calculate(
        easeFactor: 2.5,
        interval: 0,
        repetitions: 0,
        rating: CardRating.good,
      );
      expect(result.interval, 1);
      expect(result.repetitions, 1);
    });

    test('second good review gives interval 6', () {
      final result = SM2.calculate(
        easeFactor: 2.5,
        interval: 1,
        repetitions: 1,
        rating: CardRating.good,
      );
      expect(result.interval, 6);
      expect(result.repetitions, 2);
    });

    test('third review multiplies by easeFactor', () {
      final result = SM2.calculate(
        easeFactor: 2.5,
        interval: 6,
        repetitions: 2,
        rating: CardRating.good,
      );
      expect(result.interval, (6 * result.easeFactor).round());
    });

    test('easy rating gives bonus interval', () {
      final easy = SM2.calculate(
        easeFactor: 2.5,
        interval: 6,
        repetitions: 2,
        rating: CardRating.easy,
      );
      final good = SM2.calculate(
        easeFactor: 2.5,
        interval: 6,
        repetitions: 2,
        rating: CardRating.good,
      );
      expect(easy.interval, greaterThan(good.interval));
    });

    test('easeFactor never goes below 1.3', () {
      var ef = 1.4;
      for (int i = 0; i < 20; i++) {
        final result = SM2.calculate(
          easeFactor: ef,
          interval: 1,
          repetitions: 0,
          rating: CardRating.again,
        );
        ef = result.easeFactor;
      }
      expect(ef, greaterThanOrEqualTo(1.3));
    });
  });
}
