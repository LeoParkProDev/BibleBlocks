import 'dart:math';
import 'package:flutter/material.dart';

import 'pilgrim_c_mountain_painter.dart';

// C1 — Progressive Paving
// Terrain always visible. Path stones appear as solid voxels only up to
// readChapters; unread stones show as faint wireframe outlines. Landmarks
// fade in once the path has reached their column.

class PilgrimC1Painter extends CustomPainter {
  final double glowAnimation;
  final double introAnimation;
  final int readChapters;

  PilgrimC1Painter({
    required this.glowAnimation,
    required this.introAnimation,
    required this.readChapters,
  });

  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;
  static const double _block = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);

    const cx = (PilgrimCLandscape.gridW - 1) / 2.0;
    const cy = (PilgrimCLandscape.gridH - 1) / 2.0;
    final origin = Offset(
      size.width * 0.5 - (cx - cy) * _cos30 * _block,
      size.height * 0.55 - (cx + cy) * _sin30 * _block,
    );

    final voxels = PilgrimCLandscape.voxels;
    final pathLen = PilgrimCLandscape.pathLength;
    final litStones =
        (readChapters.clamp(0, PilgrimCLandscape.totalChapters) *
                pathLen /
                PilgrimCLandscape.totalChapters)
            .floor();

    // Compute the path's furthest reached x column (for landmark reveal)
    int frontierX = 0;
    for (final v in voxels) {
      if (v.pathIndex >= 0 && v.pathIndex <= litStones && v.x > frontierX) {
        frontierX = v.x;
      }
    }
    // Buffer so adjacent terrain/features feel inhabited, not a hard edge
    final revealX = frontierX + 3;

    final sorted = [...voxels]
      ..sort((a, b) {
        final da = a.x + a.y - a.z * 0.1;
        final db = b.x + b.y - b.z * 0.1;
        return da.compareTo(db);
      });

    final intro = introAnimation.clamp(0.0, 1.0);

    for (final v in sorted) {
      final isPath = v.pathIndex >= 0;
      final litPath = isPath && v.pathIndex <= litStones;
      final unlit = isPath && !litPath;
      final terrain = !isPath;

      // Always-visible terrain (heightmap columns). Features fade with frontier.
      final isHeightmap = v.type == PilgrimCVoxelType.terrainLow ||
          v.type == PilgrimCVoxelType.terrainMid ||
          v.type == PilgrimCVoxelType.terrainHigh ||
          v.type == PilgrimCVoxelType.terrainPeak;

      if (terrain && !isHeightmap && v.x > revealX) {
        continue; // hide unreached landmarks
      }
      // Intro stagger — west-to-east reveal on first load
      final orderRatio = v.x / PilgrimCLandscape.gridW;
      if (orderRatio > intro * 1.1) continue;

      if (unlit) {
        _drawWireframe(canvas, v, origin);
      } else if (litPath) {
        _drawVoxel(canvas, v, origin, highlight: v.pathIndex == litStones - 1);
      } else {
        _drawVoxel(canvas, v, origin);
      }
    }
  }

  void _drawSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A1A), Color(0xFF1F1522), Color(0xFF3A2820)],
          stops: [0, 0.6, 1],
        ).createShader(rect),
    );
  }

  Offset _project(double x, double y, double z, Offset origin) => Offset(
        origin.dx + (x - y) * _cos30 * _block,
        origin.dy + (x + y) * _sin30 * _block - z * _block,
      );

  void _drawVoxel(Canvas canvas, PilgrimCVoxel v,
      Offset origin, {bool highlight = false}) {
    final base = _colorFor(v);
    final (t, l, r) = _shade(base);
    _drawCube(canvas, v.x.toDouble(), v.y.toDouble(), v.z.toDouble(), origin, t, l, r);

    if (highlight) {
      final c = _project(v.x + 0.5, v.y + 0.5, v.z + 0.5, origin);
      final pulse = 0.5 + 0.5 * sin(glowAnimation * 2 * pi);
      canvas.drawCircle(
        c,
        8 + pulse * 3,
        Paint()
          ..color = Color.fromRGBO(245, 212, 103, 0.35 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  void _drawWireframe(Canvas canvas, PilgrimCVoxel v, Offset origin) {
    final bs = _block;
    final center = _project(v.x + 0.5, v.y + 0.5, v.z.toDouble(), origin);
    final paint = Paint()
      ..color = const Color.fromRGBO(196, 123, 90, 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    final top = Path()
      ..moveTo(center.dx, center.dy - _sin30 * bs)
      ..lineTo(center.dx + _cos30 * bs, center.dy)
      ..lineTo(center.dx, center.dy + _sin30 * bs)
      ..lineTo(center.dx - _cos30 * bs, center.dy)
      ..close();
    canvas.drawPath(top, paint);
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
  bool shouldRepaint(covariant PilgrimC1Painter old) =>
      old.glowAnimation != glowAnimation ||
      old.introAnimation != introAnimation ||
      old.readChapters != readChapters;
}
