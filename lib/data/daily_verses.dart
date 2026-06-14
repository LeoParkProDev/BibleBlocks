import 'bible_data.dart';

/// '오늘의 말씀'에 쓰일 한 절 참조(절 번호까지 지정).
class DailyVerseRef {
  final int book;
  final int chapter;
  final int verse;
  const DailyVerseRef(this.book, this.chapter, this.verse);

  String get label => '${BibleData.books[book].name} $chapter:$verse';
}

/// 매일 한 절씩 순환하는 격려·위로 중심 큐레이션 목록.
class DailyVerses {
  DailyVerses._();

  static const List<DailyVerseRef> all = [
    DailyVerseRef(18, 23, 1), // 시편 23:1
    DailyVerseRef(18, 1, 1), // 시편 1:1
    DailyVerseRef(18, 27, 1), // 시편 27:1
    DailyVerseRef(18, 34, 8), // 시편 34:8
    DailyVerseRef(18, 37, 4), // 시편 37:4
    DailyVerseRef(18, 46, 1), // 시편 46:1
    DailyVerseRef(18, 91, 2), // 시편 91:2
    DailyVerseRef(18, 119, 105), // 시편 119:105
    DailyVerseRef(18, 121, 2), // 시편 121:2
    DailyVerseRef(19, 3, 5), // 잠언 3:5
    DailyVerseRef(19, 16, 3), // 잠언 16:3
    DailyVerseRef(4, 31, 6), // 신명기 31:6
    DailyVerseRef(5, 1, 9), // 여호수아 1:9
    DailyVerseRef(22, 40, 31), // 이사야 40:31
    DailyVerseRef(22, 41, 10), // 이사야 41:10
    DailyVerseRef(23, 29, 11), // 예레미야 29:11
    DailyVerseRef(39, 6, 33), // 마태복음 6:33
    DailyVerseRef(39, 11, 28), // 마태복음 11:28
    DailyVerseRef(42, 3, 16), // 요한복음 3:16
    DailyVerseRef(42, 14, 27), // 요한복음 14:27
    DailyVerseRef(44, 8, 28), // 로마서 8:28
    DailyVerseRef(44, 12, 12), // 로마서 12:12
    DailyVerseRef(45, 13, 4), // 고린도전서 13:4
    DailyVerseRef(47, 2, 20), // 갈라디아서 2:20
    DailyVerseRef(49, 4, 6), // 빌립보서 4:6
    DailyVerseRef(49, 4, 13), // 빌립보서 4:13
    DailyVerseRef(57, 11, 1), // 히브리서 11:1
    DailyVerseRef(58, 1, 5), // 야고보서 1:5
    DailyVerseRef(59, 5, 7), // 베드로전서 5:7
  ];

  /// 날짜별로 결정적으로 한 절을 고른다(연중 일수 기준 순환).
  static DailyVerseRef forDate(DateTime date) {
    final dayOfYear = DateTime(date.year, date.month, date.day)
        .difference(DateTime(date.year, 1, 1))
        .inDays;
    return all[dayOfYear % all.length];
  }
}
