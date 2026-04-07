import 'package:flutter/foundation.dart';

/// Ratings para avaliação do card
enum CardRating {
  again(0),   // Errou — reinicia
  hard(2),    // Lembrou com dificuldade
  good(3),    // Lembrou corretamente
  easy(4);    // Lembrou com facilidade

  final int value;
  const CardRating(this.value);
}

@immutable
class SM2Result {
  final double easeFactor;
  final int interval;     // dias até próxima revisão
  final int repetitions;

  const SM2Result({
    required this.easeFactor,
    required this.interval,
    required this.repetitions,
  });
}

class SM2 {
  SM2._();

  static const double _minEaseFactor = 1.3;
  static const double _initialEaseFactor = 2.5;

  /// Calcula o próximo intervalo baseado no rating.
  /// [easeFactor] fator atual (inicia em 2.5)
  /// [interval] intervalo atual em dias
  /// [repetitions] número de repetições consecutivas corretas
  /// [rating] avaliação do usuário
  static SM2Result calculate({
    required double easeFactor,
    required int interval,
    required int repetitions,
    required CardRating rating,
  }) {
    if (rating == CardRating.again) {
      // Reinicia repetições, intervalo volta a 1
      return SM2Result(
        easeFactor: (easeFactor - 0.2).clamp(_minEaseFactor, 5.0),
        interval: 1,
        repetitions: 0,
      );
    }

    // Calcula novo easeFactor: EF' = EF + (0.1 - (5-q)*(0.08 + (5-q)*0.02))
    final q = rating.value;
    final newEF = (easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))
        .clamp(_minEaseFactor, 5.0);

    int newInterval;
    final newRepetitions = repetitions + 1;

    if (repetitions == 0) {
      newInterval = 1;
    } else if (repetitions == 1) {
      newInterval = 6;
    } else {
      newInterval = (interval * newEF).round();
    }

    if (rating == CardRating.easy) {
      newInterval = (newInterval * 1.3).round();
    }

    return SM2Result(
      easeFactor: newEF,
      interval: newInterval,
      repetitions: newRepetitions,
    );
  }

  static DateTime nextDueDate(int intervalDays, {DateTime? from}) {
    final base = from ?? DateTime.now();
    return DateTime(base.year, base.month, base.day + intervalDays);
  }

  static double get initialEaseFactor => _initialEaseFactor;
}
