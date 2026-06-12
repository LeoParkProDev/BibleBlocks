import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:bible_blocks/data/bible_data.dart';
import 'package:bible_blocks/painters/psalm_tree_hit_test.dart';
import 'package:bible_blocks/painters/psalm_tree_painter.dart';

void main() {
  group('PsalmTree voxel list', () {
    test('voxel positions are unique (hit-test relies on this)', () {
      final voxels = treeVoxels;
      final keys = voxels.map((v) => '${v.x},${v.y},${v.z}').toSet();
      expect(keys.length, voxels.length,
          reason: 'duplicate (x,y,z) would break toBlockIndex lookup');
    });

    test('structural voxels carry a contiguous 0..N-1 structuralIndex', () {
      final structural = treeStructuralVoxels;
      final indices = structural.map((v) => v.structuralIndex).toList()..sort();
      expect(indices.first, 0);
      expect(indices.last, structural.length - 1);
      for (int i = 0; i < indices.length; i++) {
        expect(indices[i], i, reason: 'gap/duplicate in structuralIndex');
      }
    });

    test('stream voxels are non-structural (structuralIndex == -1)', () {
      final streams =
          treeVoxels.where((v) => v.type == TreeVoxelType.stream).toList();
      expect(streams, isNotEmpty, reason: '시냇물이 있어야 한다');
      for (final s in streams) {
        expect(s.structuralIndex, -1);
        expect(s.isStructural, false);
      }
    });

    test('grows in order: root/trunk early, fruit late', () {
      final structural = treeStructuralVoxels;
      // Average structuralIndex of each type — roots/trunk should come before
      // leaves, and fruit last (golden, 70%+ season).
      double avg(TreeVoxelType t) {
        final list = structural.where((v) => v.type == t).toList();
        if (list.isEmpty) return double.nan;
        return list.map((v) => v.structuralIndex).reduce((a, b) => a + b) /
            list.length;
      }

      final rootAvg = avg(TreeVoxelType.root);
      final trunkAvg = avg(TreeVoxelType.trunk);
      final leafAvg = avg(TreeVoxelType.leaf);
      final fruitAvg = avg(TreeVoxelType.fruit);

      expect(rootAvg, lessThan(leafAvg),
          reason: '뿌리는 잎보다 먼저 자란다');
      expect(trunkAvg, lessThan(leafAvg),
          reason: '줄기는 잎보다 먼저 자란다');
      expect(fruitAvg, greaterThan(leafAvg),
          reason: '열매는 잎보다 나중에 맺힌다 (철을 따라)');
    });

    test('branches are asymmetric (not left-right mirrored)', () {
      // A mirrored tree would have, for most wood cells (x,y), a matching
      // (-x,y) cell. Count how often the mirror exists; asymmetric growth
      // should leave the majority unmatched.
      final wood = treeVoxels
          .where((v) =>
              v.type == TreeVoxelType.branch || v.type == TreeVoxelType.trunk)
          .toList();
      final keys = wood.map((v) => '${v.x},${v.y},${v.z}').toSet();
      int mirrored = 0;
      for (final v in wood) {
        if (v.x == 0) continue;
        if (keys.contains('${-v.x},${v.y},${v.z}')) mirrored++;
      }
      expect(mirrored / wood.length, lessThan(0.5),
          reason: '좌우대칭이면 안 된다 — 유기적 비대칭');
    });

    test('builds deterministically from the same seed', () {
      final a = buildTreeVoxels(20260601);
      final b = buildTreeVoxels(20260601);
      expect(a.length, b.length);
      for (int i = 0; i < a.length; i++) {
        expect(a[i].x, b[i].x);
        expect(a[i].y, b[i].y);
        expect(a[i].z, b[i].z);
        expect(a[i].type, b[i].type);
        expect(a[i].structuralIndex, b[i].structuralIndex);
      }
    });

    test('all voxel coordinates are finite integers (no NaN)', () {
      for (final v in treeVoxels) {
        expect(v.x.isFinite, true);
        expect(v.y.isFinite, true);
        expect(v.z.isFinite, true);
      }
    });

    test('totalStructuralBlocks matches structural voxel count', () {
      expect(PsalmTreePainter.totalStructuralBlocks,
          treeStructuralVoxels.length);
    });
  });

  group('PsalmTreePainter', () {
    test('projection: (0,0,0) maps to origin; z up moves dy down', () {
      final painter = PsalmTreePainter(progressData: const {});
      const origin = Offset(200, 300);
      final p0 = painter.project(0, 0, 0, origin);
      expect(p0.dx, closeTo(origin.dx, 0.01));
      expect(p0.dy, closeTo(origin.dy, 0.01));
      final pz = painter.project(0, 0, 1, origin);
      expect(pz.dy, lessThan(origin.dy));
    });

    test('renders without exception at 0%, 30%, 70%, 100%', () {
      final levels = <Map<int, Set<int>>>[
        const {},
        _readFirstNChapters((BibleData.totalChapters * 0.30).round()),
        _readFirstNChapters((BibleData.totalChapters * 0.70).round()),
        _readFirstNChapters(BibleData.totalChapters),
      ];
      for (final data in levels) {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final painter = PsalmTreePainter(
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
      final painter = PsalmTreePainter(
        progressData: _readFirstNChapters(100),
        introAnimation: 0.4,
      );
      expect(
          () => painter.paint(canvas, const Size(400, 600)), returnsNormally);
      recorder.endRecording();
    });

    test('renders rotated without exception', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = PsalmTreePainter(
        progressData: _readFirstNChapters(500),
        rotationAngle: 0.7,
        introAnimation: 1.0,
      );
      expect(
          () => painter.paint(canvas, const Size(400, 600)), returnsNormally);
      recorder.endRecording();
    });

    test('progress monotonically grows the tree (more read = more filled)', () {
      // Count fully-grown structural voxels at increasing progress and assert
      // the count is non-decreasing — the tree only ever grows.
      int grownCount(int readN) {
        final total = PsalmTreePainter.totalStructuralBlocks;
        int grown = 0;
        for (final v in treeStructuralVoxels) {
          final start = (v.structuralIndex * BibleData.totalChapters / total)
              .floor();
          final end =
              ((v.structuralIndex + 1) * BibleData.totalChapters / total)
                  .floor();
          bool full = end > start;
          for (int g = start; g < end; g++) {
            if (g >= readN) {
              full = false;
              break;
            }
          }
          if (full) grown++;
        }
        return grown;
      }

      int prev = -1;
      for (final pct in [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0]) {
        final n = (BibleData.totalChapters * pct).round();
        final count = grownCount(n);
        expect(count, greaterThanOrEqualTo(prev),
            reason: '진척이 늘면 자란 블록 수는 줄 수 없다 (단조 증가)');
        prev = count;
      }
      // At 100% every structural voxel is grown.
      expect(grownCount(BibleData.totalChapters),
          PsalmTreePainter.totalStructuralBlocks);
    });

    test('shouldRepaint reflects data/animation changes', () {
      final data = {0: {1, 2}};
      final a = PsalmTreePainter(progressData: data, glowAnimation: 0.5);
      final b = PsalmTreePainter(progressData: data, glowAnimation: 0.5);
      expect(a.shouldRepaint(b), false);
      final c = PsalmTreePainter(progressData: data, glowAnimation: 0.9);
      expect(a.shouldRepaint(c), true);
    });
  });

  group('PsalmTreeHitTest', () {
    const canvasSize = Size(400, 600);

    test('hitTest hits a known voxel via its projected top center', () {
      // Pick a leaf high in the canopy (likely unobstructed from the front).
      final structural = treeStructuralVoxels.toList()
        ..sort((a, b) => b.z.compareTo(a.z));
      final top = structural.first;
      final orig = PsalmTreeHitTest.origin(canvasSize);
      final center = PsalmTreeHitTest.project(
          top.x + 0.5, top.y + 0.5, top.z + 0.5, orig);
      final hit = PsalmTreeHitTest.hitTest(center, canvasSize);
      expect(hit, isNotNull);
    });

    test('hitTest returns null for a clearly empty far corner', () {
      final hit =
          PsalmTreeHitTest.hitTest(const Offset(-9999, -9999), canvasSize);
      expect(hit, isNull);
    });

    test('toBlockIndex round-trips structural voxel coordinates', () {
      final v = treeStructuralVoxels.first;
      final idx = PsalmTreeHitTest.toBlockIndex((x: v.x, y: v.y, z: v.z));
      expect(idx, v.structuralIndex);
    });

    test('blockChapterRange covers the full bible across all blocks', () {
      final total = PsalmTreePainter.totalStructuralBlocks;
      final firstRange = PsalmTreeHitTest.blockChapterRange(0);
      final lastRange = PsalmTreeHitTest.blockChapterRange(total - 1);
      expect(firstRange.globalStart, 0);
      expect(lastRange.globalEnd, BibleData.totalChapters);
    });

    test('tooltipText is non-empty and reports read count', () {
      final range = PsalmTreeHitTest.blockChapterRange(0);
      final data = <int, Set<int>>{};
      final (b, c) = BibleData.fromGlobalIndex(range.globalStart);
      data[b] = {c};
      final text = PsalmTreeHitTest.tooltipText(0, data);
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
