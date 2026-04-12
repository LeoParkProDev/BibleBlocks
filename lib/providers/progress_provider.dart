import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bible_data.dart';
import '../services/progress_service.dart';

final progressServiceProvider = Provider((ref) => ProgressService());

final progressProvider =
    AsyncNotifierProvider<ProgressNotifier, Map<int, Set<int>>>(
  ProgressNotifier.new,
);

class ProgressNotifier extends AsyncNotifier<Map<int, Set<int>>> {
  @override
  Future<Map<int, Set<int>>> build() async {
    final service = ref.read(progressServiceProvider);
    return service.loadAll();
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
