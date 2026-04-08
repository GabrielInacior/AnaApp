// lib/data/models/flashcard_model.dart
import '../../domain/entities/flashcard.dart';

class FlashcardModel {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final String createdAt;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final String dueDate;
  final String? frontImagePath;
  final String? backImagePath;
  final int queue;
  final int cardType;
  final int lapses;
  final int remainingSteps;
  final int pendingImage;
  final String? tag;

  const FlashcardModel({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.createdAt,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.dueDate,
    this.frontImagePath,
    this.backImagePath,
    this.queue = 0,
    this.cardType = 0,
    this.lapses = 0,
    this.remainingSteps = 0,
    this.pendingImage = 0,
    this.tag,
  });

  factory FlashcardModel.fromMap(Map<String, dynamic> map) => FlashcardModel(
        id: map['id'] as String,
        deckId: map['deck_id'] as String,
        front: map['front'] as String,
        back: map['back'] as String,
        createdAt: map['created_at'] as String,
        easeFactor: (map['ease_factor'] as num).toDouble(),
        intervalDays: map['interval_days'] as int,
        repetitions: map['repetitions'] as int,
        dueDate: map['due_date'] as String,
        frontImagePath: map['front_image_path'] as String?,
        backImagePath: map['back_image_path'] as String?,
        queue: map['queue'] as int? ?? 0,
        cardType: map['card_type'] as int? ?? 0,
        lapses: map['lapses'] as int? ?? 0,
        remainingSteps: map['remaining_steps'] as int? ?? 0,
        pendingImage: map['pending_image'] as int? ?? 0,
        tag: map['tag'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'deck_id': deckId,
        'front': front,
        'back': back,
        'created_at': createdAt,
        'ease_factor': easeFactor,
        'interval_days': intervalDays,
        'repetitions': repetitions,
        'due_date': dueDate,
        'front_image_path': frontImagePath,
        'back_image_path': backImagePath,
        'queue': queue,
        'card_type': cardType,
        'lapses': lapses,
        'remaining_steps': remainingSteps,
        'pending_image': pendingImage,
        'tag': tag,
      };

  Flashcard toEntity() => Flashcard(
        id: id,
        deckId: deckId,
        front: front,
        back: back,
        createdAt: DateTime.parse(createdAt),
        easeFactor: easeFactor,
        interval: intervalDays,
        repetitions: repetitions,
        dueDate: DateTime.parse(dueDate),
        frontImagePath: frontImagePath,
        backImagePath: backImagePath,
        queue: CardQueue.fromValue(queue),
        cardType: CardType.fromValue(cardType),
        lapses: lapses,
        remainingSteps: remainingSteps,
        pendingImage: pendingImage == 1,
        tag: tag,
      );

  factory FlashcardModel.fromEntity(Flashcard card) => FlashcardModel(
        id: card.id,
        deckId: card.deckId,
        front: card.front,
        back: card.back,
        createdAt: card.createdAt.toIso8601String(),
        easeFactor: card.easeFactor,
        intervalDays: card.interval,
        repetitions: card.repetitions,
        dueDate: card.dueDate.toIso8601String(),
        frontImagePath: card.frontImagePath,
        backImagePath: card.backImagePath,
        queue: card.queue.value,
        cardType: card.cardType.value,
        lapses: card.lapses,
        remainingSteps: card.remainingSteps,
        pendingImage: card.pendingImage ? 1 : 0,
        tag: card.tag,
      );
}
