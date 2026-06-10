import 'package:flutter_test/flutter_test.dart';
import 'package:bible_blocks/data/bible_data.dart';

void main() {
  test('fromGlobalIndex: 전 범위(0~1188)에서 선형 탐색 기준과 일치', () {
    // 기준: 단순 선형 탐색
    (int, int) reference(int globalIndex) {
      int remaining = globalIndex;
      for (final book in BibleData.books) {
        if (remaining < book.chapters) return (book.index, remaining + 1);
        remaining -= book.chapters;
      }
      return (65, 22);
    }

    for (int g = 0; g < BibleData.totalChapters; g++) {
      expect(BibleData.fromGlobalIndex(g), reference(g), reason: 'g=$g');
    }
  });

  test('chapterOffset: 누적 장수와 일치', () {
    int sum = 0;
    for (int b = 0; b < BibleData.totalBooks; b++) {
      expect(BibleData.chapterOffset(b), sum, reason: 'book=$b');
      sum += BibleData.books[b].chapters;
    }
    expect(sum, BibleData.totalChapters);
  });

  test('왕복 변환: chapterOffset + fromGlobalIndex 일관성', () {
    for (int b = 0; b < BibleData.totalBooks; b++) {
      final book = BibleData.books[b];
      for (final ch in [1, book.chapters]) {
        final g = BibleData.chapterOffset(b) + (ch - 1);
        expect(BibleData.fromGlobalIndex(g), (b, ch));
      }
    }
  });

  test('범위 밖 인덱스는 안전한 fallback', () {
    expect(BibleData.fromGlobalIndex(BibleData.totalChapters), (65, 22));
    expect(BibleData.fromGlobalIndex(99999), (65, 22));
  });
}
