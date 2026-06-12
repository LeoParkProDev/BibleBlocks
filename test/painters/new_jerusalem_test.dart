import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:bible_blocks/data/bible_data.dart';
import 'package:bible_blocks/painters/new_jerusalem_hit_test.dart';
import 'package:bible_blocks/painters/new_jerusalem_painter.dart';

void main() {
  group('NewJerusalem voxel list', () {
    test('voxel positions are unique (hit-test relies on this)', () {
      final voxels = cityVoxels;
      final keys = voxels.map((v) => '${v.x},${v.y},${v.z}').toSet();
      expect(keys.length, voxels.length,
          reason: 'duplicate (x,y,z) would break toBlockIndex lookup');
    });

    test('structuralIndex is a contiguous 0..N-1 sequence', () {
      final voxels = cityVoxels;
      final indices = voxels.map((v) => v.structuralIndex).toList()..sort();
      expect(indices.first, 0);
      expect(indices.last, voxels.length - 1);
      for (int i = 0; i < indices.length; i++) {
        expect(indices[i], i);
      }
    });

    test('contains all narrative stages', () {
      final types = cityVoxels.map((v) => v.type).toSet();
      expect(types.contains(CityVoxelType.plaza), true);
      expect(types.contains(CityVoxelType.wall), true);
      expect(types.contains(CityVoxelType.gate), true);
      expect(types.contains(CityVoxelType.jewel), true);
      expect(types.contains(CityVoxelType.tower), true);
      expect(types.contains(CityVoxelType.temple), true);
      expect(types.contains(CityVoxelType.spire), true);
    });

    test('totalStructuralBlocks matches voxel count', () {
      expect(NewJerusalemPainter.totalStructuralBlocks, cityVoxels.length);
    });
  });

  group('NewJerusalemPainter', () {
    test('projection: (0,0,0) maps to origin', () {
      final painter = NewJerusalemPainter(progressData: const {});
      const origin = Offset(200, 300);
      final p0 = painter.project(0, 0, 0, origin);
      expect(p0.dx, closeTo(origin.dx, 0.01));
      expect(p0.dy, closeTo(origin.dy, 0.01));

      // z up moves dy down
      final pz = painter.project(0, 0, 1, origin);
      expect(pz.dy, lessThan(origin.dy));
    });

    test('renders without exception at 0%, 50%, 100%', () {
      final progressLevels = <Map<int, Set<int>>>[
        const {},
        _readFirstNChapters(BibleData.totalChapters ~/ 2),
        _readFirstNChapters(BibleData.totalChapters),
      ];
      for (final data in progressLevels) {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final painter = NewJerusalemPainter(
          progressData: data,
          glowAnimation: 0.5,
          introAnimation: 1.0,
        );
        expect(() => painter.paint(canvas, const Size(400, 600)),
            returnsNormally);
        recorder.endRecording();
      }
    });

    test('renders mid-intro animation without exception', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = NewJerusalemPainter(
        progressData: _readFirstNChapters(100),
        introAnimation: 0.4,
      );
      expect(
          () => painter.paint(canvas, const Size(400, 600)), returnsNormally);
      recorder.endRecording();
    });

    test('shouldRepaint reflects data/animation changes', () {
      final data = {0: {1, 2}};
      final a = NewJerusalemPainter(progressData: data, glowAnimation: 0.5);
      final b = NewJerusalemPainter(progressData: data, glowAnimation: 0.5);
      expect(a.shouldRepaint(b), false);

      final c = NewJerusalemPainter(progressData: data, glowAnimation: 0.9);
      expect(a.shouldRepaint(c), true);
    });
  });

  group('NewJerusalemHitTest', () {
    const canvasSize = Size(400, 600);

    test('hitTest hits a known voxel via its projected top center', () {
      // Pick the spire (topmost, unobstructed) and tap its top-center.
      final spire =
          cityVoxels.firstWhere((v) => v.type == CityVoxelType.spire);
      final orig = NewJerusalemHitTest.origin(canvasSize);
      final center = NewJerusalemHitTest.project(
          spire.x + 0.5, spire.y + 0.5, spire.z + 0.5, orig);
      final hit = NewJerusalemHitTest.hitTest(center, canvasSize);
      expect(hit, isNotNull);
    });

    test('hitTest returns null for a clearly empty far corner', () {
      final hit = NewJerusalemHitTest.hitTest(
          const Offset(-9999, -9999), canvasSize);
      expect(hit, isNull);
    });

    test('toBlockIndex round-trips voxel coordinates', () {
      final v = cityVoxels.first;
      final idx = NewJerusalemHitTest.toBlockIndex((x: v.x, y: v.y, z: v.z));
      expect(idx, v.structuralIndex);
    });

    test('blockChapterRange covers the full bible across all blocks', () {
      final total = cityVoxels.length;
      final firstRange = NewJerusalemHitTest.blockChapterRange(0);
      final lastRange = NewJerusalemHitTest.blockChapterRange(total - 1);
      expect(firstRange.globalStart, 0);
      expect(lastRange.globalEnd, BibleData.totalChapters);
    });

    test('tooltipText is non-empty and reports read count', () {
      final range = NewJerusalemHitTest.blockChapterRange(0);
      final data = <int, Set<int>>{};
      // mark first chapter of the block read
      final (b, c) = BibleData.fromGlobalIndex(range.globalStart);
      data[b] = {c};
      final text = NewJerusalemHitTest.tooltipText(0, data);
      expect(text, contains('읽음'));
    });
  });
}

/// Marks the first [n] global chapter indices (0-based) as read.
Map<int, Set<int>> _readFirstNChapters(int n) {
  final data = <int, Set<int>>{};
  for (int g = 0; g < n; g++) {
    final (b, c) = BibleData.fromGlobalIndex(g);
    data.putIfAbsent(b, () => <int>{}).add(c);
  }
  return data;
}
