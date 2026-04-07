// lib/presentation/providers/stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/review/get_stats.dart';
import 'repository_providers.dart';

final statsProvider = FutureProvider<List<DailyStats>>((ref) async {
  return ref.read(getStatsUseCaseProvider).getLast30Days();
});

final todayReviewCountProvider = FutureProvider<int>((ref) async {
  return ref.read(getStatsUseCaseProvider).getTodayCount();
});
