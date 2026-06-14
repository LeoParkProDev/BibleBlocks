import 'package:bible_blocks/data/reading_plans.dart';
import 'package:bible_blocks/services/plan_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadingPlans 카탈로그', () {
    test('모든 계획은 날짜 수와 장 수가 양수', () {
      expect(ReadingPlans.all, isNotEmpty);
      for (final plan in ReadingPlans.all) {
        expect(plan.durationDays, greaterThan(0), reason: plan.id);
        expect(plan.totalChapters, greaterThan(0), reason: plan.id);
        // 모든 날에 최소 1장
        for (final day in plan.days) {
          expect(day.chapters, isNotEmpty, reason: '${plan.id} day ${day.day}');
        }
      }
    });

    test('잠언 31일은 31일 31장, 하루 1장', () {
      final plan = ReadingPlans.byId('proverbs-31')!;
      expect(plan.durationDays, 31);
      expect(plan.totalChapters, 31);
      expect(plan.days.every((d) => d.chapters.length == 1), isTrue);
    });

    test('불안할 때 시편 7일은 7일 7장', () {
      final plan = ReadingPlans.byId('psalms-anxiety-7')!;
      expect(plan.durationDays, 7);
      expect(plan.totalChapters, 7);
    });

    test('byId 미존재 id는 null', () {
      expect(ReadingPlans.byId('nope'), isNull);
    });
  });

  group('computePlanStatus', () {
    final plan = ReadingPlans.byId('psalms-anxiety-7')!; // 시편 23,27,34,42,46,91,121

    test('아무것도 안 읽음 → 완료 0, 현재 Day 1', () {
      final status = computePlanStatus(plan, {});
      expect(status.completedDays, 0);
      expect(status.currentDay?.day, 1);
      expect(status.isFinished, false);
      expect(status.progress, 0);
    });

    test('Day 1(시편 23편) 읽음 → 완료 1, 현재 Day 2', () {
      final status = computePlanStatus(plan, {
        18: {23},
      });
      expect(status.completedDays, 1);
      expect(status.currentDay?.day, 2);
    });

    test('비순차로 Day 2만 읽어도 완료 1, 현재는 여전히 Day 1', () {
      final status = computePlanStatus(plan, {
        18: {27}, // Day 2
      });
      expect(status.completedDays, 1);
      expect(status.currentDay?.day, 1); // 가장 이른 미완료
    });

    test('전부 읽음 → 완주(finished)', () {
      final status = computePlanStatus(plan, {
        18: {23, 27, 34, 42, 46, 91, 121},
      });
      expect(status.completedDays, 7);
      expect(status.isFinished, true);
      expect(status.currentDay, isNull);
      expect(status.progress, 1.0);
    });
  });
}
