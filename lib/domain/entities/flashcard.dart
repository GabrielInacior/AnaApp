// lib/domain/entities/flashcard.dart

/// Card queue (where the card lives in the scheduling system)
enum CardQueue {
  newCard(0),
  learning(1),
  review(2),
  relearning(3);

  final int value;
  const CardQueue(this.value);

  static CardQueue fromValue(int v) => CardQueue.values.firstWhere(
        (q) => q.value == v,
        orElse: () => CardQueue.newCard,
      );
}

/// Card type (permanent classification)
enum CardType {
  newCard(0),
  learning(1),
  review(2),
  relearning(3);

  final int value;
  const CardType(this.value);

  static CardType fromValue(int v) => CardType.values.firstWhere(
        (t) => t.value == v,
        orElse: () => CardType.newCard,
      );
}

class Flashcard {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final DateTime createdAt;

  // SM-2 fields
  final double easeFactor;
  final int interval;
  final int repetitions;
  final DateTime dueDate;

  // Image paths
  final String? frontImagePath;
  final String? backImagePath;

  // Anki-style card state
  final CardQueue queue;
  final CardType cardType;
  final int lapses;
  final int remainingSteps;

  // Image generation pending flag
  final bool pendingImage;

  const Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.createdAt,
    this.easeFactor = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    required this.dueDate,
    this.frontImagePath,
    this.backImagePath,
    this.queue = CardQueue.newCard,
    this.cardType = CardType.newCard,
    this.lapses = 0,
    this.remainingSteps = 0,
    this.pendingImage = false,
  });

  Flashcard copyWith({
    String? front,
    String? back,
    double? easeFactor,
    int? interval,
    int? repetitions,
    DateTime? dueDate,
    String? frontImagePath,
    bool clearFrontImage = false,
    String? backImagePath,
    bool clearBackImage = false,
    CardQueue? queue,
    CardType? cardType,
    int? lapses,
    int? remainingSteps,
    bool? pendingImage,
  }) {
    return Flashcard(
      id: id,
      deckId: deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      createdAt: createdAt,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      dueDate: dueDate ?? this.dueDate,
      frontImagePath:
          clearFrontImage ? null : (frontImagePath ?? this.frontImagePath),
      backImagePath:
          clearBackImage ? null : (backImagePath ?? this.backImagePath),
      queue: queue ?? this.queue,
      cardType: cardType ?? this.cardType,
      lapses: lapses ?? this.lapses,
      remainingSteps: remainingSteps ?? this.remainingSteps,
      pendingImage: pendingImage ?? this.pendingImage,
    );
  }
}
