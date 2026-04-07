// lib/presentation/providers/stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/review/get_stats.dart';
import 'repository_providers.dart';

final statsProvider = FutureProvider.autoDispose<List<DailyStats>>((ref) async {
  return ref.watch(getStatsUseCaseProvider).getLast30Days();
});

final todayReviewCountProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.watch(getStatsUseCaseProvider).getTodayCount();
});

final fullStatsProvider = FutureProvider.autoDispose<FullStats>((ref) async {
  return ref.watch(getStatsUseCaseProvider).getFullStats();
});
