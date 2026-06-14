import '../data/reading_plans.dart';

/// 진도 데이터로부터 파생된 읽기 계획 진행 상태.
class PlanStatus {
  /// 모든 장을 읽은(완료된) 날 수.
  final int completedDays;

  /// 전체 일수.
  final int totalDays;

  /// 현재 읽어야 할 날(가장 이른 미완료 날). 전부 완료면 null.
  final ReadingPlanDay? currentDay;

  const PlanStatus({
    required this.completedDays,
    required this.totalDays,
    required this.currentDay,
  });

  bool get isFinished => currentDay == null;
  double get progress => totalDays == 0 ? 0 : completedDays / totalDays;
}

/// 계획의 각 날이 진도 데이터상 모두 읽혔는지로 완료 여부를 계산하는 순수 함수.
///
/// 별도의 "완료 표시" 저장 없이 실제 읽음 데이터에서 파생하므로
/// 진도/스트릭/3D 블록과 항상 일관된다.
PlanStatus computePlanStatus(ReadingPlan plan, Map<int, Set<int>> progress) {
  bool dayComplete(ReadingPlanDay day) {
    for (final ref in day.chapters) {
      if (!(progress[ref.book]?.contains(ref.chapter) ?? false)) return false;
    }
    return day.chapters.isNotEmpty;
  }

  var completed = 0;
  ReadingPlanDay? current;
  for (final day in plan.days) {
    if (dayComplete(day)) {
      completed++;
    } else {
      current ??= day;
    }
  }

  return PlanStatus(
    completedDays: completed,
    totalDays: plan.durationDays,
    currentDay: current,
  );
}
