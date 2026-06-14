import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reading_plans.dart';
import '../models/plan_progress.dart';
import '../services/plan_service.dart';
import '../services/plan_status.dart';
import 'auth_provider.dart';
import 'progress_provider.dart';

final planServiceProvider = Provider<PlanService>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.value?.id.toString();
  return PlanService(userId: userId);
});

final activePlanProvider =
    AsyncNotifierProvider<ActivePlanNotifier, PlanProgress?>(
  ActivePlanNotifier.new,
);

class ActivePlanNotifier extends AsyncNotifier<PlanProgress?> {
  @override
  Future<PlanProgress?> build() async {
    final service = ref.watch(planServiceProvider);
    try {
      return await service.load();
    } catch (_) {
      return null;
    }
  }

  Future<void> start(String planId) async {
    final service = ref.read(planServiceProvider);
    final progress = await service.start(planId);
    state = AsyncValue.data(progress);
  }

  Future<void> stop() async {
    final service = ref.read(planServiceProvider);
    await service.clear();
    state = const AsyncValue.data(null);
  }
}

/// 현재 활성 계획의 정의(없으면 null).
final activePlanDefinitionProvider = Provider<ReadingPlan?>((ref) {
  final progress = ref.watch(activePlanProvider).value;
  if (progress == null) return null;
  return ReadingPlans.byId(progress.planId);
});

/// 활성 계획의 진행 상태(진도 데이터에서 파생).
final activePlanStatusProvider = Provider<PlanStatus?>((ref) {
  final plan = ref.watch(activePlanDefinitionProvider);
  if (plan == null) return null;
  final progress = ref.watch(progressProvider).value ?? {};
  return computePlanStatus(plan, progress);
});
