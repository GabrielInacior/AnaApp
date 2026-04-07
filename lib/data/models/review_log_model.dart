// lib/data/models/review_log_model.dart
import '../../domain/entities/review_log.dart';

class ReviewLogModel {
  final String id;
  final String cardId;
  final String deckId;
  final int rating;
  final String reviewedAt;
  final int intervalAfter;

  const ReviewLogModel({
    required this.id,
    required this.cardId,
    required this.deckId,
    required this.rating,
    required this.reviewedAt,
    required this.intervalAfter,
  });

  factory ReviewLogModel.fromMap(Map<String, dynamic> map) => ReviewLogModel(
        id: map['id'] as String,
        cardId: map['card_id'] as String,
        deckId: map['deck_id'] as String,
        rating: map['rating'] as int,
        reviewedAt: map['reviewed_at'] as String,
        intervalAfter: map['interval_after'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'card_id': cardId,
        'deck_id': deckId,
        'rating': rating,
        'reviewed_at': reviewedAt,
        'interval_after': intervalAfter,
      };

  ReviewLog toEntity() => ReviewLog(
        id: id,
        cardId: cardId,
        deckId: deckId,
        rating: rating,
        reviewedAt: DateTime.parse(reviewedAt),
        intervalAfter: intervalAfter,
      );

  factory ReviewLogModel.fromEntity(ReviewLog log) => ReviewLogModel(
        id: log.id,
        cardId: log.cardId,
        deckId: log.deckId,
        rating: log.rating,
        reviewedAt: log.reviewedAt.toIso8601String(),
        intervalAfter: log.intervalAfter,
      );
}
