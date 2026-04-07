// lib/domain/usecases/review/get_stats.dart
import '../../repositories/flashcard_repository.dart';
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

class MasteryDistribution {
  final int newCards;
  final int learning;
  final int young;
  final int mature;
  int get total => newCards + learning + young + mature;
  const MasteryDistribution({required this.newCards, required this.learning, required this.young, required this.mature});
}

class RatingDistribution {
  final int again;
  final int hard;
  final int good;
  final int easy;
  int get total => again + hard + good + easy;
  const RatingDistribution({required this.again, required this.hard, required this.good, required this.easy});
}

class ForecastDay {
  final DateTime date;
  final int dueCount;
  const ForecastDay({required this.date, required this.dueCount});
}

class FullStats {
  final List<DailyStats> dailyStats;
  final int todayCount;
  final int streakDays;
  final MasteryDistribution mastery;
  final RatingDistribution ratingBreakdown;
  final List<ForecastDay> weekForecast;

  int get total30dReviews => dailyStats.fold(0, (s, d) => s + d.reviewCount);
  double get accuracy30d {
    final total = dailyStats.fold(0, (int s, DailyStats d) => s + d.reviewCount);
    final correct = dailyStats.fold(0, (int s, DailyStats d) => s + d.correctCount);
    return total == 0 ? 0.0 : correct / total;
  }

  const FullStats({
    required this.dailyStats,
    required this.todayCount,
    required this.streakDays,
    required this.mastery,
    required this.ratingBreakdown,
    required this.weekForecast,
  });
}

class GetStats {
  final ReviewRepository _repository;
  final FlashcardRepository _cardRepository;
  GetStats(this._repository, this._cardRepository);

  Future<List<DailyStats>> getLast30Days() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day - 29);
    final logs = await _repository.getReviewLogs(from: from, to: now);

    final Map<String, DailyStats> byDay = {};
    for (final log in logs) {
      final key =
          '${log.reviewedAt.year}-${log.reviewedAt.month}-${log.reviewedAt.day}';
      final existing = byDay[key];
      final isCorrect = log.rating >= 2; // Hard(2), Good(3), Easy(4) = correct; Again(1) = incorrect
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

  Future<FullStats> getFullStats() async {
    final dailyStats = await getLast30Days();
    final todayCount = await getTodayCount();
    final streakDays = await _repository.getStreakDays();
    final now = DateTime.now();
    final thirtyDaysAgo = DateTime(now.year, now.month, now.day - 29);
    final ratingMap = await _repository.getRatingDistribution(from: thirtyDaysAgo, to: now);
    final masteryMap = await _cardRepository.getMasteryDistribution();
    final forecastEntries = await _cardRepository.getDueForecast(7);

    return FullStats(
      dailyStats: dailyStats,
      todayCount: todayCount,
      streakDays: streakDays,
      mastery: MasteryDistribution(
        newCards: masteryMap['new'] ?? 0,
        learning: masteryMap['learning'] ?? 0,
        young: masteryMap['young'] ?? 0,
        mature: masteryMap['mature'] ?? 0,
      ),
      ratingBreakdown: RatingDistribution(
        again: ratingMap[0] ?? 0,
        hard: ratingMap[2] ?? 0,
        good: ratingMap[3] ?? 0,
        easy: ratingMap[4] ?? 0,
      ),
      weekForecast: forecastEntries
          .map((e) => ForecastDay(date: e.key, dueCount: e.value))
          .toList(),
    );
  }
}
