import 'dart:math';
import 'package:flutter/material.dart';

import '../data/bible_data.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import 'block_hit_test.dart';

// ---------------------------------------------------------------------------
// Temple voxel data — shared with SolomonsTempleHitTest via this library.
// ---------------------------------------------------------------------------

enum VoxelType {
  courtyard,
  stair,
  altar,
  wall,
  dvir,
  pillar,
  roof,
  cherub,
}

class TempleVoxel {
  final int x;
  final int y;
  final int z;
  final VoxelType type;
  /// Sequential index among structural voxels (chapter-mapped). Always >= 0.
  final int structuralIndex;

  const TempleVoxel({
    required this.x,
    required this.y,
    required this.z,
    required this.type,
    required this.structuralIndex,
  });
}

/// Builds and caches the full temple voxel list.
List<TempleVoxel> buildTempleVoxels() {
  final voxels = <TempleVoxel>[];
  int idx = 0;

  // -------------------------------------------------------------------------
  // Courtyard platform — z=0, x=-2..27, y=-3..10 (checkerboard stone)
  // -------------------------------------------------------------------------
  for (int cx = -2; cx <= 27; cx++) {
    for (int cy = -3; cy <= 10; cy++) {
      voxels.add(TempleVoxel(
        x: cx, y: cy, z: 0,
        type: VoxelType.courtyard,
        structuralIndex: idx++,
      ));
    }
  }

  // -------------------------------------------------------------------------
  // Stairs — z=1..3, x=-1,0,1, y=1..5
  // -------------------------------------------------------------------------
  for (int sx = -1; sx <= 1; sx++) {
    for (int sy = 1; sy <= 5; sy++) {
      // Step height = x+2 (so x=-1 → z=1, x=0 → z=1..2, x=1 → z=1..3)
      final maxZ = sx + 2;
      for (int sz = 1; sz <= maxZ; sz++) {
        voxels.add(TempleVoxel(
          x: sx, y: sy, z: sz,
          type: VoxelType.stair,
          structuralIndex: idx++,
        ));
      }
    }
  }

  // -------------------------------------------------------------------------
  // Bronze Altar — 3×3×3 solid at local (5..7, 1..3, z=1..3)
  // -------------------------------------------------------------------------
  for (int ax = 5; ax <= 7; ax++) {
    for (int ay = 1; ay <= 3; ay++) {
      for (int az = 1; az <= 3; az++) {
        voxels.add(TempleVoxel(
          x: ax, y: ay, z: az,
          type: VoxelType.altar,
          structuralIndex: idx++,
        ));
      }
    }
  }

  // -------------------------------------------------------------------------
  // Ulam / Porch — x=2..4, y=0..6, z=1..4 — hollow walls + floor at z=1
  // -------------------------------------------------------------------------
  for (int ux = 2; ux <= 4; ux++) {
    for (int uy = 0; uy <= 6; uy++) {
      for (int uz = 1; uz <= 4; uz++) {
        final isWall = uy == 0 || uy == 6 || ux == 2 || ux == 4 || uz == 1;
        if (isWall) {
          voxels.add(TempleVoxel(
            x: ux, y: uy, z: uz,
            type: VoxelType.wall,
            structuralIndex: idx++,
          ));
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // Hekal / Holy Place — x=5..17, y=0..6, z=1..6 — hollow walls + floor
  // -------------------------------------------------------------------------
  for (int hx = 5; hx <= 17; hx++) {
    for (int hy = 0; hy <= 6; hy++) {
      for (int hz = 1; hz <= 6; hz++) {
        final isWall = hy == 0 || hy == 6 || hx == 5 || hx == 17 || hz == 1;
        if (isWall) {
          voxels.add(TempleVoxel(
            x: hx, y: hy, z: hz,
            type: VoxelType.wall,
            structuralIndex: idx++,
          ));
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // Dvir / Holy of Holies — x=18..24, y=0..6, z=1..6 — SOLID gold
  // -------------------------------------------------------------------------
  for (int dx = 18; dx <= 24; dx++) {
    for (int dy = 0; dy <= 6; dy++) {
      for (int dz = 1; dz <= 6; dz++) {
        voxels.add(TempleVoxel(
          x: dx, y: dy, z: dz,
          type: VoxelType.dvir,
          structuralIndex: idx++,
        ));
      }
    }
  }

  // -------------------------------------------------------------------------
  // Cherubim — z=8..9 atop Dvir, 8 pair positions
  // -------------------------------------------------------------------------
  const cherubPositions = [
    (19, 1), (20, 1), (19, 5), (20, 5),
    (22, 2), (23, 2), (22, 4), (23, 4),
  ];
  for (final pos in cherubPositions) {
    for (int cz = 8; cz <= 9; cz++) {
      voxels.add(TempleVoxel(
        x: pos.$1, y: pos.$2, z: cz,
        type: VoxelType.cherub,
        structuralIndex: idx++,
      ));
    }
  }

  // -------------------------------------------------------------------------
  // Jachin pillar: x=2, y=1
  // Boaz  pillar: x=2, y=5
  // -------------------------------------------------------------------------
  for (final py in [1, 5]) {
    // Base z=1..2
    for (int pz = 1; pz <= 2; pz++) {
      voxels.add(TempleVoxel(
        x: 2, y: py, z: pz,
        type: VoxelType.pillar,
        structuralIndex: idx++,
      ));
    }
    // Shaft z=3..7
    for (int pz = 3; pz <= 7; pz++) {
      voxels.add(TempleVoxel(
        x: 2, y: py, z: pz,
        type: VoxelType.pillar,
        structuralIndex: idx++,
      ));
    }
    // Capital z=8
    voxels.add(TempleVoxel(
      x: 2, y: py, z: 8,
      type: VoxelType.pillar,
      structuralIndex: idx++,
    ));
    // Top z=9
    voxels.add(TempleVoxel(
      x: 2, y: py, z: 9,
      type: VoxelType.pillar,
      structuralIndex: idx++,
    ));
  }

  // -------------------------------------------------------------------------
  // Roof parapet — gold trim on top of wall tops
  // Ulam: z=5 at x=2..4, y=0 and y=6
  // Hekal/Dvir: z=7 at outer edges of hekal (x=5..24, y=0 and y=6) and ends
  // -------------------------------------------------------------------------
  // Ulam parapet z=5
  for (int rx = 2; rx <= 4; rx++) {
    for (final ry in [0, 6]) {
      voxels.add(TempleVoxel(
        x: rx, y: ry, z: 5,
        type: VoxelType.roof,
        structuralIndex: idx++,
      ));
    }
  }
  // Hekal parapet z=7
  for (int rx = 5; rx <= 17; rx++) {
    for (final ry in [0, 6]) {
      voxels.add(TempleVoxel(
        x: rx, y: ry, z: 7,
        type: VoxelType.roof,
        structuralIndex: idx++,
      ));
    }
  }
  // Dvir parapet z=7
  for (int rx = 18; rx <= 24; rx++) {
    for (final ry in [0, 6]) {
      voxels.add(TempleVoxel(
        x: rx, y: ry, z: 7,
        type: VoxelType.roof,
        structuralIndex: idx++,
      ));
    }
  }

  return voxels;
}

/// Cached temple voxel list (lazy).
List<TempleVoxel>? _cachedVoxels;
List<TempleVoxel> get templeVoxels {
  _cachedVoxels ??= buildTempleVoxels();
  return _cachedVoxels!;
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class SolomonsTemplePainter extends CustomPainter {
  final Map<int, Set<int>> progressData;
  final double glowAnimation;
  final BlockCoord? hoveredBlock;
  final BlockCoord? pressedBlock;
  final double bounceAnimation;
  final Offset? cursorScenePos;
  final double rotationAngle;
  final Set<int> newlyFilledBlocks;
  final double fillAnimation;
  final double introAnimation;

  SolomonsTemplePainter({
    required this.progressData,
    this.glowAnimation = 0.0,
    this.hoveredBlock,
    this.pressedBlock,
    this.bounceAnimation = 0.0,
    this.cursorScenePos,
    this.rotationAngle = 0.0,
    this.newlyFilledBlocks = const {},
    this.fillAnimation = 1.0,
    this.introAnimation = 1.0,
  });

  // -------------------------------------------------------------------------
  // Constants
  // -------------------------------------------------------------------------
  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;
  static const double blockSize = 8.0;

  // Colors
  static const _courtyard1 = Color(0xFFC8B89A);
  static const _courtyard2 = Color(0xFFB8A88A);
  static const _stairColor  = Color(0xFFD8C8B0);
  static const _altarColor  = Color(0xFF8B4513);
  static const _altarTop    = Color(0xFFCD853F);
  static const _wallColor   = Color(0xFFF0E8D8);
  static const _dvirColor   = Color(0xFFFFD700);
  static const _pillarColor = Color(0xFFCD853F);
  static const _pillarBase  = Color(0xFF8B6914);
  static const _roofGold    = Color(0xFFD4A843);
  static const _cherubColor = Color(0xFFFFD700);

  // -------------------------------------------------------------------------
  // Projection (same as IsometricBiblePainter)
  // -------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  int get _totalStructural => templeVoxels.length;

  bool _isVoxelRead(int structuralIndex) {
    final range = _chapterRange(structuralIndex);
    if (range.globalEnd <= range.globalStart) return false;
    for (int g = range.globalStart; g < range.globalEnd; g++) {
      if (!ProgressService.isGlobalIndexRead(progressData, g)) return false;
    }
    return true;
  }

  ({int globalStart, int globalEnd}) _chapterRange(int structuralIndex) {
    final total = _totalStructural;
    final globalStart =
        (structuralIndex * BibleData.totalChapters / total).floor();
    final globalEnd =
        ((structuralIndex + 1) * BibleData.totalChapters / total).floor();
    return (globalStart: globalStart, globalEnd: globalEnd);
  }

  bool get _isComplete =>
      ProgressService.totalRead(progressData) >= BibleData.totalChapters;

  double _proximityZOffset(double bx, double by, double bz, Offset origin) {
    if (cursorScenePos == null) return 0;
    final blockCenter = project(bx + 0.5, by + 0.5, bz + 0.5, origin);
    final dist = (blockCenter - cursorScenePos!).distance;
    if (dist > 60) return 0;
    final ratio = 1 - (dist / 60);
    return 0.12 * ratio * ratio;
  }

  double get _bounceZOffset {
    if (pressedBlock == null || bounceAnimation <= 0) return 0;
    final t = bounceAnimation;
    return -0.3 * sin(t * pi * 2.5) * pow(1 - t, 2);
  }

  // -------------------------------------------------------------------------
  // Paint
  // -------------------------------------------------------------------------

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.65);

    if (_isComplete && glowAnimation > 0) {
      _drawCompletionGlow(canvas, size, origin);
    }

    // Sort voxels back-to-front based on rotation.
    final voxels = List<TempleVoxel>.from(templeVoxels);
    final cosA = cos(rotationAngle);
    final sinA = sin(rotationAngle);
    voxels.sort((a, b) {
      // Painter's algorithm: depth = rotatedX + rotatedY (smaller = further back)
      final depthA = (a.x * cosA - a.y * sinA) + (a.x * sinA + a.y * cosA);
      final depthB = (b.x * cosA - b.y * sinA) + (b.x * sinA + b.y * cosA);
      final cmp = depthA.compareTo(depthB);
      if (cmp != 0) return cmp;
      return a.z.compareTo(b.z);
    });

    final maxOrder = voxels.length;
    for (int i = 0; i < voxels.length; i++) {
      final v = voxels[i];

      // Intro animation: staggered appearance bottom-to-top, back-to-front
      double introOpacity = 1.0;
      double introZOff = 0.0;
      if (introAnimation < 1.0) {
        final order = i;
        final blockDelay = (order / maxOrder) * 0.6;
        final localT =
            ((introAnimation - blockDelay) / 0.4).clamp(0.0, 1.0);
        introOpacity = localT;
        introZOff = (1.0 - localT) * 2.0;
      }
      if (introOpacity <= 0) continue;

      final vx = v.x.toDouble();
      final vy = v.y.toDouble();
      final vz = v.z.toDouble();

      // z-offset: proximity float + bounce
      double zOffset = _proximityZOffset(vx, vy, vz, origin);
      final isPressed = pressedBlock != null &&
          pressedBlock!.x == v.x &&
          pressedBlock!.y == v.y &&
          pressedBlock!.z == v.z;
      if (isPressed) zOffset += _bounceZOffset;

      // Fill animation
      double animOpacity = 1.0;
      double extraZOff = 0.0;
      if (newlyFilledBlocks.contains(v.structuralIndex) &&
          fillAnimation < 1.0) {
        final delay = (v.structuralIndex % 20) * 0.05;
        final localT =
            ((fillAnimation - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        extraZOff = (1.0 - localT) * 2.0;
        animOpacity = localT;
      }

      final effectiveZ = vz + zOffset + extraZOff + introZOff;
      final combinedAlpha = animOpacity * introOpacity;

      final isRead = _isVoxelRead(v.structuralIndex);
      final (topColor, sideColor) =
          _colorsForVoxel(v, isRead, combinedAlpha);

      if (isRead) {
        _drawCube(canvas, origin, vx, vy, effectiveZ, topColor, sideColor);
      } else {
        if (introAnimation >= 1.0) {
          _drawWireframeCube(canvas, origin, vx, vy, vz);
        }
      }

      // Highlight hovered block
      final isHovered = hoveredBlock != null &&
          hoveredBlock!.x == v.x &&
          hoveredBlock!.y == v.y &&
          hoveredBlock!.z == v.z;
      if (isHovered) {
        _drawBlockHighlight(canvas, origin, vx, vy, effectiveZ);
      }
    }

    if (_isComplete && glowAnimation > 0) {
      _drawParticles(canvas, size, origin);
    }
  }

  (Color, Color) _colorsForVoxel(
      TempleVoxel v, bool isRead, double alpha) {
    Color top;
    Color side;

    switch (v.type) {
      case VoxelType.courtyard:
        final checker = (v.x + v.y) % 2 == 0;
        top = checker ? _courtyard1 : _courtyard2;
        side = checker
            ? _courtyard1.withValues(alpha: 0.7)
            : _courtyard2.withValues(alpha: 0.7);
      case VoxelType.stair:
        top = _stairColor;
        side = _stairColor.withValues(alpha: 0.75);
      case VoxelType.altar:
        top = v.z == 3 ? _altarTop : _altarColor;
        side = _altarColor.withValues(alpha: 0.8);
      case VoxelType.wall:
        top = _wallColor;
        side = _wallColor.withValues(alpha: 0.7);
      case VoxelType.dvir:
        top = _dvirColor;
        side = _dvirColor.withValues(alpha: 0.75);
      case VoxelType.cherub:
        top = _cherubColor;
        side = _cherubColor.withValues(alpha: 0.8);
      case VoxelType.pillar:
        if (v.z <= 2) {
          top = _pillarBase;
          side = _pillarBase.withValues(alpha: 0.8);
        } else if (v.z == 8) {
          top = AppColors.gold;
          side = AppColors.gold.withValues(alpha: 0.8);
        } else if (v.z == 9) {
          top = const Color(0xFFFFE55C);
          side = const Color(0xFFFFE55C).withValues(alpha: 0.8);
        } else {
          top = _pillarColor;
          side = _pillarColor.withValues(alpha: 0.8);
        }
      case VoxelType.roof:
        top = _roofGold;
        side = _roofGold.withValues(alpha: 0.75);
    }

    if (alpha < 1.0) {
      top = top.withValues(alpha: top.a * alpha);
      side = side.withValues(alpha: side.a * alpha);
    }

    return (top, side);
  }

  // -------------------------------------------------------------------------
  // Draw primitives
  // -------------------------------------------------------------------------

  void _drawCube(Canvas canvas, Offset origin, double x, double y, double z,
      Color topColor, Color sideColor) {
    final p1 = project(x + 1, y, z, origin);
    final p2 = project(x + 1, y + 1, z, origin);
    final p3 = project(x, y + 1, z, origin);
    final p4 = project(x, y, z + 1, origin);
    final p5 = project(x + 1, y, z + 1, origin);
    final p6 = project(x + 1, y + 1, z + 1, origin);
    final p7 = project(x, y + 1, z + 1, origin);

    // Top face
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

    // Left face (darker)
    final leftPath = Path()
      ..moveTo(p3.dx, p3.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p7.dx, p7.dy)
      ..close();
    canvas.drawPath(
      leftPath,
      Paint()..color = Color.lerp(sideColor, Colors.black, 0.20)!,
    );
    canvas.drawPath(
      leftPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // Right face (slightly darker than top)
    final rightPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p5.dx, p5.dy)
      ..close();
    canvas.drawPath(
      rightPath,
      Paint()..color = Color.lerp(sideColor, Colors.black, 0.10)!,
    );
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

    canvas.drawPath(
      Path()
        ..moveTo(p4.dx, p4.dy)
        ..lineTo(p5.dx, p5.dy)
        ..lineTo(p6.dx, p6.dy)
        ..lineTo(p7.dx, p7.dy)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(p3.dx, p3.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p6.dx, p6.dy)
        ..lineTo(p7.dx, p7.dy)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p6.dx, p6.dy)
        ..lineTo(p5.dx, p5.dy)
        ..close(),
      paint,
    );
  }

  void _drawBlockHighlight(
      Canvas canvas, Offset origin, double x, double y, double z) {
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15);

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
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(topPath, outlinePaint);
    canvas.drawPath(leftPath, outlinePaint);
    canvas.drawPath(rightPath, outlinePaint);
  }

  void _drawCompletionGlow(Canvas canvas, Size size, Offset origin) {
    // Glow radiates from Dvir center
    final dvirCenter = project(21.0, 3.0, 4.0, origin);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.gold.withValues(alpha: 0.30 * glowAnimation),
          AppColors.gold.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: dvirCenter, radius: size.width * 0.45),
      );
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  void _drawParticles(Canvas canvas, Size size, Offset origin) {
    final random = Random(99);
    final particlePaint = Paint();
    final dvirCenter = project(21.0, 3.0, 4.0, origin);

    for (int i = 0; i < 30; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final dist = 50 + random.nextDouble() * 150;
      final phase = (glowAnimation + i * 0.033) % 1.0;
      final alpha = sin(phase * pi) * 0.7;

      if (alpha > 0) {
        final px = dvirCenter.dx + cos(angle) * dist * phase;
        final py = dvirCenter.dy - 80 +
            sin(angle) * dist * 0.5 * phase -
            phase * 60;
        final radius = 1.5 + random.nextDouble() * 2.0;
        particlePaint.color =
            AppColors.gold.withValues(alpha: alpha.clamp(0.0, 1.0));
        canvas.drawCircle(Offset(px, py), radius, particlePaint);
      }
    }
  }

  // -------------------------------------------------------------------------
  // shouldRepaint
  // -------------------------------------------------------------------------

  @override
  bool shouldRepaint(covariant SolomonsTemplePainter oldDelegate) {
    return oldDelegate.progressData != progressData ||
        oldDelegate.glowAnimation != glowAnimation ||
        oldDelegate.hoveredBlock != hoveredBlock ||
        oldDelegate.pressedBlock != pressedBlock ||
        oldDelegate.bounceAnimation != bounceAnimation ||
        oldDelegate.cursorScenePos != cursorScenePos ||
        oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.fillAnimation != fillAnimation ||
        oldDelegate.newlyFilledBlocks != newlyFilledBlocks ||
        oldDelegate.introAnimation != introAnimation;
  }
}
