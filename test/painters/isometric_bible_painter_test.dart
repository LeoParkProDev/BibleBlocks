import 'package:flutter_test/flutter_test.dart';
import 'package:bible_blocks/painters/isometric_bible_painter.dart';

void main() {
  // H-01
  test('H-01: 아이소메트릭 투영 함수 정확도', () {
    final painter = IsometricBiblePainter(progressData: {});
    const origin = Offset(200, 300);

    // (0,0,0)은 origin 그대로
    final p0 = painter.project(0, 0, 0, origin);
    expect(p0.dx, closeTo(origin.dx, 0.01));
    expect(p0.dy, closeTo(origin.dy, 0.01));

    // x=1 → 오른쪽 위로 이동 (dx 증가)
    final p1 = painter.project(1, 0, 0, origin);
    expect(p1.dx, greaterThan(origin.dx));

    // z=1 → 위로 이동 (dy 감소)
    final pz = painter.project(0, 0, 1, origin);
    expect(pz.dy, lessThan(origin.dy));
  });

  // H-02
  test('H-02: 전체 페이지 블록 수 = 192 (8×12×2)', () {
    expect(IsometricBiblePainter.totalPageBlocks, 192);
    expect(
      IsometricBiblePainter.bookWidth *
          IsometricBiblePainter.bookHeight *
          IsometricBiblePainter.bookDepth,
      192,
    );
  });

  // H-03
  test('H-03: 십자가 위치 판별 — 세로 바 (x=3,4 / z=2~9)', () {
    // 세로 바 내부
    expect(IsometricBiblePainter.isCrossPosition(3, 5), true);
    expect(IsometricBiblePainter.isCrossPosition(4, 2), true);
    expect(IsometricBiblePainter.isCrossPosition(3, 9), true);

    // 범위 밖
    expect(IsometricBiblePainter.isCrossPosition(3, 1), false);
    expect(IsometricBiblePainter.isCrossPosition(3, 10), false);
    expect(IsometricBiblePainter.isCrossPosition(0, 0), false);
  });

  // H-04
  test('H-04: 십자가 위치 판별 — 가로 바 (z=5,6 / x=1~6)', () {
    expect(IsometricBiblePainter.isCrossPosition(1, 5), true);
    expect(IsometricBiblePainter.isCrossPosition(6, 6), true);
    expect(IsometricBiblePainter.isCrossPosition(2, 5), true);

    // 범위 밖
    expect(IsometricBiblePainter.isCrossPosition(0, 5), false);
    expect(IsometricBiblePainter.isCrossPosition(7, 5), false);
    expect(IsometricBiblePainter.isCrossPosition(7, 6), false);
  });

  // H-05
  test('H-05: 동일 데이터 → shouldRepaint false', () {
    final data = {0: {1, 2}};
    final a = IsometricBiblePainter(progressData: data, glowAnimation: 0.5);
    final b = IsometricBiblePainter(progressData: data, glowAnimation: 0.5);
    expect(a.shouldRepaint(b), false);
  });

  // H-06
  test('H-06: 데이터 변경 시 shouldRepaint true', () {
    final a = IsometricBiblePainter(progressData: {0: {1}});
    final b = IsometricBiblePainter(progressData: {0: {1, 2}});
    expect(b.shouldRepaint(a), true);

    final c = IsometricBiblePainter(progressData: {0: {1}}, glowAnimation: 0.0);
    final d = IsometricBiblePainter(progressData: {0: {1}}, glowAnimation: 0.5);
    expect(d.shouldRepaint(c), true);
  });
}
