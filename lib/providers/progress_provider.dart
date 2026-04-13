import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bible_data.dart';
import '../services/progress_service.dart';
import 'auth_provider.dart';

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
