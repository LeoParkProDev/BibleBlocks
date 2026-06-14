import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/streak_state.dart';
import '../services/streak_calculator.dart';
import '../services/streak_service.dart';
import 'auth_provider.dart';

final streakServiceProvider = Provider<StreakService>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.value?.id.toString();
  return StreakService(userId: userId);
});

final streakProvider =
    AsyncNotifierProvider<StreakNotifier, StreakState>(StreakNotifier.new);

/// 스트릭은 보조 기능이다 — 로드/저장 실패가 핵심 진도 체크를 막아선 안 된다.
/// 따라서 모든 경로에서 예외를 흡수하고 기본 StreakState로 정상 동작시킨다.
class StreakNotifier extends AsyncNotifier<StreakState> {
  @override
  Future<StreakState> build() async {
    final service = ref.watch(streakServiceProvider);
    try {
      final dates = await service.loadActiveDates();
      return StreakCalculator.compute(dates, DateTime.now());
    } catch (_) {
      return const StreakState();
    }
  }

  /// 장을 읽음 처리할 때 호출. 오늘을 활동일로 기록하고 스트릭을 갱신한다.
  Future<void> recordToday() async {
    final service = ref.read(streakServiceProvider);
    try {
      final dates = await service.recordActivity(DateTime.now());
      state = AsyncValue.data(StreakCalculator.compute(dates, DateTime.now()));
    } catch (_) {
      // 무시 — 스트릭 실패는 사용자 경험을 막지 않는다.
    }
  }
}
