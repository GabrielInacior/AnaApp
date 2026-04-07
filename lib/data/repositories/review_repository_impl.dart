// lib/data/repositories/review_repository_impl.dart
import '../../domain/entities/review_log.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/local/review_dao.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewDAO _dao;
  ReviewRepositoryImpl(this._dao);

  @override
  Future<void> saveReviewLog(ReviewLog log) => _dao.insert(log);

  @override
  Future<List<ReviewLog>> getReviewLogs({DateTime? from, DateTime? to}) =>
      _dao.getLogs(from: from, to: to);

  @override
  Future<List<ReviewLog>> getReviewLogsByDeck(String deckId) =>
      _dao.getByDeck(deckId);

  @override
  Future<int> countReviewsToday() => _dao.countToday();
}
