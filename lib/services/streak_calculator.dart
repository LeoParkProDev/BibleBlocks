import '../models/streak_state.dart';

/// 활동일(읽은 날) 집합으로부터 스트릭을 계산하는 순수 함수.
///
/// 은혜(grace) 규칙: **하루 빠짐은 봐주되, 이틀 연속 빠지면 끊긴다.**
/// 즉 두 활동일 사이에 빠진 날이 1일이면 같은 스팬으로 이어지고(은혜 브리지),
/// 2일 이상이면 스팬이 끊긴다. 빠진 날은 스트릭 숫자에 포함되지 않는다
/// (읽은 날만 카운트 — 정직한 "읽은 날 수").
///
/// "오늘"을 아직 읽지 않아도 어제 읽었으면(또는 그제 읽고 어제 1일만 쉬었으면)
/// 스트릭은 살아있는 것으로 본다. 오늘까지 비는 날이 2일 이상이면 끊긴 것.
class StreakCalculator {
  /// DST 영향을 피하기 위해 UTC 기준 날짜로 정규화한 '에폭 일(day number)'.
  static int _dayNum(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  static DateTime _fromDayNum(int n) {
    final u = DateTime.fromMillisecondsSinceEpoch(
      n * Duration.millisecondsPerDay,
      isUtc: true,
    );
    return DateTime(u.year, u.month, u.day);
  }

  static StreakState compute(Set<DateTime> activeDates, DateTime today) {
    if (activeDates.isEmpty) return const StreakState();

    final t = _dayNum(today);
    final days = activeDates.map(_dayNum).toSet().toList()..sort();

    // 스팬 분할: 인접 활동일 간격이 2일 이하(=빠진 날 1일 이하)면 같은 스팬.
    final spanCounts = <int>[]; // 각 스팬의 활동일 수
    var spanEnds = <int>[]; // 각 스팬의 마지막 활동일
    var count = 1;
    var prev = days.first;
    for (var i = 1; i < days.length; i++) {
      final day = days[i];
      if (day - prev <= 2) {
        count++;
      } else {
        spanCounts.add(count);
        spanEnds.add(prev);
        count = 1;
      }
      prev = day;
    }
    spanCounts.add(count);
    spanEnds.add(prev);

    var longest = 0;
    for (final c in spanCounts) {
      if (c > longest) longest = c;
    }

    final lastActive = days.last; // 마지막 스팬의 끝
    // 오늘까지 빈 날이 1일 이하(t - lastActive <= 2)면 현재 스팬이 살아있다.
    final current = (t - lastActive <= 2) ? spanCounts.last : 0;

    return StreakState(
      current: current,
      longest: longest,
      isActiveToday: days.contains(t),
      lastActiveDate: _fromDayNum(lastActive),
    );
  }
}
