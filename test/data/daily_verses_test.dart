import 'package:bible_blocks/data/bible_data.dart';
import 'package:bible_blocks/data/daily_verses.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyVerses', () {
    test('목록이 비어있지 않고 모든 참조가 유효한 범위', () {
      expect(DailyVerses.all, isNotEmpty);
      for (final v in DailyVerses.all) {
        expect(v.book, inInclusiveRange(0, BibleData.totalBooks - 1));
        expect(v.chapter, inInclusiveRange(1, BibleData.books[v.book].chapters));
        expect(v.verse, greaterThan(0));
      }
    });

    test('forDate는 결정적 — 같은 날짜는 같은 절', () {
      final a = DailyVerses.forDate(DateTime(2026, 6, 14));
      final b = DailyVerses.forDate(DateTime(2026, 6, 14, 23, 59));
      expect(a.label, b.label);
    });

    test('연중 일수에 따라 순환', () {
      final jan1 = DailyVerses.forDate(DateTime(2026, 1, 1));
      expect(jan1.label, DailyVerses.all[0].label);
      final jan2 = DailyVerses.forDate(DateTime(2026, 1, 2));
      expect(jan2.label, DailyVerses.all[1].label);
    });

    test('label 형식은 "책 장:절"', () {
      expect(const DailyVerseRef(18, 23, 1).label, '시편 23:1');
    });
  });
}
