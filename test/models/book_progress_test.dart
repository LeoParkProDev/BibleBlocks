import 'package:flutter_test/flutter_test.dart';
import 'package:bible_blocks/models/book_progress.dart';

void main() {
  // B-01
  test('B-01: Freezed 생성 — 기본 팩토리 정상 동작', () {
    final now = DateTime.now();
    final bp = BookProgress(bookIndex: 0, updatedAt: now);
    expect(bp.bookIndex, 0);
    expect(bp.chapters, isEmpty);
    expect(bp.updatedAt, now);
  });

  // B-02
  test('B-02: JSON 직렬화 왕복', () {
    final bp = BookProgress(
      bookIndex: 5,
      chapters: {1, 3, 5},
      updatedAt: DateTime(2026, 4, 13),
    );
    final json = bp.toJson();
    final restored = BookProgress.fromJson(json);
    expect(restored, bp);
  });

  // B-03
  test('B-03: copyWith로 chapters 업데이트', () {
    final bp = BookProgress(bookIndex: 0, updatedAt: DateTime.now());
    final updated = bp.copyWith(chapters: {1, 2, 3});
    expect(updated.chapters, {1, 2, 3});
    expect(updated.bookIndex, 0);
  });
}
