import 'dart:math';
import 'dart:ui';

import '../data/bible_data.dart';
import '../services/progress_service.dart';

typedef BlockCoord = ({int x, int y, int z});

class BlockHitTest {
  static const int bookWidth = 8;
  static const int bookHeight = 12;
  static const int bookDepth = 2;
  static const int totalPageBlocks = bookWidth * bookHeight * bookDepth;

  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;
  static const double blockSize = 14.0;

  static Offset project(double x, double y, double z, Offset origin, [double angle = 0]) {
    final rotatedX = x * cos(angle) - y * sin(angle);
    final rotatedY = x * sin(angle) + y * cos(angle);
    return Offset(
      origin.dx + (rotatedX - rotatedY) * _cos30 * blockSize,
      origin.dy + (rotatedX + rotatedY) * _sin30 * blockSize - z * blockSize,
    );
  }

  static Offset origin(Size canvasSize) {
    return Offset(canvasSize.width / 2, canvasSize.height * 0.65);
  }

  static Path topFacePath(double x, double y, double z, Offset orig, [double angle = 0]) {
    final p4 = project(x, y, z + 1, orig, angle);
    final p5 = project(x + 1, y, z + 1, orig, angle);
    final p6 = project(x + 1, y + 1, z + 1, orig, angle);
    final p7 = project(x, y + 1, z + 1, orig, angle);
    return Path()
      ..moveTo(p4.dx, p4.dy)
      ..lineTo(p5.dx, p5.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p7.dx, p7.dy)
      ..close();
  }

  static Path leftFacePath(double x, double y, double z, Offset orig, [double angle = 0]) {
    final p3 = project(x, y + 1, z, orig, angle);
    final p2 = project(x + 1, y + 1, z, orig, angle);
    final p6 = project(x + 1, y + 1, z + 1, orig, angle);
    final p7 = project(x, y + 1, z + 1, orig, angle);
    return Path()
      ..moveTo(p3.dx, p3.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p7.dx, p7.dy)
      ..close();
  }

  static Path rightFacePath(double x, double y, double z, Offset orig, [double angle = 0]) {
    final p1 = project(x + 1, y, z, orig, angle);
    final p2 = project(x + 1, y + 1, z, orig, angle);
    final p6 = project(x + 1, y + 1, z + 1, orig, angle);
    final p5 = project(x + 1, y, z + 1, orig, angle);
    return Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p5.dx, p5.dy)
      ..close();
  }

  /// Front-to-back hit test: returns the first block whose face contains the point.
  /// Traversal order along x and y axes is adjusted based on angle so that the
  /// front-facing and right-facing layers are always tested first.
  static BlockCoord? hitTest(Offset scenePoint, Size canvasSize, [double angle = 0]) {
    final orig = origin(canvasSize);
    // The isometric projection maps:
    //   rotatedX = x*cos(angle) - y*sin(angle)
    //   rotatedY = x*sin(angle) + y*cos(angle)
    // screen dx ∝ (rotatedX - rotatedY), screen dy ∝ (rotatedX + rotatedY)
    //
    // For correct front-to-back ordering:
    //   y: iterate from front (smaller rotatedY contributor) to back.
    //     cos(angle) < 0  → y=bookDepth-1 is visually closest → iterate reversed.
    //   x: iterate from visual right to visual left (larger screen dx first).
    //     cos(angle) < 0  → x=0 projects to larger screen dx → iterate 0..bookWidth-1.
    final yReverse = cos(angle) < 0;
    final xReverse = cos(angle) < 0;
    for (int yi = 0; yi < bookDepth; yi++) {
      final y = yReverse ? (bookDepth - 1 - yi) : yi;
      for (int z = 0; z < bookHeight; z++) {
        for (int xi = 0; xi < bookWidth; xi++) {
          final x = xReverse ? xi : (bookWidth - 1 - xi);
          final dx = x.toDouble();
          final dy = y.toDouble();
          final dz = z.toDouble();
          if (topFacePath(dx, dy, dz, orig, angle).contains(scenePoint) ||
              rightFacePath(dx, dy, dz, orig, angle).contains(scenePoint) ||
              leftFacePath(dx, dy, dz, orig, angle).contains(scenePoint)) {
            return (x: x, y: y, z: z);
          }
        }
      }
    }
    return null;
  }

  static int toBlockIndex(BlockCoord coord) {
    return coord.y * (bookWidth * bookHeight) + coord.z * bookWidth + coord.x;
  }

  static ({int globalStart, int globalEnd}) blockChapterRange(int blockIndex) {
    final globalStart =
        (blockIndex * BibleData.totalChapters / totalPageBlocks).floor();
    final globalEnd =
        ((blockIndex + 1) * BibleData.totalChapters / totalPageBlocks).floor();
    return (globalStart: globalStart, globalEnd: globalEnd);
  }

  static String tooltipText(int blockIndex, Map<int, Set<int>> progressData) {
    final range = blockChapterRange(blockIndex);
    if (range.globalEnd <= range.globalStart) return '';

    final (startBook, startChapter) =
        BibleData.fromGlobalIndex(range.globalStart);
    final (endBook, endChapter) =
        BibleData.fromGlobalIndex(range.globalEnd - 1);

    int readCount = 0;
    final totalCount = range.globalEnd - range.globalStart;
    for (int g = range.globalStart; g < range.globalEnd; g++) {
      if (ProgressService.isGlobalIndexRead(progressData, g)) readCount++;
    }

    String chapterInfo;
    if (startBook == endBook) {
      final name = BibleData.books[startBook].name;
      if (startChapter == endChapter) {
        chapterInfo = '$name $startChapter장';
      } else {
        chapterInfo = '$name $startChapter-$endChapter장';
      }
    } else {
      final startName = BibleData.books[startBook].name;
      final endName = BibleData.books[endBook].name;
      chapterInfo = '$startName $startChapter장 ~ $endName $endChapter장';
    }

    return '$chapterInfo ($readCount/$totalCount 읽음)';
  }

  static Offset blockTopCenter(BlockCoord coord, Size canvasSize, [double angle = 0]) {
    final orig = origin(canvasSize);
    return project(
      coord.x + 0.5,
      coord.y + 0.5,
      coord.z + 1.0,
      orig,
      angle,
    );
  }
}
