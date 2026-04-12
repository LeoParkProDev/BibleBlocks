import 'package:flutter_test/flutter_test.dart';
import 'package:bible_blocks/data/bible_data.dart';

void main() {
  // A-01
  test('A-01: 성경 66권 등록 확인', () {
    expect(BibleData.books.length, 66);
    expect(BibleData.totalBooks, 66);
  });

  // A-02
  test('A-02: 구약 39권 확인', () {
    final oldBooks =
        BibleData.books.where((b) => b.testament == Testament.old).toList();
    expect(oldBooks.length, 39);
    expect(BibleData.oldTestamentBooks, 39);
  });

  // A-03
  test('A-03: 신약 27권 확인', () {
    final newBooks =
        BibleData.books.where((b) => b.testament == Testament.new_).toList();
    expect(newBooks.length, 27);
    expect(BibleData.newTestamentBooks, 27);
  });

  // A-04
  test('A-04: 전체 장 수 합계 1,189 확인', () {
    final sum = BibleData.books.fold<int>(0, (acc, b) => acc + b.chapters);
    expect(sum, 1189);
    expect(sum, BibleData.totalChapters);
  });

  // A-05
  test('A-05: bookIndex 연속성 (0~65, 중복 없음)', () {
    for (int i = 0; i < BibleData.books.length; i++) {
      expect(BibleData.books[i].index, i);
    }
  });

  // A-06
  test('A-06: chapterOffset 정확도', () {
    expect(BibleData.chapterOffset(0), 0);
    expect(BibleData.chapterOffset(1), 50); // 창세기 50장
    // 마지막 책(계시록): 전체 1189 - 22장 = 1167
    expect(BibleData.chapterOffset(65), 1189 - 22);
  });

  // A-07
  test('A-07: fromGlobalIndex 왕복 변환 (전체 1189장)', () {
    for (int g = 0; g < BibleData.totalChapters; g++) {
      final (bookIndex, chapter) = BibleData.fromGlobalIndex(g);
      final reconstructed = BibleData.chapterOffset(bookIndex) + chapter - 1;
      expect(reconstructed, g, reason: 'globalIndex=$g → book=$bookIndex ch=$chapter');
    }
  });
}
