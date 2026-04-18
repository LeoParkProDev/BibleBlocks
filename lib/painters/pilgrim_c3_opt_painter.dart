import 'dart:math';
import 'package:flutter/material.dart';

import 'pilgrim_c_mountain_painter.dart';

// C3.opt — Light of Revelation with P1 optimizations applied:
//   1. Pre-sorted voxel list built once (voxel positions are static, so the
//      depth-order never changes across frames).
//   2. Terrain compressed to the top 2 slabs per column (lower slabs are
//      hidden by their neighbours in an isometric projection anyway).
//   3. Per-frame fog culling — voxels past the reader's visibility horizon
//      are skipped instead of drawn as near-black fog.
//
// Target: match Noah's Ark / Solomon's Temple performance on web.

class PilgrimC3OptPainter extends CustomPainter {
  final double glowAnimation;
  final double introAnimation;
  final int readChapters;

  PilgrimC3OptPainter({
    required this.glowAnimation,
    required this.introAnimation,
    required this.readChapters,
  });

  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;
  static const double _block = 7.0;
  static const double _litCullThreshold = 0.12;
  static const double _litFalloffCols = 10.0;

  // Pre-sorted, slab-filtered voxel list. Built once on first access.
  static List<PilgrimCVoxel>? _cached;
  static int _terrainVoxelCount = 0;

  static List<PilgrimCVoxel> get _voxels {
    if (_cached != null) return _cached!;
    final all = PilgrimCLandscape.voxels;
    final hm = PilgrimCLandscape.heightmap;
    final out = <PilgrimCVoxel>[];
    int terrainCount = 0;
    for (final v in all) {
      final isHeightmap = v.type == PilgrimCVoxelType.terrainLow ||
          v.type == PilgrimCVoxelType.terrainMid ||
          v.type == PilgrimCVoxelType.terrainHigh ||
          v.type == PilgrimCVoxelType.terrainPeak;
      if (isHeightmap) {
        final h = hm[v.x][v.y];
        // Keep only the top 2 slabs — lower slabs are occluded anyway
        if (v.z < h - 1) continue;
        terrainCount++;
      }
      out.add(v);
    }
    out.sort((a, b) {
      final da = a.x + a.y - a.z * 0.1;
      final db = b.x + b.y - b.z * 0.1;
      return da.compareTo(db);
    });
    _cached = out;
    _terrainVoxelCount = terrainCount;
    return out;
  }

  static int get cachedVoxelCount {
    if (_cached == null) _voxels;
    return _cached!.length;
  }

  static int get cachedTerrainCount {
    if (_cached == null) _voxels;
    return _terrainVoxelCount;
  }

  double get _progress =>
      (readChapters.clamp(0, PilgrimCLandscape.totalChapters) /
              PilgrimCLandscape.totalChapters)
          .toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);

    const cx = (PilgrimCLandscape.gridW - 1) / 2.0;
    const cy = (PilgrimCLandscape.gridH - 1) / 2.0;
    final origin = Offset(
      size.width * 0.5 - (cx - cy) * _cos30 * _block,
      size.height * 0.55 - (cx + cy) * _sin30 * _block,
    );

    final pathLen = PilgrimCLandscape.pathLength;
    final litStones = (_progress * pathLen).floor();

    // Frontier column (highest x reached by a read path stone)
    int frontier = 0;
    for (final v in _voxels) {
      if (v.pathIndex >= 0 && v.pathIndex <= litStones && v.x > frontier) {
        frontier = v.x;
      }
    }

    final intro = introAnimation.clamp(0.0, 1.0);
    final voxels = _voxels;

    for (final v in voxels) {
      // Intro stagger (west-to-east)
      final orderRatio = v.x / PilgrimCLandscape.gridW;
      if (orderRatio > intro * 1.1) continue;

      final isPath = v.pathIndex >= 0;
      if (isPath) {
        if (v.pathIndex <= litStones) {
          _drawVoxel(canvas, v, origin, litFactor: 1.0,
              highlight: v.pathIndex == litStones - 1);
        } else {
          _drawWireframe(canvas, v, origin);
        }
        continue;
      }

      // Non-path: fog falloff ahead of frontier, with hard cull when too dim
      final distAhead = v.x - frontier;
      final lit = distAhead <= 0
          ? 1.0
          : (1.0 - distAhead / _litFalloffCols);
      if (lit < _litCullThreshold) continue; // culled — off-stage
      _drawVoxel(canvas, v, origin, litFactor: lit);
    }

    _drawCelestialRadiance(canvas, size, origin);
  }

  void _drawSky(Canvas canvas, Size size) {
    final p = _progress;
    final topCol = Color.lerp(
      const Color(0xFF050510),
      const Color(0xFF3A2448),
      (p * 2).clamp(0, 1),
    )!;
    final midCol = Color.lerp(
      const Color(0xFF1A1420),
      const Color(0xFFC47B5A),
      p,
    )!;
    final horizonCol = Color.lerp(
      const Color(0xFF2A1A18),
      const Color(0xFFF5D467),
      p,
    )!;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topCol, midCol, horizonCol],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );

    final sunY = size.height * (0.75 - p * 0.35);
    final sunX = size.width * (0.3 + p * 0.4);
    final sunCol = Color.lerp(
      const Color(0xFFB85A3A),
      const Color(0xFFFDE9A8),
      p,
    )!;
    canvas.drawCircle(
      Offset(sunX, sunY),
      18 + p * 14,
      Paint()
        ..color = sunCol
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  void _drawCelestialRadiance(Canvas canvas, Size size, Offset origin) {
    final p = _progress;
    final radiance = pow(p, 2).toDouble();
    if (radiance < 0.05) return;
    final cityPos = _project(
      (PilgrimCLandscape.gridW - 4).toDouble(),
      3,
      8,
      origin,
    );
    final pulse = 0.7 + 0.3 * sin(glowAnimation * 2 * pi);
    canvas.drawCircle(
      cityPos,
      80 + 60 * radiance,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(245, 212, 103, 0.45 * radiance * pulse),
            const Color(0x00F5D467),
          ],
        ).createShader(Rect.fromCircle(
            center: cityPos, radius: 80 + 60 * radiance))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  Offset _project(double x, double y, double z, Offset origin) => Offset(
        origin.dx + (x - y) * _cos30 * _block,
        origin.dy + (x + y) * _sin30 * _block - z * _block,
      );

  void _drawVoxel(Canvas canvas, PilgrimCVoxel v, Offset origin,
      {required double litFactor, bool highlight = false}) {
    final base = _colorFor(v);
    final lit = _applyLit(base, litFactor);
    final (t, l, r) = _shade(lit);
    _drawCube(canvas, v.x.toDouble(), v.y.toDouble(), v.z.toDouble(),
        origin, t, l, r);

    if (highlight) {
      final c = _project(v.x + 0.5, v.y + 0.5, v.z + 0.5, origin);
      final pulse = 0.5 + 0.5 * sin(glowAnimation * 2 * pi);
      canvas.drawCircle(
        c,
        12 + pulse * 4,
        Paint()
          ..color = Color.fromRGBO(245, 212, 103, 0.4 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  void _drawWireframe(Canvas canvas, PilgrimCVoxel v, Offset origin) {
    final bs = _block;
    final center = _project(v.x + 0.5, v.y + 0.5, v.z.toDouble(), origin);
    final paint = Paint()
      ..color = const Color.fromRGBO(196, 123, 90, 0.2)
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

  Color _applyLit(Color base, double lit) {
    const fog = Color(0xFF0A0A1A);
    return Color.lerp(fog, base, lit.clamp(0.0, 1.0))!;
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
  bool shouldRepaint(covariant PilgrimC3OptPainter old) =>
      old.glowAnimation != glowAnimation ||
      old.introAnimation != introAnimation ||
      old.readChapters != readChapters;
}
