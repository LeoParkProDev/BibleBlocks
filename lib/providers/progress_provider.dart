import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bible_data.dart';
import '../services/progress_service.dart';
import 'auth_provider.dart';
import 'streak_provider.dart';

final progressServiceProvider = Provider<ProgressService>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.value?.id.toString();
  return ProgressService(userId: userId);
});

final progressProvider =
    AsyncNotifierProvider<ProgressNotifier, Map<int, Set<int>>>(
  ProgressNotifier.new,
);

class ProgressNotifier extends AsyncNotifier<Map<int, Set<int>>> {
  @override
  Future<Map<int, Set<int>>> build() async {
    final service = ref.watch(progressServiceProvider);
    return service.loadAll();
  }

  Future<void> resetAll() async {
    final service = ref.read(progressServiceProvider);
    await service.resetAll();
    state = const AsyncValue.data({});
  }

  Future<void> toggleChapter(int bookIndex, int chapter) async {
    final service = ref.read(progressServiceProvider);
    final current = state.value ?? {};
    final updated = await service.toggleChapter(current, bookIndex, chapter);
    state = AsyncValue.data(updated);
    // 장을 '읽음'으로 추가했을 때만 오늘을 스트릭 활동일로 기록(해제는 무시).
    if (updated[bookIndex]?.contains(chapter) ?? false) {
      ref.read(streakProvider.notifier).recordToday();
    }
  }

  /// 여러 장을 한 번에 읽음 처리(읽기 계획 오늘 분량 등). 스트릭도 기록.
  Future<void> markChaptersRead(
    List<(int bookIndex, int chapter)> refs,
  ) async {
    if (refs.isEmpty) return;
    final service = ref.read(progressServiceProvider);
    final current = state.value ?? {};
    final updated = await service.markRead(current, refs);
    state = AsyncValue.data(updated);
    ref.read(streakProvider.notifier).recordToday();
  }

  Future<void> toggleAllChapters(int bookIndex, int totalChapters) async {
    final service = ref.read(progressServiceProvider);
    final current = state.value ?? {};
    final updated =
        await service.toggleAllChapters(current, bookIndex, totalChapters);
    state = AsyncValue.data(updated);
    // 전체 읽음 처리(미완독 → 완독)일 때만 활동일 기록.
    if ((updated[bookIndex]?.length ?? 0) == totalChapters) {
      ref.read(streakProvider.notifier).recordToday();
    }
  }
}

/// 전체 읽은 장 수
final totalReadProvider = Provider<int>((ref) {
  final data = ref.watch(progressProvider).value ?? {};
  return ProgressService.totalRead(data);
});

/// 전체 진행률 (0.0 ~ 1.0)
final overallProgressProvider = Provider<double>((ref) {
  final read = ref.watch(totalReadProvider);
  return read / BibleData.totalChapters;
});
