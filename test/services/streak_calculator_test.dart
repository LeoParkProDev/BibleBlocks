import 'package:bible_blocks/services/streak_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _d(int y, int m, int day) => DateTime(y, m, day);

void main() {
  group('StreakCalculator.compute', () {
    final today = _d(2026, 6, 14);

    test('빈 데이터 → 0 스트릭', () {
      final s = StreakCalculator.compute({}, today);
      expect(s.current, 0);
      expect(s.longest, 0);
      expect(s.isActiveToday, false);
      expect(s.lastActiveDate, isNull);
    });

    test('오늘만 읽음 → current 1, isActiveToday true', () {
      final s = StreakCalculator.compute({_d(2026, 6, 14)}, today);
      expect(s.current, 1);
      expect(s.longest, 1);
      expect(s.isActiveToday, true);
      expect(s.lastActiveDate, _d(2026, 6, 14));
    });

    test('3일 연속(오늘 포함) → current 3', () {
      final s = StreakCalculator.compute(
        {_d(2026, 6, 12), _d(2026, 6, 13), _d(2026, 6, 14)},
        today,
      );
      expect(s.current, 3);
      expect(s.longest, 3);
      expect(s.isActiveToday, true);
    });

    test('어제까지 연속, 오늘 아직 → current 유지, isActiveToday false', () {
      final s = StreakCalculator.compute(
        {_d(2026, 6, 12), _d(2026, 6, 13)},
        today,
      );
      expect(s.current, 2);
      expect(s.isActiveToday, false);
    });

    test('하루 빠짐은 은혜로 이어짐 (12 읽고 13 빠지고 14 읽음)', () {
      final s = StreakCalculator.compute(
        {_d(2026, 6, 12), _d(2026, 6, 14)},
        today,
      );
      expect(s.current, 2); // 12, 14 활동 — 13은 은혜 브리지(숫자 미포함)
      expect(s.longest, 2);
      expect(s.isActiveToday, true);
    });

    test('이틀 연속 빠지면 끊김 (11 읽고 12·13 빠지고 14 읽음)', () {
      final s = StreakCalculator.compute(
        {_d(2026, 6, 11), _d(2026, 6, 14)},
        today,
      );
      expect(s.current, 1); // 14만 현재 스팬
      expect(s.longest, 1);
    });

    test('어제 1일만 쉼(gap2)도 아직 live — 오늘 미독이지만 current 유지', () {
      // 마지막 활동 = 12, 오늘 = 14 → 13 하루만 빔
      final s = StreakCalculator.compute(
        {_d(2026, 6, 11), _d(2026, 6, 12)},
        today,
      );
      expect(s.current, 2);
      expect(s.isActiveToday, false);
    });

    test('오늘까지 이틀 이상 비면 끊김 (gap3+)', () {
      // 마지막 활동 = 11, 오늘 = 14 → 12·13 이틀 빔 → 끊김
      final s = StreakCalculator.compute(
        {_d(2026, 6, 10), _d(2026, 6, 11)},
        today,
      );
      expect(s.current, 0);
      expect(s.longest, 2);
      expect(s.lastActiveDate, _d(2026, 6, 11));
    });

    test('longest는 과거 최장 스팬을 반영', () {
      final s = StreakCalculator.compute(
        {
          _d(2026, 6, 1),
          _d(2026, 6, 2),
          _d(2026, 6, 3),
          _d(2026, 6, 4),
          _d(2026, 6, 5),
          _d(2026, 6, 14),
        },
        today,
      );
      expect(s.longest, 5);
      expect(s.current, 1);
    });

    test('월 경계를 넘는 연속도 정상 계산', () {
      final s = StreakCalculator.compute(
        {_d(2026, 5, 31), _d(2026, 6, 1), _d(2026, 6, 2)},
        _d(2026, 6, 2),
      );
      expect(s.current, 3);
      expect(s.longest, 3);
    });

    test('같은 날 시각이 달라도 하루로 취급', () {
      final s = StreakCalculator.compute(
        {
          DateTime(2026, 6, 14, 1, 0),
          DateTime(2026, 6, 14, 23, 30),
        },
        DateTime(2026, 6, 14, 12),
      );
      expect(s.current, 1);
      expect(s.isActiveToday, true);
    });
  });
}
