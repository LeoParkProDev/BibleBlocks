import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/data/bible_data.dart';
import 'package:bible_blocks/services/progress_service.dart';
import 'package:bible_blocks/painters/isometric_bible_painter.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // J-01
  test('J-01: 1장짜리 책 완독 토글 (오바댜 index=30, 1장)', () async {
    final service = ProgressService();
    final book = BibleData.books[30]; // 오바댜
    expect(book.name, '오바댜');
    expect(book.chapters, 1);

    // 체크 → 완독
    var data = await service.toggleChapter({}, 30, 1);
    expect(data[30], {1});
    expect(ProgressService.totalRead(data), 1);

    // 해제 → 미완독
    data = await service.toggleChapter(data, 30, 1);
    expect(data.containsKey(30), false);
  });

  // J-02
  test('J-02: 최대 장 수 책 (시편 150장) 전체 체크/해제', () async {
    final service = ProgressService();
    final psalms = BibleData.books[18]; // 시편
    expect(psalms.name, '시편');
    expect(psalms.chapters, 150);

    var data = <int, Set<int>>{};
    for (int ch = 1; ch <= 150; ch++) {
      data = await service.toggleChapter(data, 18, ch);
    }
    expect(data[18]!.length, 150);
    expect(ProgressService.totalRead(data), 150);

    // 전부 해제
    for (int ch = 1; ch <= 150; ch++) {
      data = await service.toggleChapter(data, 18, ch);
    }
    expect(data.containsKey(18), false);
    expect(ProgressService.totalRead(data), 0);
  });

  // J-03
  test('J-03: 전체 1,189장 완독 시 isComplete 플래그', () {
    // 모든 책의 모든 장을 읽은 상태 생성
    final data = <int, Set<int>>{};
    for (final book in BibleData.books) {
      data[book.index] = Set.from(
        List.generate(book.chapters, (i) => i + 1),
      );
    }
    expect(ProgressService.totalRead(data), 1189);

    final painter = IsometricBiblePainter(progressData: data);
    expect(painter.isComplete, true);

    // 1장 빼면 미완독
    final incomplete = Map<int, Set<int>>.from(data);
    incomplete[0] = Set.from(data[0]!)..remove(1);
    final painter2 = IsometricBiblePainter(progressData: incomplete);
    expect(painter2.isComplete, false);
  });

  // J-04
  test('J-04: 전역 인덱스 경계값 — 0(창세기1장), 1188(계시록22장)', () {
    final (b0, c0) = BibleData.fromGlobalIndex(0);
    expect(b0, 0);
    expect(c0, 1);

    final (b1188, c1188) = BibleData.fromGlobalIndex(1188);
    expect(b1188, 65);
    expect(c1188, 22);
  });

  // J-05
  test('J-05: 범위 초과 전역 인덱스 → fallback (65, 22)', () {
    final (b, c) = BibleData.fromGlobalIndex(1189);
    expect(b, 65);
    expect(c, 22);

    final (b2, c2) = BibleData.fromGlobalIndex(9999);
    expect(b2, 65);
    expect(c2, 22);
  });
}
