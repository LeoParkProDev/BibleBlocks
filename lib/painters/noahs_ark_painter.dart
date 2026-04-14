import 'dart:math';
import 'package:flutter/material.dart';

import '../data/bible_data.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import 'block_hit_test.dart';

// ---------------------------------------------------------------------------
// Voxel data model
// ---------------------------------------------------------------------------

class ArkVoxel {
  final int x;
  final int y;
  final int z;
  final String type;
  final bool isStructural;
  final int structuralIndex; // -1 if decorative

  const ArkVoxel({
    required this.x,
    required this.y,
    required this.z,
    required this.type,
    required this.isStructural,
    required this.structuralIndex,
  });
}

// ---------------------------------------------------------------------------
// Shared voxel list builder — used by both painter and hit-test
// ---------------------------------------------------------------------------

class ArkVoxels {
  // Hull profile: index = x (0..14), value = [yStart, yEnd]
  static const List<List<int>> _hullProfile = [
    [4, 4], // x=0
    [3, 5], // x=1
    [2, 6], // x=2
    [2, 6], // x=3
    [1, 7], // x=4
    [1, 7], // x=5
    [1, 7], // x=6
    [1, 7], // x=7
    [1, 7], // x=8
    [1, 7], // x=9
    [2, 6], // x=10
    [2, 6], // x=11
    [3, 5], // x=12
    [3, 5], // x=13
    [4, 4], // x=14
  ];

  static const Set<String> _windowPositions = {
    '5,2,5',
    '7,2,5',
    '9,2,5',
    '5,6,5',
    '7,6,5',
    '9,6,5',
    '3,4,5',
    '11,4,5',
  };

  static List<ArkVoxel> build() {
    final voxels = <ArkVoxel>[];
    int structIdx = 0;

    // -----------------------------------------------------------------------
    // Hull: z=0 and z=1
    // -----------------------------------------------------------------------
    for (int z = 0; z <= 1; z++) {
      for (int x = 0; x < _hullProfile.length; x++) {
        final yStart = _hullProfile[x][0];
        final yEnd = _hullProfile[x][1];
        for (int y = yStart; y <= yEnd; y++) {
          voxels.add(ArkVoxel(
            x: x, y: y, z: z,
            type: 'hull',
            isStructural: true,
            structuralIndex: structIdx++,
          ));
        }
      }
    }

    // -----------------------------------------------------------------------
    // Deck 1 floor: z=2, x=1..13 (hull profile)
    // -----------------------------------------------------------------------
    for (int x = 1; x <= 13; x++) {
      final yStart = _hullProfile[x][0];
      final yEnd = _hullProfile[x][1];
      for (int y = yStart; y <= yEnd; y++) {
        voxels.add(ArkVoxel(
          x: x, y: y, z: 2,
          type: 'deck',
          isStructural: true,
          structuralIndex: structIdx++,
        ));
      }
    }

    // -----------------------------------------------------------------------
    // Deck 2 walls (z=3): side walls at yStart/yEnd for x=2..12
    // Interior floor for x=2..12, y=yStart+1..yEnd-1
    // -----------------------------------------------------------------------
    for (int x = 2; x <= 12; x++) {
      final yStart = _hullProfile[x][0];
      final yEnd = _hullProfile[x][1];
      // Side walls (y == yStart or y == yEnd)
      for (int y = yStart; y <= yEnd; y++) {
        if (y == yStart || y == yEnd) {
          voxels.add(ArkVoxel(
            x: x, y: y, z: 3,
            type: 'cabin',
            isStructural: true,
            structuralIndex: structIdx++,
          ));
        }
      }
      // Interior floor
      for (int y = yStart + 1; y <= yEnd - 1; y++) {
        voxels.add(ArkVoxel(
          x: x, y: y, z: 3,
          type: 'deck',
          isStructural: true,
          structuralIndex: structIdx++,
        ));
      }
    }

    // -----------------------------------------------------------------------
    // Cabin walls: z=4 and z=5, x=3..11, y=2..6
    // Interior floor at z=4 only
    // -----------------------------------------------------------------------
    for (int z = 4; z <= 5; z++) {
      for (int x = 3; x <= 11; x++) {
        for (int y = 2; y <= 6; y++) {
          final isWall = y == 2 || y == 6 || x == 3 || x == 11;
          if (isWall) {
            // Check if this is a window position
            final key = '$x,$y,$z';
            final isWindow = _windowPositions.contains(key);
            voxels.add(ArkVoxel(
              x: x, y: y, z: z,
              type: isWindow ? 'window' : 'cabin',
              isStructural: !isWindow,
              structuralIndex: isWindow ? -1 : structIdx++,
            ));
          } else if (z == 4) {
            // Interior floor at z=4
            voxels.add(ArkVoxel(
              x: x, y: y, z: z,
              type: 'deck',
              isStructural: true,
              structuralIndex: structIdx++,
            ));
          }
        }
      }
    }

    // -----------------------------------------------------------------------
    // Roof: z=6, x=3..11, y=2..6
    // Ridge: z=7, x=4..10, y=3..5
    // Peak: z=8, x=5..9, y=4 only
    // -----------------------------------------------------------------------
    for (int x = 3; x <= 11; x++) {
      for (int y = 2; y <= 6; y++) {
        voxels.add(ArkVoxel(
          x: x, y: y, z: 6,
          type: 'roof',
          isStructural: true,
          structuralIndex: structIdx++,
        ));
      }
    }
    for (int x = 4; x <= 10; x++) {
      for (int y = 3; y <= 5; y++) {
        voxels.add(ArkVoxel(
          x: x, y: y, z: 7,
          type: 'roof',
          isStructural: true,
          structuralIndex: structIdx++,
        ));
      }
    }
    for (int x = 5; x <= 9; x++) {
      voxels.add(ArkVoxel(
        x: x, y: 4, z: 8,
        type: 'roof',
        isStructural: true,
        structuralIndex: structIdx++,
      ));
    }

    // -----------------------------------------------------------------------
    // Ramp: (13,4,2), (14,4,1), (15,4,0)
    // -----------------------------------------------------------------------
    for (final pos in [
      [13, 4, 2],
      [14, 4, 1],
      [15, 4, 0],
    ]) {
      voxels.add(ArkVoxel(
        x: pos[0], y: pos[1], z: pos[2],
        type: 'ramp',
        isStructural: true,
        structuralIndex: structIdx++,
      ));
    }

    // -----------------------------------------------------------------------
    // Water: decorative, always drawn
    // z=-2: x=-3..19, y=-1..11
    // z=-3: x=-4..20, y=-2..12
    // -----------------------------------------------------------------------
    for (int x = -3; x <= 19; x++) {
      for (int y = -1; y <= 11; y++) {
        voxels.add(ArkVoxel(
          x: x, y: y, z: -2,
          type: 'water',
          isStructural: false,
          structuralIndex: -1,
        ));
      }
    }
    for (int x = -4; x <= 20; x++) {
      for (int y = -2; y <= 12; y++) {
        voxels.add(ArkVoxel(
          x: x, y: y, z: -3,
          type: 'water',
          isStructural: false,
          structuralIndex: -1,
        ));
      }
    }

    // -----------------------------------------------------------------------
    // Dove: decorative
    // -----------------------------------------------------------------------
    for (final pos in [
      [9, 1, 12],
      [10, 1, 12],
      [9, 1, 11],
    ]) {
      voxels.add(ArkVoxel(
        x: pos[0], y: pos[1], z: pos[2],
        type: 'dove',
        isStructural: false,
        structuralIndex: -1,
      ));
    }

    // Olive: decorative
    voxels.add(ArkVoxel(
      x: 10, y: 2, z: 11,
      type: 'olive',
      isStructural: false,
      structuralIndex: -1,
    ));

    return voxels;
  }

  // Lazily built, shared between painter and hit-test
  static late final List<ArkVoxel> _cache;
  static late final int _structuralCount;
  static bool _built = false;

  static List<ArkVoxel> get allVoxels {
    _ensureBuilt();
    return _cache;
  }

  static int get structuralCount {
    _ensureBuilt();
    return _structuralCount;
  }

  static void _ensureBuilt() {
    if (_built) return;
    _cache = build();
    _structuralCount = _cache.where((v) => v.isStructural).length;
    _built = true;
  }
}

// ---------------------------------------------------------------------------
// NoahsArkPainter
// ---------------------------------------------------------------------------

class NoahsArkPainter extends CustomPainter {
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

  NoahsArkPainter({
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

  static const double blockSize = 10.0;
  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;

  // Total structural voxel count (excluding decorative)
  static int get totalStructuralBlocks => ArkVoxels.structuralCount;

  // ---------------------------------------------------------------------------
  // Colors
  // ---------------------------------------------------------------------------
  static const Color _hullDarkTop = Color(0xFF6B3E1E);
  static const Color _hullMedTop = Color(0xFF8B5A2B);
  static const Color _deckTop = Color(0xFFA0682F);
  static const Color _cabinTop = Color(0xFF7A4A22);
  static const Color _roofTop = Color(0xFFC47B5A); // terracotta
  static const Color _windowTop = Color(0xFFD4A843); // gold
  static const Color _waterTop = Color(0xFF2A4A6B);
  static const Color _doveTop = Color(0xFFF0EEE8);
  static const Color _oliveTop = Color(0xFF4A7A2A);
  static const Color _rampTop = Color(0xFF8B5A2B);

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

  Color _topColorForType(String type) {
    switch (type) {
      case 'hull':
        return _hullMedTop;
      case 'deck':
        return _deckTop;
      case 'cabin':
        return _cabinTop;
      case 'roof':
        return _roofTop;
      case 'window':
        return _windowTop;
      case 'water':
        return _waterTop;
      case 'dove':
        return _doveTop;
      case 'olive':
        return _oliveTop;
      case 'ramp':
        return _rampTop;
      default:
        return _hullDarkTop;
    }
  }

  double _depthKey(ArkVoxel v) {
    final cosA = cos(rotationAngle);
    final sinA = sin(rotationAngle);
    final cx = v.x + 0.5;
    final cy = v.y + 0.5;
    final rotatedX = cx * cosA - cy * sinA;
    final rotatedY = cx * sinA + cy * cosA;
    // Back-to-front: larger (rotatedX + rotatedY - z) is rendered last (on top)
    return rotatedX + rotatedY - (v.z + 0.5);
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
    final origin = Offset(size.width / 2, size.height * 0.65);

    if (isComplete && glowAnimation > 0) {
      _drawCompletionGlow(canvas, size, origin);
    }

    final allVoxels = ArkVoxels.allVoxels;

    // Sort back-to-front
    final sorted = List<ArkVoxel>.from(allVoxels)
      ..sort((a, b) => _depthKey(a).compareTo(_depthKey(b)));

    // Dove float offset
    final doveZOffset = sin(glowAnimation * 2 * pi) * 0.3;

    for (final v in sorted) {
      double vz = v.z.toDouble();
      if (v.type == 'dove') vz += doveZOffset;

      // Decorative blocks: always draw solid
      if (!v.isStructural) {
        Color topColor = _topColorForType(v.type);
        // Water wave: slightly modulate alpha with glowAnimation
        if (v.type == 'water') {
          final wave = sin(glowAnimation * 2 * pi + v.x * 0.3 + v.y * 0.2);
          final alpha = (0.75 + wave * 0.15).clamp(0.5, 1.0);
          topColor = topColor.withValues(alpha: alpha);
        }
        _drawCube(canvas, origin, v.x.toDouble(), v.y.toDouble(), vz,
            topColor);
        continue;
      }

      // Structural blocks: check reading progress
      final sIdx = v.structuralIndex;
      final globalStart =
          (sIdx * BibleData.totalChapters / totalStructuralBlocks).floor();
      final globalEnd =
          ((sIdx + 1) * BibleData.totalChapters / totalStructuralBlocks)
              .floor();

      int readCount = 0;
      final totalCount = max(1, globalEnd - globalStart);
      for (int g = globalStart; g < globalEnd; g++) {
        if (ProgressService.isGlobalIndexRead(progressData, g)) readCount++;
      }
      final fillRatio = readCount / totalCount;

      // Intro animation
      double introOpacity = 1.0;
      double introZOff = 0.0;
      if (introAnimation < 1.0) {
        final order = sIdx;
        final maxOrder = totalStructuralBlocks;
        final blockDelay = (order / maxOrder * 0.6).clamp(0.0, 0.6);
        final localT = ((introAnimation - blockDelay) / 0.4).clamp(0.0, 1.0);
        introOpacity = localT;
        introZOff = (1.0 - localT) * 3.0;
      }
      if (introOpacity <= 0) continue;

      // Proximity float + bounce
      double zOffset =
          _proximityZOffset(v.x.toDouble(), v.y.toDouble(), vz, origin);
      final isPressed = pressedBlock != null &&
          pressedBlock!.x == v.x &&
          pressedBlock!.y == v.y &&
          pressedBlock!.z == v.z;
      if (isPressed) zOffset += _bounceZOffset;
      final effectiveZ = vz + zOffset;

      // Fill animation for newly filled blocks
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
        _drawCube(
          canvas, origin,
          v.x.toDouble(), v.y.toDouble(), drawZ,
          _topColorForType(v.type).withValues(alpha: alpha),
        );
      } else if (readCount > 0) {
        final baseAlpha = (0.15 + fillRatio * 0.35) * alpha;
        _drawCube(
          canvas, origin,
          v.x.toDouble(), v.y.toDouble(), drawZ,
          _topColorForType(v.type).withValues(alpha: baseAlpha),
        );
      } else {
        if (introAnimation >= 1.0) {
          _drawWireframeCube(
              canvas, origin, v.x.toDouble(), v.y.toDouble(), effectiveZ);
        }
      }

      // Hover highlight
      final isHovered = hoveredBlock != null &&
          hoveredBlock!.x == v.x &&
          hoveredBlock!.y == v.y &&
          hoveredBlock!.z == v.z;
      if (isHovered) {
        _drawBlockHighlight(
            canvas, origin, v.x.toDouble(), v.y.toDouble(), effectiveZ);
      }
    }

    if (isComplete && glowAnimation > 0) {
      _drawParticles(canvas, size, origin);
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

    // Left face
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

    // Right face
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
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.gold.withValues(alpha: 0.25 * glowAnimation),
          AppColors.gold.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: origin, radius: size.width * 0.4),
      );
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  void _drawParticles(Canvas canvas, Size size, Offset origin) {
    final random = Random(42);
    final particlePaint = Paint();

    for (int i = 0; i < 30; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final dist = 50 + random.nextDouble() * 150;
      final phase = (glowAnimation + i * 0.033) % 1.0;
      final alpha = sin(phase * pi) * 0.7;

      if (alpha > 0) {
        final px = origin.dx + cos(angle) * dist * phase;
        final py =
            origin.dy - 100 + sin(angle) * dist * 0.5 * phase - phase * 80;
        final radius = 1.5 + random.nextDouble() * 2.0;

        particlePaint.color =
            AppColors.gold.withValues(alpha: alpha.clamp(0.0, 1.0));
        canvas.drawCircle(Offset(px, py), radius, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant NoahsArkPainter oldDelegate) {
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
