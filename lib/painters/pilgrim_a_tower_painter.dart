import 'dart:math';
import 'package:flutter/material.dart';

// PilgrimA — Spiral Celestial Tower
// Voxel tower rising from the City of Destruction (foundation) to the
// Celestial City (crown). A continuous spiral staircase wraps the central
// pillar with one step per chapter (1,189 total). Landmark ledges mark
// key waypoints of Bunyan's pilgrimage.

enum TowerVoxelKind {
  foundationStone,
  pillar,
  ledge,
  stair,
  windowBlue,
  windowGold,
  crown,
  peak,
}

class TowerVoxel {
  final double x;
  final double y;
  final double z;
  final TowerVoxelKind kind;
  final int order; // sequential build index for intro stagger (-1 = always on)
  final int stairIndex; // -1 unless stair
  const TowerVoxel({
    required this.x,
    required this.y,
    required this.z,
    required this.kind,
    this.order = -1,
    this.stairIndex = -1,
  });
}

class TowerLedge {
  final int z;
  final String label;
  final double radius;
  const TowerLedge(this.z, this.label, this.radius);
}

class TowerScene {
  static const int stairCount = 1189;
  static const int stairsPerRevolution = 24;
  static const double stairRadius = 3.3;
  static const double pillarRadius = 2.3;
  static const int maxZ = 62;
  static const int foundationSize = 11;
  static const int foundationLevels = 2;

  static const List<TowerLedge> ledges = [
    TowerLedge(6, '좁은 문', 3.9),
    TowerLedge(18, '겸손의 골짜기', 3.8),
    TowerLedge(30, '허영의 시장', 3.8),
    TowerLedge(42, '빛나는 산', 3.7),
    TowerLedge(52, '죽음의 강', 3.5),
  ];

  static TowerScene? _instance;
  static TowerScene get instance => _instance ??= TowerScene._build();

  final List<TowerVoxel> voxels;
  final int maxOrder;
  TowerScene._(this.voxels, this.maxOrder);

  static TowerScene _build() {
    final voxels = <TowerVoxel>[];
    int order = 0;

    // Foundation — City of Destruction (dark terracotta slab)
    final half = foundationSize / 2;
    for (int z = -foundationLevels; z < 0; z++) {
      for (int ix = 0; ix < foundationSize; ix++) {
        for (int iy = 0; iy < foundationSize; iy++) {
          final fx = ix - half + 0.5;
          final fy = iy - half + 0.5;
          final d = sqrt(fx * fx + fy * fy);
          if (d > foundationSize / 2 + 0.2) continue;
          voxels.add(TowerVoxel(
            x: fx, y: fy, z: z.toDouble(),
            kind: TowerVoxelKind.foundationStone,
            order: order++,
          ));
        }
      }
    }

    // Central pillar — tapered ring at each level
    for (int z = 0; z <= maxZ - 8; z++) {
      final t = z / (maxZ - 8);
      final r = pillarRadius * (1 - 0.25 * t);
      const segs = 20;
      for (int i = 0; i < segs; i++) {
        final a = (i / segs) * 2 * pi;
        final px = cos(a) * r;
        final py = sin(a) * r;
        voxels.add(TowerVoxel(
          x: px, y: py, z: z.toDouble(),
          kind: TowerVoxelKind.pillar,
          order: order++,
        ));
      }
    }

    // Landmark ledges — ring of blocks at named z levels
    for (final l in ledges) {
      const segs = 30;
      for (int i = 0; i < segs; i++) {
        final a = (i / segs) * 2 * pi;
        voxels.add(TowerVoxel(
          x: cos(a) * l.radius,
          y: sin(a) * l.radius,
          z: l.z.toDouble(),
          kind: TowerVoxelKind.ledge,
          order: order++,
        ));
      }
    }

    // Stained glass windows — cardinal directions, every 8 levels
    for (int z = 4; z <= maxZ - 12; z += 6) {
      final isGold = ((z ~/ 6) % 2 == 0);
      final kind = isGold
          ? TowerVoxelKind.windowGold
          : TowerVoxelKind.windowBlue;
      for (int dir = 0; dir < 4; dir++) {
        final a = dir * pi / 2;
        final r = pillarRadius * (1 - 0.25 * (z / (maxZ - 8))) + 0.15;
        voxels.add(TowerVoxel(
          x: cos(a) * r,
          y: sin(a) * r,
          z: z.toDouble(),
          kind: kind,
          order: order++,
        ));
      }
    }

    // Spiral staircase — 1,189 steps wrapping the pillar
    final stairTop = (maxZ - 8).toDouble();
    for (int i = 0; i < stairCount; i++) {
      final t = i / (stairCount - 1);
      final angle = (i / stairsPerRevolution) * 2 * pi;
      final z = t * stairTop;
      final rr = stairRadius * (1 - 0.15 * t);
      voxels.add(TowerVoxel(
        x: cos(angle) * rr,
        y: sin(angle) * rr,
        z: z,
        kind: TowerVoxelKind.stair,
        order: order++,
        stairIndex: i,
      ));
    }

    // Crown — stepped pyramid
    final crownBase = maxZ - 6;
    for (int layer = 0; layer < 5; layer++) {
      final z = (crownBase + layer).toDouble();
      final ringR = 2.2 - layer * 0.45;
      final segs = 16 - layer * 2;
      for (int i = 0; i < segs; i++) {
        final a = (i / segs) * 2 * pi;
        voxels.add(TowerVoxel(
          x: cos(a) * ringR,
          y: sin(a) * ringR,
          z: z,
          kind: TowerVoxelKind.crown,
          order: order++,
        ));
      }
    }

    // Peak — single radiant cube above the crown
    voxels.add(TowerVoxel(
      x: 0, y: 0, z: maxZ.toDouble(),
      kind: TowerVoxelKind.peak,
      order: order++,
    ));

    return TowerScene._(voxels, order);
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class PilgrimATowerPainter extends CustomPainter {
  final double glowAnimation;
  final double introAnimation;
  final double rotationAngle;
  final int readStairs;

  PilgrimATowerPainter({
    required this.glowAnimation,
    required this.introAnimation,
    this.rotationAngle = 0.0,
    this.readStairs = 0,
  });

  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;
  static const double _blockSize = 9.0;

  Offset _project(double x, double y, double z, Offset origin) {
    final cosA = cos(rotationAngle);
    final sinA = sin(rotationAngle);
    final rx = x * cosA - y * sinA;
    final ry = x * sinA + y * cosA;
    return Offset(
      origin.dx + (rx - ry) * _cos30 * _blockSize,
      origin.dy + (rx + ry) * _sin30 * _blockSize - z * _blockSize,
    );
  }

  double _depthKey(TowerVoxel v) {
    final cosA = cos(rotationAngle);
    final sinA = sin(rotationAngle);
    final rx = v.x * cosA - v.y * sinA;
    final ry = v.x * sinA + v.y * cosA;
    // Further back = smaller depth, draw first
    return -(rx + ry) * 100 + v.z;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);

    final origin = Offset(size.width / 2, size.height * 0.82);
    final scene = TowerScene.instance;
    final revealMax = introAnimation * scene.maxOrder;

    _drawHalo(canvas, origin, scene);

    final sorted = [...scene.voxels]
      ..sort((a, b) => _depthKey(a).compareTo(_depthKey(b)));

    for (final v in sorted) {
      if (v.order > revealMax) continue;
      _drawVoxel(canvas, v, origin);
    }

    _drawPeakAura(canvas, origin);
    _drawParticles(canvas, size, origin);
  }

  void _drawSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.4),
        radius: 1.1,
        colors: [Color(0xFF1A1538), Color(0xFF0A0A1A), Color(0xFF040410)],
        stops: [0, 0.55, 1],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _drawHalo(Canvas canvas, Offset origin, TowerScene scene) {
    final peak = _project(0, 0, TowerScene.maxZ.toDouble(), origin);
    final pulse = 0.6 + 0.4 * sin(glowAnimation * 2 * pi);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(212, 168, 67, 0.35 * pulse),
          const Color(0x00D4A843),
        ],
      ).createShader(Rect.fromCircle(center: peak, radius: 160));
    canvas.drawCircle(peak, 160, paint);
  }

  void _drawPeakAura(Canvas canvas, Offset origin) {
    final peak = _project(0, 0, TowerScene.maxZ.toDouble(), origin);
    final pulse = 0.5 + 0.5 * sin(glowAnimation * 2 * pi);
    for (int i = 0; i < 3; i++) {
      final r = 14.0 + i * 10 + pulse * 8;
      final p = Paint()
        ..color = Color.fromRGBO(245, 230, 192, 0.12 * (1 - i / 3) * pulse)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(peak, r, p);
    }
  }

  void _drawParticles(Canvas canvas, Size size, Offset origin) {
    final peak = _project(0, 0, TowerScene.maxZ.toDouble(), origin);
    final rng = Random(42);
    for (int i = 0; i < 40; i++) {
      final base = rng.nextDouble() * 2 * pi;
      final phase = (glowAnimation + rng.nextDouble()) % 1.0;
      final dist = 30 + phase * 80;
      final a = base + phase * 0.6;
      final x = peak.dx + cos(a) * dist;
      final y = peak.dy + sin(a) * dist - phase * 20;
      final alpha = (1 - phase) * 0.5;
      final paint = Paint()
        ..color = Color.fromRGBO(245, 230, 192, alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawCircle(Offset(x, y), 1.3, paint);
    }
  }

  void _drawVoxel(Canvas canvas, TowerVoxel v, Offset origin) {
    final bs = _blockSize;
    final top = _project(v.x, v.y, v.z + 0.5, origin);
    final c = _colorForVoxel(v);
    final (top1, left1, right1) = _shadedTriplet(c);

    final topPath = Path()
      ..moveTo(top.dx, top.dy - bs * 0.5)
      ..lineTo(top.dx + _cos30 * bs * 0.5, top.dy - _sin30 * bs * 0.5)
      ..lineTo(top.dx, top.dy + _sin30 * bs * 0)
      ..lineTo(top.dx - _cos30 * bs * 0.5, top.dy - _sin30 * bs * 0.5)
      ..close();
    canvas.drawPath(topPath, Paint()..color = top1);

    final leftPath = Path()
      ..moveTo(top.dx - _cos30 * bs * 0.5, top.dy - _sin30 * bs * 0.5)
      ..lineTo(top.dx, top.dy)
      ..lineTo(top.dx, top.dy + bs)
      ..lineTo(top.dx - _cos30 * bs * 0.5, top.dy + bs - _sin30 * bs * 0.5)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = left1);

    final rightPath = Path()
      ..moveTo(top.dx + _cos30 * bs * 0.5, top.dy - _sin30 * bs * 0.5)
      ..lineTo(top.dx, top.dy)
      ..lineTo(top.dx, top.dy + bs)
      ..lineTo(top.dx + _cos30 * bs * 0.5, top.dy + bs - _sin30 * bs * 0.5)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = right1);

    // Highlight the most-recently-read stair
    if (v.kind == TowerVoxelKind.stair && v.stairIndex == readStairs - 1) {
      final glow = Paint()
        ..color = const Color(0xFFD4A843)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(topPath, glow);
    }
  }

  (Color, Color, Color) _shadedTriplet(Color base) {
    Color darken(Color c, double f) => Color.fromARGB(
          c.a.round(),
          (c.r * 255 * f).clamp(0, 255).round(),
          (c.g * 255 * f).clamp(0, 255).round(),
          (c.b * 255 * f).clamp(0, 255).round(),
        );
    return (base, darken(base, 0.72), darken(base, 0.55));
  }

  Color _colorForVoxel(TowerVoxel v) {
    switch (v.kind) {
      case TowerVoxelKind.foundationStone:
        return const Color(0xFF4A2E1F);
      case TowerVoxelKind.pillar:
        final t = v.z / TowerScene.maxZ;
        return Color.lerp(
          const Color(0xFF8B4513),
          const Color(0xFFB78560),
          t,
        )!;
      case TowerVoxelKind.ledge:
        return const Color(0xFFC47B5A);
      case TowerVoxelKind.stair:
        final tz = v.z / TowerScene.maxZ;
        final lit = v.stairIndex >= 0 &&
            v.stairIndex < readStairs;
        final base = Color.lerp(
          const Color(0xFFC47B5A),
          const Color(0xFFD4A843),
          tz,
        )!;
        if (!lit) {
          return Color.fromRGBO(
            (base.r * 255).round(),
            (base.g * 255).round(),
            (base.b * 255).round(),
            0.4,
          );
        }
        return base;
      case TowerVoxelKind.windowBlue:
        final pulse = 0.7 + 0.3 * sin(glowAnimation * 2 * pi);
        return Color.fromRGBO(122, 142, 153, pulse);
      case TowerVoxelKind.windowGold:
        final pulse = 0.7 + 0.3 * sin(glowAnimation * 2 * pi + pi / 2);
        return Color.fromRGBO(212, 168, 67, pulse);
      case TowerVoxelKind.crown:
        return const Color(0xFFD4A843);
      case TowerVoxelKind.peak:
        final pulse = 0.75 + 0.25 * sin(glowAnimation * 2 * pi);
        return Color.fromRGBO(255, 240, 200, pulse);
    }
  }

  @override
  bool shouldRepaint(covariant PilgrimATowerPainter old) =>
      old.glowAnimation != glowAnimation ||
      old.introAnimation != introAnimation ||
      old.rotationAngle != rotationAngle ||
      old.readStairs != readStairs;
}
