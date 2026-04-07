// lib/domain/entities/deck_config.dart
class DeckConfig {
  final String deckId;
  final int newCardsPerDay;
  final int reviewsPerDay;
  final List<int> learningSteps; // minutes: [1, 10]
  final int graduatingInterval; // days
  final int easyInterval; // days
  final List<int> relearningSteps; // minutes: [10]
  final int lapseThreshold; // leech after N lapses
  final int maxInterval; // max days

  const DeckConfig({
    required this.deckId,
    this.newCardsPerDay = 20,
    this.reviewsPerDay = 200,
    this.learningSteps = const [1, 10],
    this.graduatingInterval = 1,
    this.easyInterval = 4,
    this.relearningSteps = const [10],
    this.lapseThreshold = 8,
    this.maxInterval = 36500,
  });

  DeckConfig copyWith({
    int? newCardsPerDay,
    int? reviewsPerDay,
    List<int>? learningSteps,
    int? graduatingInterval,
    int? easyInterval,
    List<int>? relearningSteps,
    int? lapseThreshold,
    int? maxInterval,
  }) {
    return DeckConfig(
      deckId: deckId,
      newCardsPerDay: newCardsPerDay ?? this.newCardsPerDay,
      reviewsPerDay: reviewsPerDay ?? this.reviewsPerDay,
      learningSteps: learningSteps ?? this.learningSteps,
      graduatingInterval: graduatingInterval ?? this.graduatingInterval,
      easyInterval: easyInterval ?? this.easyInterval,
      relearningSteps: relearningSteps ?? this.relearningSteps,
      lapseThreshold: lapseThreshold ?? this.lapseThreshold,
      maxInterval: maxInterval ?? this.maxInterval,
    );
  }
}
