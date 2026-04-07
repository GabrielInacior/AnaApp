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
      );
}
