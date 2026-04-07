// lib/domain/repositories/review_repository.dart
import '../entities/review_log.dart';

abstract interface class ReviewRepository {
  Future<void> saveReviewLog(ReviewLog log);
  Future<List<ReviewLog>> getReviewLogs({DateTime? from, DateTime? to});
  Future<List<ReviewLog>> getReviewLogsByDeck(String deckId);
  Future<int> countReviewsToday();
}
