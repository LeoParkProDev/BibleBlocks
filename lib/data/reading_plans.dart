import 'bible_data.dart';

/// 읽기 계획에서 가리키는 한 장(章) 참조.
class ChapterRef {
  final int book; // bookIndex (0~65)
  final int chapter; // 1-based
  const ChapterRef(this.book, this.chapter);

  String get label => '${BibleData.books[book].name} $chapter장';
}

/// 계획의 하루치 분량.
class ReadingPlanDay {
  final int day; // 1-based
  final List<ChapterRef> chapters;
  const ReadingPlanDay({required this.day, required this.chapters});
}

/// 읽기 계획 정의.
class ReadingPlan {
  final String id;
  final String title;
  final String subtitle;
  final List<ReadingPlanDay> days;

  const ReadingPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.days,
  });

  int get durationDays => days.length;
  int get totalChapters =>
      days.fold(0, (sum, d) => sum + d.chapters.length);
}

/// 앱에 내장된 추천 읽기 계획 카탈로그.
///
/// 리서치 결론대로 완독률이 가장 높은 단기 계획(7~31일)을 중심으로 구성한다.
class ReadingPlans {
  ReadingPlans._();

  /// [bookStart]~[bookEnd] 책의 모든 장을 순서대로 펼친다.
  static List<ChapterRef> _range(int bookStart, int bookEnd) {
    final list = <ChapterRef>[];
    for (var b = bookStart; b <= bookEnd; b++) {
      for (var ch = 1; ch <= BibleData.books[b].chapters; ch++) {
        list.add(ChapterRef(b, ch));
      }
    }
    return list;
  }

  /// 장 목록을 [dayCount]일로 최대한 고르게 분할(앞쪽에 1장 더 실릴 수 있음).
  static List<ReadingPlanDay> _split(List<ChapterRef> all, int dayCount) {
    final days = <ReadingPlanDay>[];
    final n = all.length;
    var start = 0;
    for (var i = 0; i < dayCount; i++) {
      final remainingDays = dayCount - i;
      final remainingCh = n - start;
      final take = remainingDays > 0 ? (remainingCh / remainingDays).ceil() : 0;
      final end = (start + take).clamp(0, n);
      days.add(ReadingPlanDay(day: i + 1, chapters: all.sublist(start, end)));
      start = end;
    }
    return days;
  }

  /// 한 장씩 하루치로 만든 계획(예: 잠언 31일, 큐레이션 시편).
  static List<ReadingPlanDay> _oneEach(List<ChapterRef> refs) {
    return [
      for (var i = 0; i < refs.length; i++)
        ReadingPlanDay(day: i + 1, chapters: [refs[i]]),
    ];
  }

  static final List<ReadingPlan> all = [
    ReadingPlan(
      id: 'psalms-anxiety-7',
      title: '불안할 때 읽는 시편 7일',
      subtitle: '하루 한 편, 마음을 다스리는 일주일',
      days: _oneEach(
        const [23, 27, 34, 42, 46, 91, 121]
            .map((c) => ChapterRef(18, c))
            .toList(),
      ),
    ),
    ReadingPlan(
      id: 'gospels-21',
      title: '복음서 21일',
      subtitle: '예수님의 생애 — 마태·마가·누가·요한',
      days: _split(_range(39, 42), 21),
    ),
    ReadingPlan(
      id: 'proverbs-31',
      title: '잠언 31일',
      subtitle: '하루 한 장, 한 달의 지혜',
      days: _oneEach(_range(19, 19)),
    ),
    ReadingPlan(
      id: 'psalms-30',
      title: '시편 한 달',
      subtitle: '시편 150편을 30일에',
      days: _split(_range(18, 18), 30),
    ),
    ReadingPlan(
      id: 'nt-90',
      title: '신약 90일',
      subtitle: '마태복음부터 요한계시록까지',
      days: _split(_range(39, 65), 90),
    ),
  ];

  static ReadingPlan? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
