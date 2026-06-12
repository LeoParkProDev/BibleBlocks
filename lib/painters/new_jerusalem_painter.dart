import 'dart:math';
import 'package:flutter/material.dart';

import '../data/bible_data.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import 'block_hit_test.dart';

// ---------------------------------------------------------------------------
// New Jerusalem — descending city of light (Revelation 21)
//
// Voxel-list based map (same pattern as NoahsArk / SolomonsTemple).
// Build order encodes the narrative progression: as chapters are read the
// city rises in stages —
//   plaza ring -> jasper wall + 12 pearl gates -> 12 jeweled foundations ->
//   towers rising -> central golden temple -> crowning spire.
// `structuralIndex` is assigned in that build order so reading progress maps
// linearly to "the city being raised". Read voxels are solid (jewel / gold /
// light); unread voxels render as a ghost wireframe so the whole city outline
// is visible even at 0%.
// ---------------------------------------------------------------------------

enum CityVoxelType {
  plaza,
  wall,
  gate,
  jewel,
  tower,
  roof,
  temple,
  spire,
}

class CityVoxel {
  final int x;
  final int y;
  final int z;
  final CityVoxelType type;

  /// Sequential index among structural voxels (chapter-mapped). Always >= 0.
  final int structuralIndex;

  /// For gates / jewels — the per-gate jewel color index (0..11), else -1.
  final int jewelIndex;

  const CityVoxel({
    required this.x,
    required this.y,
    required this.z,
    required this.type,
    required this.structuralIndex,
    this.jewelIndex = -1,
  });
}

/// Builds the full New Jerusalem voxel list in narrative build order.
List<CityVoxel> buildCityVoxels() {
  final voxels = <CityVoxel>[];
  int idx = 0;

  const int radius = 9; // city / wall radius in grid units

  // Tracks occupied (x,y,z) cells for z>=1 so structures never stack on the
  // same cell — duplicate positions would break the hit-test lookup.
  final occupied = <String>{};
  bool claim(int x, int y, int z) => occupied.add('$x,$y,$z');

  // -------------------------------------------------------------------------
  // 1) Plaza floor (z=0) — center outward. A filled disk of radius `radius`.
  // -------------------------------------------------------------------------
  final plaza = <CityVoxel>[];
  for (int x = -radius; x <= radius; x++) {
    for (int y = -radius; y <= radius; y++) {
      final d = sqrt((x * x + y * y).toDouble());
      if (d <= radius - 0.3) {
        plaza.add(CityVoxel(
          x: x, y: y, z: 0,
          type: CityVoxelType.plaza,
          structuralIndex: 0, // assigned below after sorting center-outward
        ));
      }
    }
  }
  // Lay the plaza from the center outward so it "spreads".
  plaza.sort((a, b) {
    final da = a.x * a.x + a.y * a.y;
    final db = b.x * b.x + b.y * b.y;
    return da.compareTo(db);
  });
  for (final p in plaza) {
    voxels.add(CityVoxel(
      x: p.x, y: p.y, z: 0,
      type: CityVoxelType.plaza,
      structuralIndex: idx++,
    ));
  }

  // -------------------------------------------------------------------------
  // 2) Wall ring (z=1..3) with 12 gates. Walk the circle in 5° steps and
  //    snap to the grid; dedup so we don't stack voxels on the same cell.
  // -------------------------------------------------------------------------
  const int wallHeight = 3;
  for (int a = 0; a < 360; a += 5) {
    final rad = a * pi / 180;
    final wx = (cos(rad) * radius).round();
    final wy = (sin(rad) * radius).round();
    final gateSlot = (a / 30).round() % 12;
    final isGate = (a - gateSlot * 30).abs() < 5;
    for (int z = 1; z <= wallHeight; z++) {
      if (!claim(wx, wy, z)) continue;
      final gate = isGate && z <= 2;
      voxels.add(CityVoxel(
        x: wx, y: wy, z: z,
        type: gate ? CityVoxelType.gate : CityVoxelType.wall,
        structuralIndex: idx++,
        jewelIndex: gate ? gateSlot : -1,
      ));
    }
  }

  // -------------------------------------------------------------------------
  // 3) Jeweled foundation studs — one per gate, just inside the wall.
  // -------------------------------------------------------------------------
  for (int g = 0; g < 12; g++) {
    final a = g * 30 * pi / 180;
    final jx = (cos(a) * (radius - 1)).round();
    final jy = (sin(a) * (radius - 1)).round();
    if (!claim(jx, jy, 1)) continue;
    voxels.add(CityVoxel(
      x: jx, y: jy, z: 1,
      type: CityVoxelType.jewel,
      structuralIndex: idx++,
      jewelIndex: g,
    ));
  }

  // -------------------------------------------------------------------------
  // 4) Towers — two concentric rings of buildings rising toward the center.
  // -------------------------------------------------------------------------
  // Inner ring sits at r=4.6 so its rounded grid cells clear the ±3 temple
  // base footprint, leaving the central golden ziggurat unobstructed.
  const towerRings = [
    (r: 6.2, n: 8, h: 4),
    (r: 4.6, n: 6, h: 6),
  ];
  final towerColumns = <String>{};
  for (int ri = 0; ri < towerRings.length; ri++) {
    final ring = towerRings[ri];
    for (int i = 0; i < ring.n; i++) {
      final a = (i / ring.n) * pi * 2 + ri * 0.4;
      final tx = (cos(a) * ring.r).round();
      final ty = (sin(a) * ring.r).round();
      final colKey = '$tx,$ty';
      if (towerColumns.contains(colKey)) continue;
      towerColumns.add(colKey);
      final h = ring.h + (i % 2);
      for (int z = 1; z <= h; z++) {
        if (!claim(tx, ty, z)) continue;
        voxels.add(CityVoxel(
          x: tx, y: ty, z: z,
          type: CityVoxelType.tower,
          structuralIndex: idx++,
        ));
      }
      // Roof cap
      if (claim(tx, ty, h + 1)) {
        voxels.add(CityVoxel(
          x: tx, y: ty, z: h + 1,
          type: CityVoxelType.roof,
          structuralIndex: idx++,
        ));
      }
    }
  }

  // -------------------------------------------------------------------------
  // 5) Central temple — stepped golden ziggurat at the city center.
  // -------------------------------------------------------------------------
  const int templeHeight = 8;
  for (int z = 1; z <= templeHeight; z++) {
    final half = max(0, ((templeHeight - z) / 2.2).round());
    for (int x = -half; x <= half; x++) {
      for (int y = -half; y <= half; y++) {
        if (!claim(x, y, z)) continue;
        voxels.add(CityVoxel(
          x: x, y: y, z: z,
          type: CityVoxelType.temple,
          structuralIndex: idx++,
        ));
      }
    }
  }

  // -------------------------------------------------------------------------
  // 6) Crowning spire.
  // -------------------------------------------------------------------------
  claim(0, 0, templeHeight + 1);
  voxels.add(CityVoxel(
    x: 0, y: 0, z: templeHeight + 1,
    type: CityVoxelType.spire,
    structuralIndex: idx++,
  ));

  return voxels;
}

/// Cached city voxel list (lazy).
List<CityVoxel>? _cachedCityVoxels;
List<CityVoxel> get cityVoxels {
  _cachedCityVoxels ??= buildCityVoxels();
  return _cachedCityVoxels!;
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class NewJerusalemPainter extends CustomPainter {
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

  NewJerusalemPainter({
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

  /// Every voxel here is structural (chapter-mapped).
  static int get totalStructuralBlocks => cityVoxels.length;

  // ---------------------------------------------------------------------------
  // Colors — jasper-pale walls, jewel gates, golden towers & temple, light spire
  // ---------------------------------------------------------------------------
  static const Color _plazaTop = Color(0xFFCAA24A);
  static const Color _wallTop = Color(0xFFBFAE8A); // jasper-ish pale
  static const Color _towerTop = Color(0xFFD8B25A);
  static const Color _roofTop = Color(0xFFE3C071);
  static const Color _templeTop = Color(0xFFE8C668);
  static const Color _spireTop = Color(0xFFFFF0B8);

  /// 12 foundation/gate jewels (Rev 21:19-20 inspired palette).
  static const List<Color> _jewels = [
    Color(0xFF3FA9C4),
    Color(0xFF3F5FC4),
    Color(0xFF5FC47A),
    Color(0xFF50C878),
    Color(0xFFC45F9A),
    Color(0xFFC44F4F),
    Color(0xFFC4A83F),
    Color(0xFF7AC4B0),
    Color(0xFFC4C43F),
    Color(0xFF5FC4A0),
    Color(0xFF9A5FC4),
    Color(0xFFA05FC4),
  ];

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

  Color _topColorFor(CityVoxel v) {
    switch (v.type) {
      case CityVoxelType.plaza:
        return _plazaTop;
      case CityVoxelType.wall:
        return _wallTop;
      case CityVoxelType.gate:
        return v.jewelIndex >= 0 ? _jewels[v.jewelIndex] : _spireTop;
      case CityVoxelType.jewel:
        return v.jewelIndex >= 0 ? _jewels[v.jewelIndex] : _spireTop;
      case CityVoxelType.tower:
        return _towerTop;
      case CityVoxelType.roof:
        return _roofTop;
      case CityVoxelType.temple:
        return _templeTop;
      case CityVoxelType.spire:
        return _spireTop;
    }
  }

  double _depthKey(CityVoxel v) {
    final cosA = cos(rotationAngle);
    final sinA = sin(rotationAngle);
    final cx = v.x + 0.5;
    final cy = v.y + 0.5;
    final rotatedX = cx * cosA - cy * sinA;
    final rotatedY = cx * sinA + cy * cosA;
    // Back-to-front: larger key rendered last (on top).
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
    final origin = Offset(size.width / 2, size.height * 0.62);

    // Descending halo of the city in the sky.
    _drawHalo(canvas, size, origin);

    if (isComplete && glowAnimation > 0) {
      _drawCompletionGlow(canvas, size, origin);
    }

    final all = cityVoxels;
    final sorted = List<CityVoxel>.from(all)
      ..sort((a, b) => _depthKey(a).compareTo(_depthKey(b)));

    final total = totalStructuralBlocks;
    bool spireBuilt = false;

    for (final v in sorted) {
      final sIdx = v.structuralIndex;
      final globalStart =
          (sIdx * BibleData.totalChapters / total).floor();
      final globalEnd =
          ((sIdx + 1) * BibleData.totalChapters / total).floor();

      int readCount = 0;
      final totalCount = max(1, globalEnd - globalStart);
      for (int g = globalStart; g < globalEnd; g++) {
        if (ProgressService.isGlobalIndexRead(progressData, g)) readCount++;
      }
      final fillRatio = readCount / totalCount;

      // Intro animation: voxels appear in build order, bottom-up.
      double introOpacity = 1.0;
      double introZOff = 0.0;
      if (introAnimation < 1.0) {
        final blockDelay = (sIdx / total * 0.6).clamp(0.0, 0.6);
        final localT = ((introAnimation - blockDelay) / 0.4).clamp(0.0, 1.0);
        introOpacity = localT;
        introZOff = (1.0 - localT) * 3.0;
      }
      if (introOpacity <= 0) continue;

      // Proximity float + bounce.
      double zOffset = _proximityZOffset(
          v.x.toDouble(), v.y.toDouble(), v.z.toDouble(), origin);
      final isPressed = pressedBlock != null &&
          pressedBlock!.x == v.x &&
          pressedBlock!.y == v.y &&
          pressedBlock!.z == v.z;
      if (isPressed) zOffset += _bounceZOffset;
      final effectiveZ = v.z.toDouble() + zOffset;

      // Fill animation for newly-filled voxels.
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
            _topColorFor(v).withValues(alpha: alpha));
        if (v.type == CityVoxelType.spire) spireBuilt = true;
        _maybeSparkle(canvas, origin, v, drawZ, alpha);
      } else if (readCount > 0) {
        final baseAlpha = (0.18 + fillRatio * 0.4) * alpha;
        _drawCube(canvas, origin, v.x.toDouble(), v.y.toDouble(), drawZ,
            _topColorFor(v).withValues(alpha: baseAlpha));
      } else {
        // Ghost wireframe — the whole city outline visible even at 0%.
        if (introAnimation >= 1.0) {
          _drawWireframeCube(
              canvas, origin, v.x.toDouble(), v.y.toDouble(), effectiveZ);
        }
      }

      // Selection (푸른톤) > hover (골드) 우선.
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

    // Crowning light beam once the temple/spire is complete.
    if (spireBuilt) {
      _drawLightBeam(canvas, size, origin);
    }

    if (isComplete && glowAnimation > 0) {
      _drawParticles(canvas, size, origin);
    }
  }

  void _maybeSparkle(
      Canvas canvas, Offset origin, CityVoxel v, double z, double alpha) {
    if (v.type != CityVoxelType.jewel && v.type != CityVoxelType.gate) return;
    final p = project(v.x + 0.5, v.y + 0.5, z + 0.5, origin);
    final tw = 0.5 + 0.5 * sin(glowAnimation * 2 * pi * 3 + v.structuralIndex);
    final color = _topColorFor(v);
    final paint = Paint()
      ..color = color.withValues(alpha: (0.35 * tw * alpha).clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(p, blockSize * 0.9, paint);
  }

  void _drawHalo(Canvas canvas, Size size, Offset origin) {
    final progress =
        (ProgressService.totalRead(progressData) / BibleData.totalChapters)
            .clamp(0.0, 1.0);
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.gold.withValues(alpha: 0.05 + 0.05 * progress),
          AppColors.gold.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
            center: Offset(origin.dx, origin.dy - size.height * 0.12),
            radius: size.width * 0.42),
      );
    canvas.drawRect(Offset.zero & size, haloPaint);
  }

  void _drawLightBeam(Canvas canvas, Size size, Offset origin) {
    final apex = project(0.5, 0.5, 11, origin);
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _spireTop.withValues(alpha: 0.0),
          _spireTop.withValues(alpha: 0.28),
          _spireTop.withValues(alpha: 0.6),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTRB(0, 0, size.width, apex.dy.clamp(0, size.height)));
    final bw = blockSize * 1.8;
    final path = Path()
      ..moveTo(apex.dx - bw * 0.4, 0)
      ..lineTo(apex.dx + bw * 0.4, 0)
      ..lineTo(apex.dx + bw, apex.dy)
      ..lineTo(apex.dx - bw, apex.dy)
      ..close();
    canvas.drawPath(path, beamPaint);

    final glowPaint = Paint()
      ..color = _spireTop.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(apex, blockSize * 4.0, glowPaint);

    // Descending light motes.
    final motePaint = Paint();
    for (int i = 0; i < 14; i++) {
      final ph = (glowAnimation * 0.5 + i / 14) % 1.0;
      final yy = ph * apex.dy;
      motePaint.color = _spireTop.withValues(alpha: 0.6 * (1 - ph));
      canvas.drawCircle(
        Offset(apex.dx + sin(i * 2 + glowAnimation * 2 * pi) * bw * 0.6, yy),
        1.8,
        motePaint,
      );
    }
  }

  void _drawCube(
      Canvas canvas, Offset origin, double x, double y, double z, Color topColor) {
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
  bool shouldRepaint(covariant NewJerusalemPainter oldDelegate) {
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
