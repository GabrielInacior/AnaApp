// lib/domain/usecases/review/get_stats.dart
import '../../repositories/review_repository.dart';

class DailyStats {
  final DateTime date;
  final int reviewCount;
  final int correctCount; // rating >= 3 (Good ou Easy)

  const DailyStats({
    required this.date,
    required this.reviewCount,
    required this.correctCount,
  });

  double get accuracy =>
      reviewCount == 0 ? 0 : correctCount / reviewCount;
}

class GetStats {
  final ReviewRepository _repository;
  GetStats(this._repository);

  Future<List<DailyStats>> getLast30Days() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day - 29);
    final logs = await _repository.getReviewLogs(from: from, to: now);

    final Map<String, DailyStats> byDay = {};
    for (final log in logs) {
      final key =
          '${log.reviewedAt.year}-${log.reviewedAt.month}-${log.reviewedAt.day}';
      final existing = byDay[key];
      final isCorrect = log.rating >= 3;
      byDay[key] = DailyStats(
        date: DateTime(
            log.reviewedAt.year, log.reviewedAt.month, log.reviewedAt.day),
        reviewCount: (existing?.reviewCount ?? 0) + 1,
        correctCount: (existing?.correctCount ?? 0) + (isCorrect ? 1 : 0),
      );
    }

    return byDay.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<int> getTodayCount() => _repository.countReviewsToday();
}
