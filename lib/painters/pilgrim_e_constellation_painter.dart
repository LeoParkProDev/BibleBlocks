import 'dart:math';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// PilgrimE Constellation Painter
// ---------------------------------------------------------------------------
// John Bunyan's "Pilgrim's Progress" themed voxel constellation map for
// BibleBlocks. Renders a 3D night sky with:
//   * City of Destruction (bottom-left, dark red stars)
//   * Cross constellation
//   * King's Highway (long curved gold path)
//   * Doubting Castle cluster (dark clump)
//   * Celestial City (top-center, 12-star crown + gold aura)
//   * Pilgrim star (the traveller, pulsing, on the path)
//   * ~1,189 total voxel stars — path + background scatter
// ---------------------------------------------------------------------------

/// A voxel star positioned in 3D scene space.
class PilgrimStar {
  final double x;
  final double y;
  final double z;
  final int size; // 1 = 1x1x1, 2 = 2x2x2
  final Color color;
  final double baseAlpha;
  final StarKind kind;
  final int pathOrder; // sequential index along the straight-and-narrow path; -1 = background

  const PilgrimStar({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    required this.color,
    required this.baseAlpha,
    required this.kind,
    this.pathOrder = -1,
  });
}

enum StarKind {
  // Background scatter — faint blue dust
  backgroundBlue,
  // Distant nebula specks — deep indigo
  nebula,
  // The narrow path between City of Destruction and Celestial City
  path,
  // Temptation stars near the path — bluish, unconnected
  temptation,
  // City of Destruction landmark — dark crimson
  cityOfDestruction,
  // Cross constellation — bright gold
  cross,
  // King's Highway — long gold chain
  kingsHighway,
  // Doubting Castle — dark violet clump
  doubtingCastle,
  // Celestial City crown — brightest gold, pulsing
  celestialCity,
  // Pilgrim star — larger, pulses strongly
  pilgrim,
}

/// Connections between stars (gold luminous lines).
class StarLink {
  final int fromIndex;
  final int toIndex;
  final double intensity; // 0..1

  const StarLink(this.fromIndex, this.toIndex, {this.intensity = 1.0});
}

// ---------------------------------------------------------------------------
// Scene builder — deterministic (seeded).
// ---------------------------------------------------------------------------

class PilgrimSceneData {
  final List<PilgrimStar> stars;
  final List<StarLink> links;
  final int pathCount;
  final int pilgrimIndex;
  final int celestialCityCenterIndex;

  const PilgrimSceneData({
    required this.stars,
    required this.links,
    required this.pathCount,
    required this.pilgrimIndex,
    required this.celestialCityCenterIndex,
  });

  static late final PilgrimSceneData _cache;
  static bool _built = false;

  static PilgrimSceneData get instance {
    if (!_built) {
      _cache = _build();
      _built = true;
    }
    return _cache;
  }

  static PilgrimSceneData _build() {
    final stars = <PilgrimStar>[];
    final links = <StarLink>[];

    // Scene extents (isometric scene coordinates, roughly -22..22 in x/y, 0..30 in z).
    // Path travels from (x=-16, y=14, z=2) → (x=12, y=-14, z=26) with a gentle curve.

    // ------------------- 1. City of Destruction (bottom-left/low) ---------
    // A dark red clump near the start of the path.
    final cocRand = Random(11);
    final cocCenter = _V3(-17, 16, 2);
    for (int i = 0; i < 22; i++) {
      final dx = (cocRand.nextDouble() - 0.5) * 5.5;
      final dy = (cocRand.nextDouble() - 0.5) * 5.5;
      final dz = cocRand.nextDouble() * 2.0;
      stars.add(PilgrimStar(
        x: cocCenter.x + dx,
        y: cocCenter.y + dy,
        z: cocCenter.z + dz,
        size: 1,
        color: const Color(0xFF6B1F1F),
        baseAlpha: 0.55 + cocRand.nextDouble() * 0.25,
        kind: StarKind.cityOfDestruction,
      ));
    }

    // ------------------- 2. The Narrow Path (main gold chain) -------------
    // Travels lower-left to upper-right with a graceful curve that rises in z.
    const pathStars = 260; // a sizeable fraction of 1189
    final pathStartIndex = stars.length;
    for (int i = 0; i < pathStars; i++) {
      final t = i / (pathStars - 1);
      // Base linear travel
      final bx = _lerp(-16.0, 12.0, t);
      final by = _lerp(14.0, -14.0, t);
      final bz = _lerp(2.0, 26.0, t);
      // Curve: gentle sine bow pushing up & to the side.
      final curveX = sin(t * pi) * 3.2;
      final curveY = sin(t * pi) * -2.0;
      final curveZ = sin(t * pi) * 3.5;
      // Light jitter to avoid robotic feel.
      final jr = Random(3000 + i);
      final jx = (jr.nextDouble() - 0.5) * 0.9;
      final jy = (jr.nextDouble() - 0.5) * 0.9;
      final jz = (jr.nextDouble() - 0.5) * 0.6;

      // Occasional larger stars along path
      final isBig = i % 14 == 3;
      final ivory = Color.lerp(
        const Color(0xFFFFE7A8),
        const Color(0xFFFFF4D1),
        jr.nextDouble(),
      )!;

      stars.add(PilgrimStar(
        x: bx + curveX + jx,
        y: by + curveY + jy,
        z: bz + curveZ + jz,
        size: isBig ? 2 : 1,
        color: ivory,
        baseAlpha: 0.85 + jr.nextDouble() * 0.15,
        kind: StarKind.path,
        pathOrder: i,
      ));
    }
    final pathEndIndex = stars.length - 1;

    // Connect consecutive path stars (narrow luminous line).
    for (int i = 0; i < pathStars - 1; i++) {
      links.add(StarLink(pathStartIndex + i, pathStartIndex + i + 1));
    }

    // ------------------- 3. Pilgrim star (traveller) ----------------------
    // Sits ~40% along the path — between Slough of Despond and Cross.
    final pilgrimBase = stars[pathStartIndex + (pathStars * 0.42).floor()];
    final pilgrimIndex = stars.length;
    stars.add(PilgrimStar(
      x: pilgrimBase.x + 0.2,
      y: pilgrimBase.y + 0.2,
      z: pilgrimBase.z + 0.8,
      size: 2,
      color: const Color(0xFFFFFBEA),
      baseAlpha: 1.0,
      kind: StarKind.pilgrim,
    ));

    // ------------------- 4. Cross Constellation --------------------------
    // Placed roughly mid-path — 5 gold stars forming a cross.
    final crossCenter = stars[pathStartIndex + (pathStars * 0.55).floor()];
    final crossOffsets = <_V3>[
      _V3(0, 0, 0), // center
      _V3(0, 0, 2.2), // top
      _V3(0, 0, -2.0), // bottom
      _V3(-2.0, 2.0, 0.2), // left arm (offset in world-aligned isometric)
      _V3(2.0, -2.0, 0.2), // right arm
    ];
    final crossStartIndex = stars.length;
    for (int i = 0; i < crossOffsets.length; i++) {
      final o = crossOffsets[i];
      stars.add(PilgrimStar(
        x: crossCenter.x + o.x + 6.0,
        y: crossCenter.y + o.y - 2.0,
        z: crossCenter.z + o.z + 2.0,
        size: i == 0 ? 2 : 1,
        color: const Color(0xFFF6D67A),
        baseAlpha: 0.95,
        kind: StarKind.cross,
      ));
    }
    // Link cross: center ↔ top, center ↔ bottom, left ↔ right (through center).
    links.add(StarLink(crossStartIndex, crossStartIndex + 1, intensity: 0.9));
    links.add(StarLink(crossStartIndex, crossStartIndex + 2, intensity: 0.9));
    links.add(StarLink(crossStartIndex + 3, crossStartIndex, intensity: 0.9));
    links.add(StarLink(crossStartIndex, crossStartIndex + 4, intensity: 0.9));

    // ------------------- 5. King's Highway (long gold chain) -------------
    // A separate gold arc beside the path, higher in sky, 9 bright stars.
    final hwyPts = <_V3>[
      _V3(-10, -2, 22),
      _V3(-7, -3, 22.5),
      _V3(-4, -3.5, 23),
      _V3(-1, -4, 23.4),
      _V3(2, -4.2, 23.7),
      _V3(5, -4.3, 24),
      _V3(8, -4.1, 24.2),
      _V3(10.5, -3.8, 24.4),
      _V3(13, -3.2, 24.6),
    ];
    final hwyStart = stars.length;
    for (int i = 0; i < hwyPts.length; i++) {
      final p = hwyPts[i];
      stars.add(PilgrimStar(
        x: p.x,
        y: p.y,
        z: p.z,
        size: i % 3 == 0 ? 2 : 1,
        color: const Color(0xFFEBC76A),
        baseAlpha: 0.9,
        kind: StarKind.kingsHighway,
      ));
    }
    for (int i = 0; i < hwyPts.length - 1; i++) {
      links.add(StarLink(hwyStart + i, hwyStart + i + 1, intensity: 0.75));
    }

    // ------------------- 6. Doubting Castle (dark clump) -----------------
    final dcRand = Random(77);
    final dcCenter = _V3(-8, -10, 10);
    for (int i = 0; i < 14; i++) {
      final dx = (dcRand.nextDouble() - 0.5) * 4.0;
      final dy = (dcRand.nextDouble() - 0.5) * 4.0;
      final dz = (dcRand.nextDouble() - 0.5) * 3.0;
      stars.add(PilgrimStar(
        x: dcCenter.x + dx,
        y: dcCenter.y + dy,
        z: dcCenter.z + dz,
        size: 1,
        color: const Color(0xFF3A2C55),
        baseAlpha: 0.45 + dcRand.nextDouble() * 0.25,
        kind: StarKind.doubtingCastle,
      ));
    }

    // ------------------- 7. Celestial City crown (top-center) -------------
    // 12-star crown above the path's endpoint.
    final ccCenter = _V3(13, -14, 28);
    final celestialStartIndex = stars.length;
    const crownCount = 12;
    for (int i = 0; i < crownCount; i++) {
      final angle = (i / crownCount) * 2 * pi - pi / 2;
      final rad = 3.8;
      final sx = ccCenter.x + cos(angle) * rad;
      final sy = ccCenter.y + sin(angle) * rad * 0.45; // flatter ellipse in y
      final sz = ccCenter.z + sin(angle) * 1.5 + 1.8;
      stars.add(PilgrimStar(
        x: sx,
        y: sy,
        z: sz,
        size: 2,
        color: const Color(0xFFFFE073),
        baseAlpha: 1.0,
        kind: StarKind.celestialCity,
      ));
    }
    // Center keystone star (brightest; pulsing hub).
    final celestialCenterIndex = stars.length;
    stars.add(PilgrimStar(
      x: ccCenter.x,
      y: ccCenter.y,
      z: ccCenter.z + 1.0,
      size: 2,
      color: const Color(0xFFFFF2A8),
      baseAlpha: 1.0,
      kind: StarKind.celestialCity,
    ));
    // Link crown stars in a ring + spokes to center.
    for (int i = 0; i < crownCount; i++) {
      final a = celestialStartIndex + i;
      final b = celestialStartIndex + (i + 1) % crownCount;
      links.add(StarLink(a, b, intensity: 0.95));
      links.add(StarLink(a, celestialCenterIndex, intensity: 0.6));
    }

    // Final path star → celestial city center (arrival).
    links.add(StarLink(pathEndIndex, celestialCenterIndex, intensity: 1.0));

    // ------------------- 8. Temptation stars (off-path, unconnected) -----
    final tRand = Random(2025);
    for (int i = 0; i < 60; i++) {
      // scatter near path midsection
      final t = 0.1 + tRand.nextDouble() * 0.8;
      final bx = _lerp(-16.0, 12.0, t);
      final by = _lerp(14.0, -14.0, t);
      final bz = _lerp(2.0, 26.0, t);
      // push off-path a bit so they aren't on the line
      final off = 4.0 + tRand.nextDouble() * 5.0;
      final dir = tRand.nextBool() ? 1.0 : -1.0;
      stars.add(PilgrimStar(
        x: bx + off * dir,
        y: by + off * dir * 0.4,
        z: bz + (tRand.nextDouble() - 0.5) * 6.0,
        size: 1,
        color: const Color(0xFF4E6A88),
        baseAlpha: 0.35 + tRand.nextDouble() * 0.25,
        kind: StarKind.temptation,
      ));
    }

    // ------------------- 9. Background scatter (the distant heavens) -----
    // Fills to bring total star count close to 1,189.
    final current = stars.length;
    final bgCount = (1189 - current).clamp(0, 1200);
    final bgRand = Random(9001);
    for (int i = 0; i < bgCount; i++) {
      final x = (bgRand.nextDouble() - 0.5) * 62.0;
      final y = (bgRand.nextDouble() - 0.5) * 62.0;
      final z = bgRand.nextDouble() * 34.0;
      // Nebula-ish tinting: a minority get a faint violet or warm hue.
      final tint = bgRand.nextDouble();
      Color c;
      if (tint < 0.08) {
        c = const Color(0xFF6C4F8A); // rare warm violet nebula fleck
      } else if (tint < 0.18) {
        c = const Color(0xFF2F4E78); // deep blue
      } else {
        c = Color.lerp(
          const Color(0xFFB8C7E0),
          const Color(0xFF7F8FB5),
          bgRand.nextDouble(),
        )!;
      }
      stars.add(PilgrimStar(
        x: x,
        y: y,
        z: z,
        size: 1,
        color: c,
        baseAlpha: 0.18 + bgRand.nextDouble() * 0.35,
        kind: tint < 0.08 ? StarKind.nebula : StarKind.backgroundBlue,
      ));
    }

    return PilgrimSceneData(
      stars: stars,
      links: links,
      pathCount: pathStars,
      pilgrimIndex: pilgrimIndex,
      celestialCityCenterIndex: celestialCenterIndex,
    );
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class PilgrimEConstellationPainter extends CustomPainter {
  final double glowAnimation; // 0..1 looped
  final double introAnimation; // 0..1, 1 = fully revealed
  final double rotationAngle;

  PilgrimEConstellationPainter({
    required this.glowAnimation,
    required this.introAnimation,
    this.rotationAngle = 0.0,
  });

  // Projection constants — isometric with subtle perspective hint.
  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;
  static const double _baseBlockSize = 6.5; // voxel edge in pixels

  // Perspective: deeper (smaller rotatedY component) → scaled smaller.
  static const double _perspectiveStrength = 0.018;

  @override
  void paint(Canvas canvas, Size size) {
    _drawNightSky(canvas, size);

    final scene = PilgrimSceneData.instance;
    final origin = Offset(size.width / 2, size.height * 0.62);

    // Camera tilt: slightly looking up — we bias origin lower so Celestial
    // City sits high in the frame.
    // Sort stars back-to-front by depth key.
    final indexed = List<int>.generate(scene.stars.length, (i) => i);
    indexed.sort((a, b) {
      return _depthKey(scene.stars[a]).compareTo(_depthKey(scene.stars[b]));
    });

    // ------------------ Distant nebula puffs (soft radial glow) ----------
    _drawNebulaPuffs(canvas, size, origin);

    // ------------------ Draw stars (back-to-front) -----------------------
    for (final idx in indexed) {
      final s = scene.stars[idx];
      final visibility = _visibilityForStar(s, scene);
      if (visibility <= 0) continue;
      _drawStarVoxel(canvas, origin, s, visibility, idx == scene.pilgrimIndex,
          idx == scene.celestialCityCenterIndex, scene);
    }

    // ------------------ Draw connection lines over stars -----------------
    _drawLinks(canvas, origin, scene);

    // ------------------ Celestial City aura ------------------------------
    _drawCelestialAura(canvas, origin, scene);

    // ------------------ Foreground particle sparkle ----------------------
    _drawSparkles(canvas, size, origin, scene);
  }

  // ---------------------------------------------------------------------------
  // Projection + depth
  // ---------------------------------------------------------------------------

  Offset _project(double x, double y, double z, Offset origin) {
    final cosA = cos(rotationAngle);
    final sinA = sin(rotationAngle);
    final rx = x * cosA - y * sinA;
    final ry = x * sinA + y * cosA;

    // Perspective hint: things further (larger ry) shrink slightly; add subtle
    // y-axis compression with depth.
    final depth = rx + ry; // combined iso depth
    final scale = 1.0 / (1.0 + depth * _perspectiveStrength);

    final px = origin.dx + (rx - ry) * _cos30 * _baseBlockSize * scale;
    final py = origin.dy +
        (rx + ry) * _sin30 * _baseBlockSize * scale -
        z * _baseBlockSize * scale;
    return Offset(px, py);
  }

  double _projectedScale(double x, double y, Offset origin) {
    final cosA = cos(rotationAngle);
    final sinA = sin(rotationAngle);
    final rx = x * cosA - y * sinA;
    final ry = x * sinA + y * cosA;
    final depth = rx + ry;
    return 1.0 / (1.0 + depth * _perspectiveStrength);
  }

  double _depthKey(PilgrimStar s) {
    final cosA = cos(rotationAngle);
    final sinA = sin(rotationAngle);
    final rx = s.x * cosA - s.y * sinA;
    final ry = s.x * sinA + s.y * cosA;
    return rx + ry - s.z * 0.5;
  }

  // ---------------------------------------------------------------------------
  // Intro visibility — stars light up sequentially along path
  // ---------------------------------------------------------------------------

  double _visibilityForStar(PilgrimStar s, PilgrimSceneData scene) {
    // Phase 1 (0.0 - 0.4): background fades in uniformly
    // Phase 2 (0.25 - 0.85): path stars light up from City of Destruction
    //                        to Celestial City.
    // Phase 3 (0.6 - 1.0): landmark clusters (cross, highway, castle, crown)
    //                      fade in.
    if (introAnimation >= 1.0) return 1.0;

    switch (s.kind) {
      case StarKind.backgroundBlue:
      case StarKind.nebula:
        final t = (introAnimation / 0.4).clamp(0.0, 1.0);
        return t;
      case StarKind.temptation:
        final t = ((introAnimation - 0.15) / 0.5).clamp(0.0, 1.0);
        return t;
      case StarKind.path:
      case StarKind.pilgrim:
        final order = s.pathOrder >= 0 ? s.pathOrder : scene.pathCount ~/ 2;
        final frac = order / scene.pathCount;
        // Map path reveal to 0.25 → 0.85 of introAnimation.
        final center = 0.25 + frac * 0.60;
        final localT = ((introAnimation - center) / 0.08).clamp(0.0, 1.0);
        return localT;
      case StarKind.cityOfDestruction:
        final t = ((introAnimation - 0.2) / 0.15).clamp(0.0, 1.0);
        return t;
      case StarKind.cross:
        final t = ((introAnimation - 0.55) / 0.15).clamp(0.0, 1.0);
        return t;
      case StarKind.kingsHighway:
        final t = ((introAnimation - 0.65) / 0.15).clamp(0.0, 1.0);
        return t;
      case StarKind.doubtingCastle:
        final t = ((introAnimation - 0.5) / 0.2).clamp(0.0, 1.0);
        return t;
      case StarKind.celestialCity:
        final t = ((introAnimation - 0.8) / 0.2).clamp(0.0, 1.0);
        return t;
    }
  }

  // ---------------------------------------------------------------------------
  // Background
  // ---------------------------------------------------------------------------

  void _drawNightSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF000005),
          Color(0xFF05061A),
          Color(0xFF0A0A1A),
          Color(0xFF140A22),
          Color(0xFF05030E),
        ],
        stops: [0.0, 0.3, 0.55, 0.82, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, gradient);

    // Subtle horizontal haze near the bottom ("world horizon" at City of Destr.)
    final hazePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.55, 0.75),
        radius: 0.8,
        colors: [
          const Color(0xFF4A1414).withValues(alpha: 0.22),
          const Color(0xFF4A1414).withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, hazePaint);

    // Golden halo near Celestial City area (top-right).
    final auraPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.55, -0.55),
        radius: 0.65,
        colors: [
          const Color(0xFFD4A843).withValues(alpha: 0.12),
          const Color(0xFFD4A843).withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, auraPaint);
  }

  void _drawNebulaPuffs(Canvas canvas, Size size, Offset origin) {
    final puffs = <_Puff>[
      _V3(-18, -8, 20).puff(const Color(0xFF5B3C7A), 160),
      _V3(6, 10, 6).puff(const Color(0xFF2C4A74), 180),
      _V3(18, 4, 16).puff(const Color(0xFF3E2C52), 140),
    ];
    for (final p in puffs) {
      final center = _project(p.v.x, p.v.y, p.v.z, origin);
      final a = (introAnimation * 0.08).clamp(0.0, 0.08);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [p.color.withValues(alpha: a), p.color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: center, radius: p.radius));
      canvas.drawCircle(center, p.radius, paint);
    }
  }

  // ---------------------------------------------------------------------------
  // Star voxel rendering
  // ---------------------------------------------------------------------------

  void _drawStarVoxel(
    Canvas canvas,
    Offset origin,
    PilgrimStar s,
    double visibility,
    bool isPilgrim,
    bool isCelestialCenter,
    PilgrimSceneData scene,
  ) {
    // Compute pulse factors
    double pulse = 0.0;
    switch (s.kind) {
      case StarKind.pilgrim:
        pulse = 0.35 + 0.25 * sin(glowAnimation * 2 * pi * 1.5);
        break;
      case StarKind.celestialCity:
        pulse = 0.20 + 0.15 * sin(glowAnimation * 2 * pi);
        break;
      case StarKind.cross:
        pulse = 0.10 + 0.08 * sin(glowAnimation * 2 * pi + 1.0);
        break;
      case StarKind.path:
        pulse = 0.04 * sin(glowAnimation * 2 * pi + s.pathOrder * 0.25);
        break;
      default:
        pulse = 0.0;
    }

    final effectiveAlpha = (s.baseAlpha * visibility).clamp(0.0, 1.0);
    if (effectiveAlpha <= 0) return;

    // Sub-voxel z offset — pilgrim bobs gently.
    double zOff = 0.0;
    if (isPilgrim) {
      zOff = sin(glowAnimation * 2 * pi * 1.2) * 0.35;
    }

    // Voxel edge size in scene units (1 or 2).
    final edge = s.size.toDouble();

    // Anchor corner (so the voxel is centered on (s.x, s.y, s.z)).
    final ax = s.x - edge / 2;
    final ay = s.y - edge / 2;
    final az = s.z - edge / 2 + zOff;

    // Draw voxel cube with additive-style glow halo.
    _drawCube(
      canvas,
      origin,
      ax,
      ay,
      az,
      edge,
      s.color,
      effectiveAlpha,
    );

    // Halo for bright stars.
    if (s.kind == StarKind.path ||
        s.kind == StarKind.cross ||
        s.kind == StarKind.kingsHighway ||
        s.kind == StarKind.celestialCity ||
        s.kind == StarKind.pilgrim) {
      final center = _project(s.x, s.y, s.z + zOff, origin);
      final scale = _projectedScale(s.x, s.y, origin);
      final haloRadius = (6.0 + edge * 4.0) * scale * (1.0 + pulse);
      final haloAlpha = (0.28 + pulse) * effectiveAlpha;
      final haloPaint = Paint()
        ..color = s.color.withValues(alpha: haloAlpha.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, haloRadius, haloPaint);

      if (isPilgrim || isCelestialCenter) {
        // Extra inner bright core
        final corePaint = Paint()
          ..color = Colors.white.withValues(
              alpha: (0.55 + pulse * 0.5).clamp(0.0, 1.0) * effectiveAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(center, (2.5 + edge) * scale, corePaint);
      }
    }
  }

  void _drawCube(
    Canvas canvas,
    Offset origin,
    double x,
    double y,
    double z,
    double edge,
    Color topColor,
    double alpha,
  ) {
    // Corner projections
    final p1 = _project(x + edge, y, z, origin);
    final p2 = _project(x + edge, y + edge, z, origin);
    final p3 = _project(x, y + edge, z, origin);
    final p4 = _project(x, y, z + edge, origin);
    final p5 = _project(x + edge, y, z + edge, origin);
    final p6 = _project(x + edge, y + edge, z + edge, origin);
    final p7 = _project(x, y + edge, z + edge, origin);

    final top = topColor.withValues(alpha: alpha);
    final left = Color.lerp(topColor, Colors.black, 0.32)!.withValues(alpha: alpha);
    final right = Color.lerp(topColor, Colors.black, 0.55)!.withValues(alpha: alpha);

    // Top
    final topPath = Path()
      ..moveTo(p4.dx, p4.dy)
      ..lineTo(p5.dx, p5.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p7.dx, p7.dy)
      ..close();
    canvas.drawPath(topPath, Paint()..color = top);

    // Left
    final leftPath = Path()
      ..moveTo(p3.dx, p3.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p7.dx, p7.dy)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = left);

    // Right
    final rightPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p5.dx, p5.dy)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = right);

    // Crisp edge highlight on top
    canvas.drawPath(
      topPath,
      Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.4,
    );
  }

  // ---------------------------------------------------------------------------
  // Connection lines (light-of-the-way)
  // ---------------------------------------------------------------------------

  void _drawLinks(Canvas canvas, Offset origin, PilgrimSceneData scene) {
    for (final link in scene.links) {
      final a = scene.stars[link.fromIndex];
      final b = scene.stars[link.toIndex];
      final va = _visibilityForStar(a, scene);
      final vb = _visibilityForStar(b, scene);
      final lineVis = min(va, vb);
      if (lineVis <= 0.02) continue;

      final pa = _project(a.x, a.y, a.z, origin);
      final pb = _project(b.x, b.y, b.z, origin);

      final baseAlpha = 0.42 * link.intensity * lineVis;

      // Outer halo stroke
      final halo = Paint()
        ..color = const Color(0xFFFFD67A).withValues(alpha: baseAlpha * 0.55)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawLine(pa, pb, halo);

      // Inner crisp line
      final line = Paint()
        ..color = const Color(0xFFFFF3C9).withValues(alpha: baseAlpha * 1.2)
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(pa, pb, line);
    }
  }

  // ---------------------------------------------------------------------------
  // Celestial City aura
  // ---------------------------------------------------------------------------

  void _drawCelestialAura(
      Canvas canvas, Offset origin, PilgrimSceneData scene) {
    final center = scene.stars[scene.celestialCityCenterIndex];
    final cVis = _visibilityForStar(center, scene);
    if (cVis <= 0) return;

    final pulse = 0.5 + 0.5 * sin(glowAnimation * 2 * pi);
    final c = _project(center.x, center.y, center.z, origin);
    final scale = _projectedScale(center.x, center.y, origin);

    final radius = (60.0 + pulse * 22.0) * scale;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFE073)
              .withValues(alpha: 0.28 * cVis * (0.7 + pulse * 0.3)),
          const Color(0xFFD4A843).withValues(alpha: 0.10 * cVis),
          const Color(0xFFD4A843).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: radius));
    canvas.drawCircle(c, radius, paint);
  }

  // ---------------------------------------------------------------------------
  // Sparkle particles (foreground twinkles)
  // ---------------------------------------------------------------------------

  void _drawSparkles(
      Canvas canvas, Size size, Offset origin, PilgrimSceneData scene) {
    if (introAnimation < 0.6) return;
    final fadeIn = ((introAnimation - 0.6) / 0.4).clamp(0.0, 1.0);

    // Sparkles near Celestial City
    final cc = scene.stars[scene.celestialCityCenterIndex];
    final center = _project(cc.x, cc.y, cc.z, origin);
    final rand = Random(314);
    for (int i = 0; i < 22; i++) {
      final angle = rand.nextDouble() * 2 * pi;
      final dist = 18.0 + rand.nextDouble() * 110.0;
      final phase = (glowAnimation + i * 0.047) % 1.0;
      final alpha = sin(phase * pi) * 0.9 * fadeIn;
      if (alpha <= 0) continue;
      final px = center.dx + cos(angle) * dist * (0.5 + phase * 0.8);
      final py = center.dy + sin(angle) * dist * 0.6 * (0.5 + phase * 0.8) -
          phase * 22.0;
      final r = 1.0 + rand.nextDouble() * 1.8;
      final paint = Paint()
        ..color = const Color(0xFFFFF2A8).withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(px, py), r, paint);
    }

    // Drift sparkles along path (occasional light motes)
    final pathRand = Random(909);
    final sample = 18;
    for (int i = 0; i < sample; i++) {
      final star = scene.stars[(i * (scene.pathCount ~/ sample))
          .clamp(0, scene.pathCount - 1)];
      final sp = _project(star.x, star.y, star.z, origin);
      final phase = (glowAnimation + i * 0.07) % 1.0;
      final alpha = sin(phase * pi) * 0.6 * fadeIn;
      if (alpha <= 0.02) continue;
      final r = 0.8 + pathRand.nextDouble() * 1.2;
      final paint = Paint()
        ..color = const Color(0xFFFFE7A8).withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(sp, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PilgrimEConstellationPainter old) {
    return old.glowAnimation != glowAnimation ||
        old.introAnimation != introAnimation ||
        old.rotationAngle != rotationAngle;
  }
}

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

class _V3 {
  final double x;
  final double y;
  final double z;
  const _V3(this.x, this.y, this.z);

  _Puff puff(Color c, double r) => _Puff(this, c, r);
}

class _Puff {
  final _V3 v;
  final Color color;
  final double radius;
  const _Puff(this.v, this.color, this.radius);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
