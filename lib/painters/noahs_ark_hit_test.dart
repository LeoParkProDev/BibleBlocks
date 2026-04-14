import 'dart:math';
import 'dart:ui';

import '../data/bible_data.dart';
import '../services/progress_service.dart';
import 'block_hit_test.dart' show BlockCoord;
import 'noahs_ark_painter.dart' show NoahsArkPainter, ArkVoxels;

class NoahsArkHitTest {
  static const double blockSize = 10.0;
  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;

  static int get _totalStructural => NoahsArkPainter.totalStructuralBlocks;

  // ---------------------------------------------------------------------------
  // Projection
  // ---------------------------------------------------------------------------

  static Offset project(double x, double y, double z, Offset origin,
      [double angle = 0]) {
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

  // ---------------------------------------------------------------------------
  // Face paths
  // ---------------------------------------------------------------------------

  static Path topFacePath(double x, double y, double z, Offset orig,
      [double angle = 0]) {
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

  static Path leftFacePath(double x, double y, double z, Offset orig,
      [double angle = 0]) {
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

  static Path rightFacePath(double x, double y, double z, Offset orig,
      [double angle = 0]) {
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

  // ---------------------------------------------------------------------------
  // Hit test — structural voxels only, front-to-back
  // ---------------------------------------------------------------------------

  static BlockCoord? hitTest(Offset scenePoint, Size canvasSize,
      [double angle = 0]) {
    final orig = origin(canvasSize);

    // Build a sorted (front-to-back) list of structural voxels.
    // Front-to-back means we test voxels with the smallest depth key first so
    // the first hit is the visually topmost block.
    final structuralVoxels =
        ArkVoxels.allVoxels.where((v) => v.isStructural).toList();

    // Depth key: same as painter but ascending = front-most first.
    // front-most = smallest (rotatedX + rotatedY - z)
    structuralVoxels.sort((a, b) {
      double depthA = _depthKey(a.x.toDouble(), a.y.toDouble(),
          a.z.toDouble(), angle);
      double depthB = _depthKey(b.x.toDouble(), b.y.toDouble(),
          b.z.toDouble(), angle);
      // Ascending: front-most (smallest depth) first
      return depthA.compareTo(depthB);
    });

    for (final v in structuralVoxels) {
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

  static double _depthKey(double x, double y, double z, double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    final cx = x + 0.5;
    final cy = y + 0.5;
    final rotatedX = cx * cosA - cy * sinA;
    final rotatedY = cx * sinA + cy * cosA;
    return rotatedX + rotatedY - (z + 0.5);
  }

  // ---------------------------------------------------------------------------
  // Index / chapter helpers
  // ---------------------------------------------------------------------------

  /// Convert a BlockCoord (x, y, z) back to structuralIndex.
  /// Looks up the voxel in the shared list.
  static int toBlockIndex(BlockCoord coord) {
    final voxel = ArkVoxels.allVoxels.firstWhere(
      (v) => v.isStructural && v.x == coord.x && v.y == coord.y && v.z == coord.z,
      orElse: () => throw ArgumentError(
          'No structural voxel at (${coord.x}, ${coord.y}, ${coord.z})'),
    );
    return voxel.structuralIndex;
  }

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

  static Offset blockTopCenter(BlockCoord coord, Size canvasSize,
      [double angle = 0]) {
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
