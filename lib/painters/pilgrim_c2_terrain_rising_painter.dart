import 'dart:math';
import 'package:flutter/material.dart';

import 'pilgrim_c_mountain_painter.dart';

// C2 — Terrain Rising
// World starts flat. Mountains grow from the ground along the path's wake —
// each column of terrain rises to its full height only after the pilgrim
// has walked past it. Progress = a wave of emerging landscape.

class PilgrimC2Painter extends CustomPainter {
  final double glowAnimation;
  final double introAnimation;
  final int readChapters;

  PilgrimC2Painter({
    required this.glowAnimation,
    required this.introAnimation,
    required this.readChapters,
  });

  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;
  static const double _block = 7.0;
  static const int _growBand = 4; // column width over which growth ramps up

  // Path's maxX reached, cached per readChapters. Rebuilt when read changes.
  static int _cachedRead = -1;
  static int _cachedFrontierX = 0;

  int _computeFrontier(int litStones) {
    if (litStones == _cachedRead) return _cachedFrontierX;
    int maxX = 0;
    for (final v in PilgrimCLandscape.voxels) {
      if (v.pathIndex >= 0 && v.pathIndex <= litStones && v.x > maxX) {
        maxX = v.x;
      }
    }
    _cachedRead = litStones;
    _cachedFrontierX = maxX;
    return maxX;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);

    const cx = (PilgrimCLandscape.gridW - 1) / 2.0;
    const cy = (PilgrimCLandscape.gridH - 1) / 2.0;
    final origin = Offset(
      size.width * 0.5 - (cx - cy) * _cos30 * _block,
      size.height * 0.58 - (cx + cy) * _sin30 * _block,
    );

    final pathLen = PilgrimCLandscape.pathLength;
    final litStones =
        (readChapters.clamp(0, PilgrimCLandscape.totalChapters) *
                pathLen /
                PilgrimCLandscape.totalChapters)
            .floor();
    final frontier = _computeFrontier(litStones);

    _drawBaseline(canvas, origin);

    final voxels = PilgrimCLandscape.voxels;
    final intro = introAnimation.clamp(0.0, 1.0);

    final sorted = [...voxels]
      ..sort((a, b) {
        final da = a.x + a.y - a.z * 0.1;
        final db = b.x + b.y - b.z * 0.1;
        return da.compareTo(db);
      });

    for (final v in sorted) {
      final isPath = v.pathIndex >= 0;
      final litPath = isPath && v.pathIndex <= litStones;

      if (isPath) {
        if (!litPath) continue; // don't show unread path
        _drawVoxel(canvas, v, origin, isPath: true,
            highlight: v.pathIndex == litStones - 1);
        continue;
      }

      // Non-path voxel — growth by column distance to frontier
      final growth = ((frontier - v.x + _growBand) / _growBand).clamp(0.0, 1.0);
      if (growth <= 0.02) continue;

      // Intro stagger multiplier
      final orderRatio = v.x / PilgrimCLandscape.gridW;
      if (orderRatio > intro * 1.05) continue;

      // Squash voxels with low growth — render only if z is within growth band
      final col = PilgrimCLandscape.heightmap[v.x][v.y];
      if (col < 0) continue;
      final visibleZ = (col * growth).clamp(0, col).toDouble();
      if (v.z > visibleZ + 0.01) continue;

      _drawVoxel(canvas, v, origin, growth: growth);
    }

    _drawFrontierLine(canvas, origin, frontier);
  }

  void _drawSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A1A), Color(0xFF221A2A), Color(0xFF3A2628)],
          stops: [0, 0.6, 1],
        ).createShader(rect),
    );
  }

  void _drawBaseline(Canvas canvas, Offset origin) {
    // Draw a subtle ground plane (dotted diamond grid)
    final paint = Paint()
      ..color = const Color.fromRGBO(196, 123, 90, 0.15)
      ..style = PaintingStyle.fill;
    for (int x = 0; x < PilgrimCLandscape.gridW; x += 3) {
      for (int y = 0; y < PilgrimCLandscape.gridH; y += 3) {
        final c = _project(x + 0.5, y + 0.5, 0, origin);
        canvas.drawCircle(c, 0.6, paint);
      }
    }
  }

  void _drawFrontierLine(Canvas canvas, Offset origin, int frontier) {
    // A subtle gold "growth wave" — vertical band at the current frontier
    final a = _project(frontier.toDouble(), 0, 0, origin);
    final b = _project(
        frontier.toDouble(), PilgrimCLandscape.gridH.toDouble() - 1, 0, origin);
    final pulse = 0.5 + 0.5 * sin(glowAnimation * 2 * pi);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color.fromRGBO(212, 168, 67, 0.35 * pulse),
          Color.fromRGBO(212, 168, 67, 0.05 * pulse),
        ],
      ).createShader(Rect.fromPoints(a, b))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(a, b, paint);
  }

  Offset _project(double x, double y, double z, Offset origin) => Offset(
        origin.dx + (x - y) * _cos30 * _block,
        origin.dy + (x + y) * _sin30 * _block - z * _block,
      );

  void _drawVoxel(Canvas canvas, PilgrimCVoxel v, Offset origin,
      {bool isPath = false, bool highlight = false, double growth = 1.0}) {
    final base = _colorFor(v);
    final tinted = growth < 0.85
        ? Color.fromRGBO(
            (base.r * 255).round(),
            (base.g * 255).round(),
            (base.b * 255).round(),
            0.6 + 0.4 * growth,
          )
        : base;
    final (t, l, r) = _shade(tinted);
    _drawCube(canvas, v.x.toDouble(), v.y.toDouble(), v.z.toDouble(),
        origin, t, l, r);

    if (highlight) {
      final c = _project(v.x + 0.5, v.y + 0.5, v.z + 0.5, origin);
      final pulse = 0.5 + 0.5 * sin(glowAnimation * 2 * pi);
      canvas.drawCircle(
        c,
        10 + pulse * 4,
        Paint()
          ..color = Color.fromRGBO(245, 212, 103, 0.4 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  void _drawCube(Canvas canvas, double x, double y, double z, Offset origin,
      Color top, Color left, Color right) {
    final bs = _block;
    final c = _project(x + 0.5, y + 0.5, z.toDouble(), origin);
    final topPath = Path()
      ..moveTo(c.dx, c.dy - _sin30 * bs)
      ..lineTo(c.dx + _cos30 * bs, c.dy)
      ..lineTo(c.dx, c.dy + _sin30 * bs)
      ..lineTo(c.dx - _cos30 * bs, c.dy)
      ..close();
    canvas.drawPath(topPath, Paint()..color = top);

    final leftPath = Path()
      ..moveTo(c.dx - _cos30 * bs, c.dy)
      ..lineTo(c.dx, c.dy + _sin30 * bs)
      ..lineTo(c.dx, c.dy + _sin30 * bs + bs)
      ..lineTo(c.dx - _cos30 * bs, c.dy + bs)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = left);

    final rightPath = Path()
      ..moveTo(c.dx + _cos30 * bs, c.dy)
      ..lineTo(c.dx, c.dy + _sin30 * bs)
      ..lineTo(c.dx, c.dy + _sin30 * bs + bs)
      ..lineTo(c.dx + _cos30 * bs, c.dy + bs)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = right);
  }

  (Color, Color, Color) _shade(Color base) {
    Color d(Color c, double f) => Color.fromARGB(
          c.a.round(),
          (c.r * 255 * f).clamp(0, 255).round(),
          (c.g * 255 * f).clamp(0, 255).round(),
          (c.b * 255 * f).clamp(0, 255).round(),
        );
    return (base, d(base, 0.72), d(base, 0.55));
  }

  Color _colorFor(PilgrimCVoxel v) {
    switch (v.type) {
      case PilgrimCVoxelType.terrainLow: return const Color(0xFF3B2A1E);
      case PilgrimCVoxelType.terrainMid: return const Color(0xFF5E5234);
      case PilgrimCVoxelType.terrainHigh: return const Color(0xFF897246);
      case PilgrimCVoxelType.terrainPeak: return const Color(0xFFB89464);
      case PilgrimCVoxelType.swampMud: return const Color(0xFF2A1F14);
      case PilgrimCVoxelType.swampWater: return const Color(0xFF1A2633);
      case PilgrimCVoxelType.interpreterHouse: return const Color(0xFFC7BFAE);
      case PilgrimCVoxelType.interpreterRoof: return const Color(0xFF7A4A22);
      case PilgrimCVoxelType.valleyHumble: return const Color(0xFF3B4A3B);
      case PilgrimCVoxelType.valleyShadow: return const Color(0xFF0B0B12);
      case PilgrimCVoxelType.shiningPeak:
        final p = 0.8 + 0.2 * sin(glowAnimation * 2 * pi);
        return Color.fromRGBO(232, 198, 122, p);
      case PilgrimCVoxelType.jordanRiver:
        final p = 0.75 + 0.25 * sin(glowAnimation * 2 * pi);
        return Color.fromRGBO(106, 158, 191, p);
      case PilgrimCVoxelType.celestialWall: return const Color(0xFFB88C3D);
      case PilgrimCVoxelType.celestialTower:
        final p = 0.85 + 0.15 * sin(glowAnimation * 2 * pi);
        return Color.fromRGBO(227, 182, 86, p);
      case PilgrimCVoxelType.celestialGate: return const Color(0xFFF5E3A0);
      case PilgrimCVoxelType.tree: return const Color(0xFF3E5A3E);
      case PilgrimCVoxelType.bush: return const Color(0xFF57734E);
      case PilgrimCVoxelType.cloud: return const Color(0xFFD8D4E0);
      case PilgrimCVoxelType.pathStone: return const Color(0xFFE9A583);
    }
  }

  @override
  bool shouldRepaint(covariant PilgrimC2Painter old) =>
      old.glowAnimation != glowAnimation ||
      old.introAnimation != introAnimation ||
      old.readChapters != readChapters;
}
