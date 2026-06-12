import 'dart:math';
import 'package:flutter/material.dart';

import '../data/bible_data.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import 'block_hit_test.dart';

// ---------------------------------------------------------------------------
// Psalm Tree — "시냇가의 나무" (Psalm 1:3)
//
//   "그는 시냇가에 심은 나무가 철을 따라 열매를 맺으며
//    그 잎사귀가 마르지 아니함 같으니"
//
// The tree IS the reader. As chapters are read the tree GROWS in its natural
// order: 씨앗/뿌리 -> 줄기 -> 가지(비대칭·유기적) -> 잎(어림→진녹) -> 황금 열매(70%+)
// + 따뜻한 빛이 강해진다. A 시냇물(life stream) flows past the base and its
// banks green up as progress rises. Unread parts show as a ghost wireframe so
// the full grown silhouette is always visible — even at 0%.
//
// Ported from tool/tree_map.html (the design source of truth):
//   - mulberry32 seeded PRNG -> deterministic organic, ASYMMETRIC branches
//   - recursive branch growth with seeded azimuth/elevation jitter
//   - canopy-fill leaf schedule (lower/inner first, higher/outer last)
//   - golden fruit only in the late season among outer/higher leaves
//
// Integration matches NewJerusalemPainter: a voxel list + per-voxel
// `structuralIndex` assigned in *growth order* (= birth order). Reading
// progress maps linearly to structuralIndex, so the tree fills exactly in the
// order it would grow. An `occupied` guard guarantees unique (x,y,z) cells so
// the hit-test lookup stays unambiguous. The 시냇물 voxels are non-structural
// (always rendered, animated shimmer) and are NOT chapter-mapped.
// ---------------------------------------------------------------------------

enum TreeVoxelType {
  root,
  trunk,
  branch,
  leaf,
  fruit,
  stream, // non-structural — always present, shimmering brook
}

class TreeVoxel {
  final int x;
  final int y;
  final int z;
  final TreeVoxelType type;

  /// Sequential index among *structural* voxels (chapter-mapped), in growth
  /// order. Stream voxels carry -1 (non-structural).
  final int structuralIndex;

  /// Per-voxel deterministic seed (0..999) for color/shimmer variance.
  final int seed;

  const TreeVoxel({
    required this.x,
    required this.y,
    required this.z,
    required this.type,
    required this.structuralIndex,
    required this.seed,
  });

  bool get isStructural => type != TreeVoxelType.stream;
}

// ---------------------------------------------------------------------------
// Seeded PRNG (mulberry32) — identical to the HTML preview for matching shape.
// ---------------------------------------------------------------------------
class _Mulberry32 {
  int _a;
  _Mulberry32(int seed) : _a = seed & 0xFFFFFFFF;

  double next() {
    _a = (_a + 0x6D2B79F5) & 0xFFFFFFFF;
    int t = _a;
    t = (_imul(t ^ (t >>> 15), 1 | t)) & 0xFFFFFFFF;
    t = (t + (_imul(t ^ (t >>> 7), 61 | t) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    t = (t ^ (t >>> 14)) & 0xFFFFFFFF;
    return t / 4294967296.0;
  }

  static int _imul(int a, int b) {
    // 32-bit multiply matching JS Math.imul semantics.
    final result = (a & 0xFFFFFFFF) * (b & 0xFFFFFFFF);
    return result.toUnsigned(32).toSigned(32);
  }
}

/// Internal mutable accumulator while voxelizing the skeleton.
class _RawVoxel {
  final int x;
  final int y;
  final int z;
  TreeVoxelType type;
  double birth; // 0..1 growth fraction at which this voxel appears
  int seed;
  _RawVoxel(this.x, this.y, this.z, this.type, this.birth, this.seed);
}

const Map<TreeVoxelType, int> _prio = {
  TreeVoxelType.root: 3,
  TreeVoxelType.trunk: 4,
  TreeVoxelType.branch: 3,
  TreeVoxelType.leaf: 1,
  TreeVoxelType.fruit: 2,
};

/// Builds the full tree voxel list in growth (birth) order and assigns a
/// contiguous structuralIndex to every structural voxel. Stream voxels are
/// appended with structuralIndex = -1.
List<TreeVoxel> buildTreeVoxels([int seedValue = 20260601]) {
  final rnd = _Mulberry32(seedValue);
  final cells = <String, _RawVoxel>{};

  String key(int x, int y, int z) => '$x,$y,$z';

  void put(double fx, double fy, double fz, TreeVoxelType type, double birth) {
    final x = fx.round();
    final y = fy.round();
    final z = fz.round();
    final k = key(x, y, z);
    final ex = cells[k];
    final s = (rnd.next() * 1000).floor();
    if (ex != null) {
      // wood beats leaf; earlier birth wins at equal priority.
      if (_prio[type]! > _prio[ex.type]! ||
          (_prio[type] == _prio[ex.type] && birth < ex.birth)) {
        ex.type = type;
        ex.birth = birth;
        ex.seed = s;
      }
      return;
    }
    cells[k] = _RawVoxel(x, y, z, type, birth, s);
  }

  // -------------------------------------------------------------------------
  // ROOTS — appear earliest, spread underground (z<0). Band 0.02 .. 0.16.
  // -------------------------------------------------------------------------
  const rootCount = 5;
  for (int r = 0; r < rootCount; r++) {
    final ang = (r / rootCount) * pi * 2 + rnd.next() * 0.8;
    double rx = 0, ry = 0, rz = 0;
    final len = 3 + (rnd.next() * 3).floor();
    for (int s = 0; s < len; s++) {
      rx += cos(ang) * (0.7 + rnd.next() * 0.4);
      ry += sin(ang) * (0.7 + rnd.next() * 0.4);
      rz -= 0.55 + rnd.next() * 0.35;
      final birth = 0.02 + (s / len) * 0.14 + r * 0.004;
      put(rx, ry, rz, TreeVoxelType.root, birth);
    }
  }

  // Thick-column stamp for wood (trunk/branch).
  void stamp(double x, double y, double z, double radius, TreeVoxelType type,
      double birth) {
    final R = max(0, radius.ceil());
    for (int dx = -R; dx <= R; dx++) {
      for (int dy = -R; dy <= R; dy++) {
        final d = sqrt((dx * dx + dy * dy).toDouble());
        if (d <= radius + 0.25) {
          final shell = radius > 0.6 ? (d / (radius + 0.5)) * 0.06 : 0.0;
          put(x + dx, y + dy, z, type, birth + shell);
        }
      }
    }
  }

  // Canopy-fill leaf schedule (lower/inner first, higher/outer last).
  const canopyZ0 = 5.0, canopyZ1 = 19.0, canopyR = 9.0;
  const fillLo = 0.27, fillHi = 0.80;
  double leafBirth(double lx, double ly, double lz, double jitter) {
    final hN = min(1.0, max(0.0, (lz - canopyZ0) / (canopyZ1 - canopyZ0)));
    final rN = min(1.0, sqrt(lx * lx + ly * ly) / canopyR);
    final sched = hN * 0.55 + rN * 0.45;
    return min(0.90, fillLo + (fillHi - fillLo) * sched + jitter);
  }

  void leafCluster(double cx, double cy, double cz, double size) {
    final n = (size * size * 3.2).round();
    for (int i = 0; i < n; i++) {
      final u = rnd.next(), v = rnd.next(), w = rnd.next();
      final rr = pow(rnd.next(), 0.55).toDouble() * size; // denser toward center
      final th = u * pi * 2, ph = acos(2 * v - 1);
      final lx = cx + sin(ph) * cos(th) * rr * 1.05;
      final ly = cy + sin(ph) * sin(th) * rr * 1.05;
      final lz = cz + cos(ph) * rr * 0.85 + (w - 0.3) * 0.6;
      final birth = leafBirth(lx, ly, lz, (rnd.next() - 0.4) * 0.06);
      put(lx, ly, lz, TreeVoxelType.leaf, birth);
    }
  }

  // Recursive, ASYMMETRIC branch growth (seeded jitter — never mirrored).
  ({double x, double y, double z}) grow(double x, double y, double z,
      double azimuth, double elevation, double length, double radius,
      int depth, double birthStart, double birthEnd) {
    final steps = max(2, length.round());
    double cx = x, cy = y, cz = z;
    double az = azimuth, el = elevation;
    for (int s = 0; s < steps; s++) {
      final t = s / steps;
      az += (rnd.next() - 0.5) * 0.55;
      el += (rnd.next() - 0.5) * 0.35 + 0.06;
      const step = 0.85;
      cx += cos(az) * cos(el) * step;
      cy += sin(az) * cos(el) * step;
      cz += sin(el) * step + 0.25;
      final rad = radius * (1 - t * 0.7);
      final birth = birthStart + (birthEnd - birthStart) * t;
      stamp(cx, cy, cz, depth >= 2 ? rad : min(rad, 0.4),
          TreeVoxelType.branch, birth);
    }
    if (depth > 0) {
      final kids = 2 + (rnd.next() < 0.45 ? 1 : 0);
      for (int c = 0; c < kids; c++) {
        final naz = az + (rnd.next() - 0.5) * 1.9 + (c - kids / 2) * 0.7;
        final nel = min(1.35, el + 0.2 + rnd.next() * 0.5);
        final nlen = length * (0.6 + rnd.next() * 0.25);
        final nrad = max(0.18, radius * 0.6);
        final cbStart = birthEnd;
        final cbEnd =
            min(0.62, birthEnd + (0.62 - birthEnd) * (0.45 + rnd.next() * 0.4));
        grow(cx, cy, cz, naz, nel, nlen, nrad, depth - 1, cbStart, cbEnd);
        if (depth <= 2) {
          final lsize = 1.5 + rnd.next() * 1.1 + (2 - depth) * 0.4;
          // onset matched to HTML; leafCluster's own schedule spreads births.
          // (rnd.next() consumed for parity with the preview.)
          rnd.next();
          leafCluster(cx, cy, cz + 0.6, lsize);
        }
      }
    } else {
      final lsize = 1.7 + rnd.next() * 1.2;
      rnd.next();
      leafCluster(cx, cy, cz + 0.5, lsize);
    }
    return (x: cx, y: cy, z: cz);
  }

  // -------------------------------------------------------------------------
  // TRUNK — thick at base, thinning up. Born 0.10 .. 0.34.
  // -------------------------------------------------------------------------
  double tx = 0, ty = 0, tz = 0;
  double taz = rnd.next() * pi * 2, tel = 1.32;
  const trunkH = 11;
  final trunkPath = <({double x, double y, double z})>[];
  for (int s = 0; s < trunkH; s++) {
    final t = s / trunkH;
    taz += (rnd.next() - 0.5) * 0.22;
    tel += (rnd.next() - 0.5) * 0.10;
    tx += cos(taz) * cos(tel) * 0.55;
    ty += sin(taz) * cos(tel) * 0.55;
    tz += sin(tel) * 0.92 + 0.35;
    final radius = 2.1 * (1 - t * 0.62);
    final birth = 0.10 + t * 0.24;
    stamp(tx, ty, tz, radius, TreeVoxelType.trunk, birth);
    trunkPath.add((x: tx, y: ty, z: tz));
  }

  // -------------------------------------------------------------------------
  // PRIMARY BRANCHES off the upper trunk — asymmetric placement, no mirror.
  // -------------------------------------------------------------------------
  const branchAnchors = [0.42, 0.55, 0.66, 0.78, 0.88, 0.96];
  for (final at in branchAnchors) {
    final idx = min(trunkPath.length - 1, (at * trunkH).round());
    final p = trunkPath[idx];
    final az = rnd.next() * pi * 2;
    final el = 0.35 + rnd.next() * 0.6;
    final len = 5.5 - at * 2.2 + rnd.next() * 1.5;
    final rad = 1.05 * (1 - at * 0.4);
    final bStart = 0.20 + at * 0.10;
    final bEnd = min(0.52, bStart + 0.12 + rnd.next() * 0.08);
    grow(p.x, p.y, p.z, az, el, len, rad, 2, bStart, bEnd);
  }
  // Two low character branches for a wild silhouette.
  for (int i = 0; i < 2; i++) {
    final p = trunkPath[((0.5 + i * 0.15) * trunkH).round()];
    grow(p.x, p.y, p.z, rnd.next() * pi * 2, 0.15 + rnd.next() * 0.3,
        4 + rnd.next() * 2, 0.7, 1, 0.44, 0.66);
  }

  // -------------------------------------------------------------------------
  // FRUIT — golden, late season (70%+). Among outer/higher leaves.
  // -------------------------------------------------------------------------
  final leafList = cells.values
      .where((v) => v.type == TreeVoxelType.leaf)
      .toList()
    ..sort((a, b) {
      final ka = b.z + sqrt((b.x * b.x + b.y * b.y).toDouble());
      final kb = a.z + sqrt((a.x * a.x + a.y * a.y).toDouble());
      return ka.compareTo(kb);
    });
  final fruitN = min(38, (leafList.length * 0.05).round());
  for (int i = 0; i < fruitN; i++) {
    final cap = min(leafList.length, fruitN * 9);
    if (cap == 0) break;
    final base = leafList[(i * 7) % cap];
    final birth = 0.70 + rnd.next() * 0.27;
    put(base.x.toDouble(), base.y.toDouble(), base.z.toDouble(),
        TreeVoxelType.fruit, birth);
  }

  // -------------------------------------------------------------------------
  // Assign growth-ordered structuralIndex to all structural voxels.
  // Sort by birth, then by a stable spatial key for determinism.
  // -------------------------------------------------------------------------
  final structural = cells.values.toList()
    ..sort((a, b) {
      final c = a.birth.compareTo(b.birth);
      if (c != 0) return c;
      if (a.z != b.z) return a.z.compareTo(b.z);
      if (a.x != b.x) return a.x.compareTo(b.x);
      return a.y.compareTo(b.y);
    });

  final voxels = <TreeVoxel>[];
  for (int i = 0; i < structural.length; i++) {
    final v = structural[i];
    voxels.add(TreeVoxel(
      x: v.x,
      y: v.y,
      z: v.z,
      type: v.type,
      structuralIndex: i,
      seed: v.seed,
    ));
  }

  // -------------------------------------------------------------------------
  // STREAM (시냇가의 물) — non-structural, always present, animated shimmer.
  // A diagonal brook across the front. Dedup against tree cells + itself.
  // -------------------------------------------------------------------------
  final occupiedStructural = cells.keys.toSet();
  final streamSeen = <String>{};
  const sCount = 42;
  for (int i = 0; i < sCount; i++) {
    final t = i / sCount;
    final sx = -7 + t * 16 + sin(t * 7) * 0.8;
    final sy = 6 - t * 3 + cos(t * 5) * 1.4;
    for (final off in const [(0.0, 0.0), (0.9, 0.9)]) {
      final x = (sx + off.$1).round();
      final y = (sy + off.$2).round();
      const z = 0; // ground ribbon (z≈-0.2 rounds to 0)
      final k = key(x, y, z);
      if (occupiedStructural.contains(k)) continue;
      if (!streamSeen.add(k)) continue;
      voxels.add(TreeVoxel(
        x: x,
        y: y,
        z: z,
        type: TreeVoxelType.stream,
        structuralIndex: -1,
        seed: (rnd.next() * 1000).floor(),
      ));
    }
  }

  return voxels;
}

/// Cached tree voxel list (lazy).
List<TreeVoxel>? _cachedTreeVoxels;
List<TreeVoxel> get treeVoxels {
  _cachedTreeVoxels ??= buildTreeVoxels();
  return _cachedTreeVoxels!;
}

/// Only the structural (chapter-mapped) voxels, growth-ordered.
List<TreeVoxel>? _cachedStructural;
List<TreeVoxel> get treeStructuralVoxels {
  _cachedStructural ??=
      treeVoxels.where((v) => v.isStructural).toList();
  return _cachedStructural!;
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class PsalmTreePainter extends CustomPainter {
  final Map<int, Set<int>> progressData;
  final double glowAnimation;
  final BlockCoord? hoveredBlock;
  final BlockCoord? pressedBlock;
  final BlockCoord? selectedBlock;
  final double bounceAnimation;
  final Offset? cursorScenePos;
  final double rotationAngle;
  final Set<int> newlyFilledBlocks;
  final double fillAnimation;
  final double introAnimation;

  PsalmTreePainter({
    required this.progressData,
    this.glowAnimation = 0.0,
    this.hoveredBlock,
    this.pressedBlock,
    this.selectedBlock,
    this.bounceAnimation = 0.0,
    this.cursorScenePos,
    this.rotationAngle = 0.0,
    this.newlyFilledBlocks = const {},
    this.fillAnimation = 1.0,
    this.introAnimation = 1.0,
  });

  static const double blockSize = 9.0;
  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;

  /// Number of chapter-mapped voxels.
  static int get totalStructuralBlocks => treeStructuralVoxels.length;

  // ---- colors (테라코타 일몰 dusk palette, matching tree_map.html dusk) ----
  static const List<Color> _bark = [
    Color(0xFF7A5236),
    Color(0xFF5E3D28),
    Color(0xFF432A1B),
  ];
  static const Color _barkRoot = Color(0xFF3A281B);
  static const Color _terra = Color(0xFFC47B5A); // warm accent up high
  static const Color _leafYoung = Color(0xFF9CC24A);
  static const Color _leafMid = Color(0xFF5A9A44);
  static const Color _leafDeep = Color(0xFF2F6B3A);
  static const Color _fruit = Color(0xFFF2C14A);
  static const Color _fruitCore = Color(0xFFFFE9A8);
  static const Color _water = Color(0xFF3A7CA5);
  static const Color _waterHi = Color(0xFF9FD6E8);
  static const Color _soilDry = Color(0xFF5A4632);
  static const Color _soilLush = Color(0xFF3C5A2C);

  double get _progressFraction =>
      (ProgressService.totalRead(progressData) / BibleData.totalChapters)
          .clamp(0.0, 1.0);

  bool get isComplete =>
      ProgressService.totalRead(progressData) >= BibleData.totalChapters;

  Offset project(double x, double y, double z, Offset origin) {
    final cosA = cos(rotationAngle);
    final sinA = sin(rotationAngle);
    final rotatedX = x * cosA - y * sinA;
    final rotatedY = x * sinA + y * cosA;
    return Offset(
      origin.dx + (rotatedX - rotatedY) * _cos30 * blockSize,
      origin.dy + (rotatedX + rotatedY) * _sin30 * blockSize - z * blockSize,
    );
  }

  double _depthKey(TreeVoxel v) {
    final cosA = cos(rotationAngle);
    final sinA = sin(rotationAngle);
    final cx = v.x + 0.5;
    final cy = v.y + 0.5;
    final rotatedX = cx * cosA - cy * sinA;
    final rotatedY = cx * sinA + cy * cosA;
    return rotatedX + rotatedY - (v.z + 0.5);
  }

  Color _lerp(Color a, Color b, double t) => Color.lerp(a, b, t.clamp(0, 1))!;
  Color _shade(Color c, double f) {
    final r = (c.r * 255.0 * f).clamp(0, 255).round();
    final g = (c.g * 255.0 * f).clamp(0, 255).round();
    final b = (c.b * 255.0 * f).clamp(0, 255).round();
    return Color.fromARGB(255, r, g, b);
  }

  Color _topColorFor(TreeVoxel v, double p) {
    switch (v.type) {
      case TreeVoxelType.root:
        final soil = _lerp(_soilDry, _soilLush,
            ((p - 0.12) / 0.88).clamp(0.0, 1.0));
        return _lerp(_barkRoot, soil, 0.35);
      case TreeVoxelType.trunk:
      case TreeVoxelType.branch:
        final hb = ((v.z + 6) / 26).clamp(0.0, 1.0);
        Color col = _bark[v.seed % 3];
        if (v.type == TreeVoxelType.branch) {
          col = _lerp(col, _terra, 0.12 * hb);
        }
        return col;
      case TreeVoxelType.leaf:
        final mat = ((p - 0.30) / 0.55).clamp(0.0, 1.0);
        final local = (v.seed % 100) / 100.0;
        final ph = mat * 0.7 + local * 0.3;
        final base = ph < 0.5
            ? _lerp(_leafYoung, _leafMid, ph / 0.5)
            : _lerp(_leafMid, _leafDeep, (ph - 0.5) / 0.5);
        final tw = 0.5 + 0.5 * sin(glowAnimation * 2 * pi * 1.6 + v.seed * 0.7);
        return _shade(base, 0.94 + 0.12 * tw);
      case TreeVoxelType.fruit:
        final tw = 0.5 + 0.5 * sin(glowAnimation * 2 * pi * 2.5 + v.seed);
        return _lerp(_fruit, _fruitCore, 0.3 + 0.4 * tw);
      case TreeVoxelType.stream:
        final tw =
            0.5 + 0.5 * sin(glowAnimation * 2 * pi * 2.2 + v.seed * 0.3);
        return _lerp(_water, _waterHi, tw * 0.7);
    }
  }

  double _proximityZOffset(double bx, double by, double bz, Offset origin) {
    if (cursorScenePos == null) return 0;
    final blockCenter = project(bx + 0.5, by + 0.5, bz + 0.5, origin);
    final dist = (blockCenter - cursorScenePos!).distance;
    if (dist > 60) return 0;
    final ratio = 1 - (dist / 60);
    return 0.15 * ratio * ratio;
  }

  double get _bounceZOffset {
    if (pressedBlock == null || bounceAnimation <= 0) return 0;
    final t = bounceAnimation;
    return -0.3 * sin(t * pi * 2.5) * pow(1 - t, 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.70);
    final p = _progressFraction;

    // Warm light halo behind the tree — grows with maturity.
    _drawLightHalo(canvas, size, origin, p);

    if (isComplete && glowAnimation > 0) {
      _drawCompletionGlow(canvas, size, origin);
    }

    final all = treeVoxels;
    final structuralTotal = totalStructuralBlocks;

    // Build a render list: visible structural voxels (read), the streams
    // (always), and ghost wireframes for unread structural voxels.
    final ordered = List<TreeVoxel>.from(all)
      ..sort((a, b) => _depthKey(a).compareTo(_depthKey(b)));

    for (final v in ordered) {
      // -- stream: always present, shimmering, sits at the base --
      if (v.type == TreeVoxelType.stream) {
        if (introAnimation < 1.0) continue; // appears after intro settles
        _drawCube(canvas, origin, v.x.toDouble(), v.y.toDouble(),
            v.z.toDouble(), _topColorFor(v, p).withValues(alpha: 0.7));
        continue;
      }

      final sIdx = v.structuralIndex;
      final globalStart =
          (sIdx * BibleData.totalChapters / structuralTotal).floor();
      final globalEnd =
          ((sIdx + 1) * BibleData.totalChapters / structuralTotal).floor();

      int readCount = 0;
      final totalCount = max(1, globalEnd - globalStart);
      for (int g = globalStart; g < globalEnd; g++) {
        if (ProgressService.isGlobalIndexRead(progressData, g)) readCount++;
      }
      final fillRatio = readCount / totalCount;

      // Intro animation: voxels appear in growth order, rising from below.
      double introOpacity = 1.0;
      double introZOff = 0.0;
      if (introAnimation < 1.0) {
        final blockDelay = (sIdx / structuralTotal * 0.6).clamp(0.0, 0.6);
        final localT = ((introAnimation - blockDelay) / 0.4).clamp(0.0, 1.0);
        introOpacity = localT;
        introZOff = (1.0 - localT) * 3.0;
      }
      if (introOpacity <= 0) continue;

      double zOffset = _proximityZOffset(
          v.x.toDouble(), v.y.toDouble(), v.z.toDouble(), origin);
      final isPressed = pressedBlock != null &&
          pressedBlock!.x == v.x &&
          pressedBlock!.y == v.y &&
          pressedBlock!.z == v.z;
      if (isPressed) zOffset += _bounceZOffset;
      final effectiveZ = v.z.toDouble() + zOffset;

      // Fill animation (pop-in) for newly-grown voxels.
      double animOpacity = 1.0;
      double extraZOff = 0.0;
      if (newlyFilledBlocks.contains(sIdx) && fillAnimation < 1.0) {
        final blockDelay = (sIdx % 20) * 0.05;
        final localT =
            ((fillAnimation - blockDelay) / (1.0 - blockDelay)).clamp(0.0, 1.0);
        extraZOff = (1.0 - localT) * 2.0;
        animOpacity = localT;
      }

      final drawZ = effectiveZ + extraZOff + introZOff;
      final alpha = (animOpacity * introOpacity).clamp(0.0, 1.0);

      if (fillRatio >= 1.0) {
        _drawCube(canvas, origin, v.x.toDouble(), v.y.toDouble(), drawZ,
            _topColorFor(v, p).withValues(alpha: alpha));
        if (v.type == TreeVoxelType.fruit) {
          _drawFruitGlow(canvas, origin, v, drawZ, alpha);
        }
      } else if (readCount > 0) {
        final baseAlpha = (0.18 + fillRatio * 0.4) * alpha;
        _drawCube(canvas, origin, v.x.toDouble(), v.y.toDouble(), drawZ,
            _topColorFor(v, p).withValues(alpha: baseAlpha));
      } else {
        // Ghost wireframe — the full grown silhouette, visible even at 0%.
        if (introAnimation >= 1.0) {
          _drawWireframeCube(
              canvas, origin, v.x.toDouble(), v.y.toDouble(), effectiveZ);
        }
      }

      // Selection (푸른톤) > hover (골드).
      final isSelected = selectedBlock != null &&
          selectedBlock!.x == v.x &&
          selectedBlock!.y == v.y &&
          selectedBlock!.z == v.z;
      final isHovered = hoveredBlock != null &&
          hoveredBlock!.x == v.x &&
          hoveredBlock!.y == v.y &&
          hoveredBlock!.z == v.z;
      if (isSelected) {
        _drawBlockHighlight(
            canvas, origin, v.x.toDouble(), v.y.toDouble(), effectiveZ,
            fill: AppColors.selectionBlue.withValues(alpha: 0.35),
            outline: AppColors.selectionBlue,
            strokeWidth: 2.0);
      } else if (isHovered) {
        _drawBlockHighlight(
            canvas, origin, v.x.toDouble(), v.y.toDouble(), effectiveZ);
      }
    }

    // Rising light motes (영성이 차오름) — late game.
    if (p > 0.25) {
      _drawLightMotes(canvas, size, origin, p);
    }

    if (isComplete && glowAnimation > 0) {
      _drawParticles(canvas, size, origin);
    }
  }

  void _drawLightHalo(Canvas canvas, Size size, Offset origin, double p) {
    final lightStrength = ((p - 0.12) / 0.88).clamp(0.0, 1.0);
    if (lightStrength <= 0) return;
    final center = Offset(origin.dx, origin.dy - size.height * 0.22);
    final radius = size.width * 0.18 + size.width * 0.30 * lightStrength;
    final a = 0.05 + 0.32 * lightStrength;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.gold.withValues(alpha: a),
          AppColors.gold.withValues(alpha: a * 0.4),
          AppColors.gold.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawFruitGlow(
      Canvas canvas, Offset origin, TreeVoxel v, double z, double alpha) {
    final c = project(v.x + 0.5, v.y + 0.5, z + 0.5, origin);
    final tw = 0.5 + 0.5 * sin(glowAnimation * 2 * pi * 2.5 + v.seed);
    final paint = Paint()
      ..color = AppColors.gold
          .withValues(alpha: (0.45 * (0.5 + 0.35 * tw) * alpha).clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(c, blockSize * 1.4, paint);
  }

  void _drawLightMotes(Canvas canvas, Size size, Offset origin, double p) {
    final lightStrength = ((p - 0.12) / 0.88).clamp(0.0, 1.0);
    final n = (18 * lightStrength).round();
    final paint = Paint();
    for (int i = 0; i < n; i++) {
      final seedp = i * 97.13;
      final t = ((glowAnimation * 0.25 + i * 0.16) % 1.0);
      final px = origin.dx + sin(seedp) * size.width * 0.22 * (0.4 + i / n);
      final py = origin.dy - size.height * 0.05 - t * size.height * 0.5;
      final r = (1.2 + (i % 3)) * (size.width / 720);
      final a = (1 - t) * 0.5 * lightStrength;
      paint.color = AppColors.gold.withValues(alpha: a.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(px, py), r, paint);
    }
  }

  void _drawCube(Canvas canvas, Offset origin, double x, double y, double z,
      Color topColor) {
    final sideColor = Color.lerp(topColor, Colors.black, 0.35)!;
    final darkSideColor = Color.lerp(topColor, Colors.black, 0.55)!;

    final p1 = project(x + 1, y, z, origin);
    final p2 = project(x + 1, y + 1, z, origin);
    final p3 = project(x, y + 1, z, origin);
    final p4 = project(x, y, z + 1, origin);
    final p5 = project(x + 1, y, z + 1, origin);
    final p6 = project(x + 1, y + 1, z + 1, origin);
    final p7 = project(x, y + 1, z + 1, origin);

    final topPath = Path()
      ..moveTo(p4.dx, p4.dy)
      ..lineTo(p5.dx, p5.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p7.dx, p7.dy)
      ..close();
    canvas.drawPath(topPath, Paint()..color = topColor);
    canvas.drawPath(
      topPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    final leftPath = Path()
      ..moveTo(p3.dx, p3.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p7.dx, p7.dy)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = sideColor);
    canvas.drawPath(
      leftPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    final rightPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p5.dx, p5.dy)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = darkSideColor);
    canvas.drawPath(
      rightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  void _drawWireframeCube(
      Canvas canvas, Offset origin, double x, double y, double z) {
    final paint = Paint()
      ..color = AppColors.wireframe
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;

    final p1 = project(x + 1, y, z, origin);
    final p2 = project(x + 1, y + 1, z, origin);
    final p3 = project(x, y + 1, z, origin);
    final p4 = project(x, y, z + 1, origin);
    final p5 = project(x + 1, y, z + 1, origin);
    final p6 = project(x + 1, y + 1, z + 1, origin);
    final p7 = project(x, y + 1, z + 1, origin);

    final topPath = Path()
      ..moveTo(p4.dx, p4.dy)
      ..lineTo(p5.dx, p5.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p7.dx, p7.dy)
      ..close();
    canvas.drawPath(topPath, paint);

    final leftPath = Path()
      ..moveTo(p3.dx, p3.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p7.dx, p7.dy)
      ..close();
    canvas.drawPath(leftPath, paint);

    final rightPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p5.dx, p5.dy)
      ..close();
    canvas.drawPath(rightPath, paint);
  }

  void _drawBlockHighlight(
      Canvas canvas, Offset origin, double x, double y, double z,
      {Color fill = const Color(0x26FFFFFF),
      Color outline = AppColors.gold,
      double strokeWidth = 1.5}) {
    final highlightPaint = Paint()..color = fill;
    final p1 = project(x + 1, y, z, origin);
    final p2 = project(x + 1, y + 1, z, origin);
    final p3 = project(x, y + 1, z, origin);
    final p4 = project(x, y, z + 1, origin);
    final p5 = project(x + 1, y, z + 1, origin);
    final p6 = project(x + 1, y + 1, z + 1, origin);
    final p7 = project(x, y + 1, z + 1, origin);

    final topPath = Path()
      ..moveTo(p4.dx, p4.dy)
      ..lineTo(p5.dx, p5.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p7.dx, p7.dy)
      ..close();
    final leftPath = Path()
      ..moveTo(p3.dx, p3.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p7.dx, p7.dy)
      ..close();
    final rightPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p5.dx, p5.dy)
      ..close();

    canvas.drawPath(topPath, highlightPaint);
    canvas.drawPath(leftPath, highlightPaint);
    canvas.drawPath(rightPath, highlightPaint);

    final outlinePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(topPath, outlinePaint);
    canvas.drawPath(leftPath, outlinePaint);
    canvas.drawPath(rightPath, outlinePaint);
  }

  void _drawCompletionGlow(Canvas canvas, Size size, Offset origin) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.gold.withValues(alpha: 0.22 * glowAnimation),
          AppColors.gold.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
            center: Offset(origin.dx, origin.dy - size.height * 0.18),
            radius: size.width * 0.42),
      );
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  void _drawParticles(Canvas canvas, Size size, Offset origin) {
    final random = Random(42);
    final particlePaint = Paint();
    final top = Offset(origin.dx, origin.dy - size.height * 0.30);
    for (int i = 0; i < 30; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final dist = 40 + random.nextDouble() * 140;
      final phase = (glowAnimation + i * 0.033) % 1.0;
      final alpha = sin(phase * pi) * 0.7;
      if (alpha > 0) {
        final px = top.dx + cos(angle) * dist * phase;
        final py = top.dy + sin(angle) * dist * 0.5 * phase - phase * 80;
        final radius = 1.5 + random.nextDouble() * 2.0;
        particlePaint.color =
            AppColors.gold.withValues(alpha: alpha.clamp(0.0, 1.0));
        canvas.drawCircle(Offset(px, py), radius, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PsalmTreePainter oldDelegate) {
    return oldDelegate.progressData != progressData ||
        oldDelegate.glowAnimation != glowAnimation ||
        oldDelegate.hoveredBlock != hoveredBlock ||
        oldDelegate.pressedBlock != pressedBlock ||
        oldDelegate.selectedBlock != selectedBlock ||
        oldDelegate.bounceAnimation != bounceAnimation ||
        oldDelegate.cursorScenePos != cursorScenePos ||
        oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.fillAnimation != fillAnimation ||
        oldDelegate.newlyFilledBlocks != newlyFilledBlocks ||
        oldDelegate.introAnimation != introAnimation;
  }
}
