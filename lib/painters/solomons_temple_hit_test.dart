import 'dart:math';
import 'dart:ui';

import '../data/bible_data.dart';
import '../services/progress_service.dart';
import 'block_hit_test.dart' show BlockCoord;
import 'solomons_temple_painter.dart' show TempleVoxel, templeVoxels;

/// Hit-test utilities for the Solomon's Temple isometric view.
/// Mirrors the interface of [BlockHitTest] but operates on the temple voxel
/// grid instead of the book page-block grid.
class SolomonsTempleHitTest {
  static const double blockSize = 8.0;

  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;

  // -------------------------------------------------------------------------
  // Projection — identical formula to IsometricBiblePainter / BlockHitTest
  // -------------------------------------------------------------------------

  static Offset project(
      double x, double y, double z, Offset orig, [double angle = 0]) {
    final rotatedX = x * cos(angle) - y * sin(angle);
    final rotatedY = x * sin(angle) + y * cos(angle);
    return Offset(
      orig.dx + (rotatedX - rotatedY) * _cos30 * blockSize,
      orig.dy + (rotatedX + rotatedY) * _sin30 * blockSize - z * blockSize,
    );
  }

  static Offset origin(Size canvasSize) {
    return Offset(canvasSize.width / 2, canvasSize.height * 0.65);
  }

  // -------------------------------------------------------------------------
  // Face paths
  // -------------------------------------------------------------------------

  static Path topFacePath(
      double x, double y, double z, Offset orig, [double angle = 0]) {
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

  static Path leftFacePath(
      double x, double y, double z, Offset orig, [double angle = 0]) {
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

  static Path rightFacePath(
      double x, double y, double z, Offset orig, [double angle = 0]) {
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

  // -------------------------------------------------------------------------
  // Hit test — front-to-back (reverse paint order)
  // -------------------------------------------------------------------------

  /// Returns the [BlockCoord] of the topmost voxel that contains [scenePoint],
  /// or null if no voxel is hit. Uses [x/y/z] directly from the voxel's world
  /// coordinates so the returned coord can be matched against painter state.
  static BlockCoord? hitTest(
      Offset scenePoint, Size canvasSize, [double angle = 0]) {
    final orig = origin(canvasSize);

    // Build back-to-front sorted list (same as painter) then reverse it so we
    // test front-most voxels first.
    final voxels = List<TempleVoxel>.from(templeVoxels);
    final cosA = cos(angle);
    final sinA = sin(angle);
    voxels.sort((a, b) {
      final depthA =
          (a.x * cosA - a.y * sinA) + (a.x * sinA + a.y * cosA);
      final depthB =
          (b.x * cosA - b.y * sinA) + (b.x * sinA + b.y * cosA);
      final cmp = depthA.compareTo(depthB);
      if (cmp != 0) return cmp;
      return a.z.compareTo(b.z);
    });

    // Iterate front-to-back (reversed sort order)
    for (int i = voxels.length - 1; i >= 0; i--) {
      final v = voxels[i];
      final dx = v.x.toDouble();
      final dy = v.y.toDouble();
      final dz = v.z.toDouble();

      if (topFacePath(dx, dy, dz, orig, angle).contains(scenePoint) ||
          rightFacePath(dx, dy, dz, orig, angle).contains(scenePoint) ||
          leftFacePath(dx, dy, dz, orig, angle).contains(scenePoint)) {
        return (x: v.x, y: v.y, z: v.z);
      }
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Index helpers
  // -------------------------------------------------------------------------

  /// Converts a [BlockCoord] (world voxel coordinates) to a structural index.
  /// Returns -1 if no matching voxel is found.
  static int toBlockIndex(BlockCoord coord) {
    final voxels = templeVoxels;
    for (final v in voxels) {
      if (v.x == coord.x && v.y == coord.y && v.z == coord.z) {
        return v.structuralIndex;
      }
    }
    return -1;
  }

  static int get _totalStructural => templeVoxels.length;

  static ({int globalStart, int globalEnd}) blockChapterRange(int blockIndex) {
    final total = _totalStructural;
    final globalStart =
        (blockIndex * BibleData.totalChapters / total).floor();
    final globalEnd =
        ((blockIndex + 1) * BibleData.totalChapters / total).floor();
    return (globalStart: globalStart, globalEnd: globalEnd);
  }

  static String tooltipText(
      int blockIndex, Map<int, Set<int>> progressData) {
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

  static Offset blockTopCenter(
      BlockCoord coord, Size canvasSize, [double angle = 0]) {
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
