// lib/domain/entities/review_log.dart
class ReviewLog {
  final String id;
  final String cardId;
  final String deckId;
  final int rating;        // 0=Again, 2=Hard, 3=Good, 4=Easy
  final DateTime reviewedAt;
  final int intervalAfter; // intervalo aplicado após a revisão

  const ReviewLog({
    required this.id,
    required this.cardId,
    required this.deckId,
    required this.rating,
    required this.reviewedAt,
    required this.intervalAfter,
  });
}
