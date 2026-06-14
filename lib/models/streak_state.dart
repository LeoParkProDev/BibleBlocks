/// 스트릭(연속 읽기) 계산 결과를 담는 불변 값 객체.
///
/// 영속화 대상이 아니라 활동일 집합에서 매번 파생 계산되는 값이므로
/// Freezed/JSON 없이 가벼운 일반 클래스로 둔다.
class StreakState {
  /// 현재 이어가는 스트릭 길이(읽은 날 수). 끊겼으면 0.
  final int current;

  /// 역대 최장 스트릭(읽은 날 수).
  final int longest;

  /// 오늘 이미 한 장 이상 읽었는지.
  final bool isActiveToday;

  /// 가장 최근 활동일(읽은 날). 기록이 없으면 null.
  final DateTime? lastActiveDate;

  const StreakState({
    this.current = 0,
    this.longest = 0,
    this.isActiveToday = false,
    this.lastActiveDate,
  });

  @override
  bool operator ==(Object other) =>
      other is StreakState &&
      other.current == current &&
      other.longest == longest &&
      other.isActiveToday == isActiveToday &&
      other.lastActiveDate == lastActiveDate;

  @override
  int get hashCode =>
      Object.hash(current, longest, isActiveToday, lastActiveDate);

  @override
  String toString() =>
      'StreakState(current: $current, longest: $longest, '
      'isActiveToday: $isActiveToday, lastActiveDate: $lastActiveDate)';
}
