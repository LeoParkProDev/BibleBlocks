import 'dart:math';
import 'package:flutter/material.dart';

/// Pilgrim B — Isometric Labyrinth painter for BibleBlocks.
///
/// Theme: John Bunyan's "The Pilgrim's Progress".
/// A top-down isometric maze where a single continuous path (정로) of
/// terracotta paving stones snakes from the City of Destruction
/// (lower-left, dark) through narrow gates, past landmarks, to the
/// Celestial City (upper-right, gold fortress).
///
/// - 1,189 Bible chapters are mapped proportionally onto the path tiles
///   as fill progress indicators.
/// - "Wrong turns" are wireframe dead-ends that tempt but mislead.
/// - Design & shading are inspired by [NoahsArkPainter] and
///   [IsometricBiblePainter].
class PilgrimBMazePainter extends CustomPainter {
  /// 0..1189 — how many chapters the user has "walked".
  final int readChapters;

  /// 0..1 — breathing glow for path pulse + lanterns.
  final double glowAnimation;

  /// 0..1 — intro sweep from City of Destruction to Celestial City.
  final double introAnimation;

  /// Total chapters — kept parametric so the demo screen can drive it.
  final int totalChapters;

  PilgrimBMazePainter({
    required this.readChapters,
    this.glowAnimation = 0.0,
    this.introAnimation = 1.0,
    this.totalChapters = 1189,
  });

  // ---------------------------------------------------------------------------
  // Grid + isometric projection
  // ---------------------------------------------------------------------------

  /// Maze grid dimensions (tiles).
  static const int gridSize = 24;

  /// Voxel size in logical pixels.
  static const double blockSize = 11.0;

  /// Classic 2:1 isometric cosines.
  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;

  Offset _project(double x, double y, double z, Offset origin) {
    return Offset(
      origin.dx + (x - y) * _cos30 * blockSize,
      origin.dy + (x + y) * _sin30 * blockSize - z * blockSize,
    );
  }

  // ---------------------------------------------------------------------------
  // Palette — "Terracotta Sunset" variant, adapted for the dark maze scene.
  // ---------------------------------------------------------------------------

  static const Color _bg = Color(0xFF0A0A1A);
  static const Color _bgAccent = Color(0xFF151530);

  // Path — terracotta paving stones (정로).
  static const Color _pathTop = Color(0xFFC47B5A); // primary
  static const Color _pathTopLit = Color(0xFFE09B7A);

  // Wall stones (미로 벽) — cool blue-grey stonework.
  static const Color _wallTop = Color(0xFF5C6E79);
  static const Color _wallSide = Color(0xFF3A4851);

  // City of Destruction — charred dark cubes (멸망의 도시).
  static const Color _destructionTop = Color(0xFF2A1A20);
  static const Color _destructionSide = Color(0xFF180C10);
  static const Color _destructionEmber = Color(0xFF8A3020);

  // Celestial City — golden ramparts (천성).
  static const Color _celestialGold = Color(0xFFD4A843);
  static const Color _celestialGoldDeep = Color(0xFF9A7A22);
  static const Color _celestialIvory = Color(0xFFF5E6C0);

  // Landmarks.
  static const Color _wicketGate = Color(0xFFE09B7A); // 좁은 문
  static const Color _interpreterStone = Color(0xFF8A7A68); // 해석자의 집
  static const Color _covenantStone = Color(0xFFBFB29A); // 언약의 비석
  static const Color _swampWater = Color(0xFF2A4A5E); // 절망의 늪
  static const Color _swampDeep = Color(0xFF183248);
  static const Color _vanityBooth1 = Color(0xFF9A3A5A);
  static const Color _vanityBooth2 = Color(0xFF3A5A9A);
  static const Color _vanityBooth3 = Color(0xFF5A9A3A);
  static const Color _lanternGlow = Color(0xFFFFD870);

  static const Color _wireframe = Color(0x33C47B5A);

  // ---------------------------------------------------------------------------
  // Maze layout — hand-authored, deterministic.
  //
  // Coordinate system: (x, y) in [0, gridSize).
  // _pathTiles is an ORDERED list — element 0 is the first step from the
  // City of Destruction, final element is the last step before the Celestial
  // City gate. Chapters are mapped proportionally onto this ordering.
  //
  // The path wanders 좌하단(1,22) → 우상단(22,1) with S-turns, a narrow gate,
  // a detour around Slough of Despond, past Vanity Fair, and up to the
  // Celestial City gate.
  // ---------------------------------------------------------------------------

  /// Single continuous ordered path from City of Destruction to Celestial City.
  ///
  /// Hand-authored so that adjacent entries differ by exactly 1 in one axis
  /// (Manhattan step) — this guarantees a continuous labyrinth path.
  static final List<_Tile> _pathTiles = _buildPath();

  /// Dead-end "wrong turns" — drawn as faint wireframe tiles.
  static final Set<_Tile> _deadEndTiles = _buildDeadEnds();

  /// Set for O(1) path lookup.
  static final Set<_Tile> _pathSet = _pathTiles.toSet();

  /// Wall voxels — everything that isn't path, dead-end, landmark,
  /// or one of the two cities.
  static final List<_WallCell> _wallCells = _buildWalls();

  /// Landmarks: (x, y) + kind.
  static final List<_Landmark> _landmarks = _buildLandmarks();

  // Anchored regions.
  static const _Rect _destructionRect = _Rect(0, 20, 4, 4); // bottom-left
  static const _Rect _celestialRect = _Rect(19, 0, 5, 5); // top-right

  static List<_Tile> _buildPath() {
    // Hand-traced path. Keep each step as an adjacent (dx,dy) move.
    // Starts at (1, 22) — gate of City of Destruction.
    // Ends at (21, 1) — gate of Celestial City.
    final List<_Tile> p = [];
    int x = 1, y = 22;
    void move(String dirs) {
      for (final c in dirs.split('')) {
        switch (c) {
          case 'U':
            y -= 1;
            break;
          case 'D':
            y += 1;
            break;
          case 'L':
            x -= 1;
            break;
          case 'R':
            x += 1;
            break;
        }
        p.add(_Tile(x, y));
      }
    }

    p.add(_Tile(x, y));
    // Leave City of Destruction — go right, then up toward the Wicket Gate.
    move('RRR'); // (4,22)
    move('UUU'); // (4,19) — Wicket Gate landmark
    // Detour around Slough of Despond (swamp around 6..8, 18..19).
    move('RR'); // (6,19)
    move('UU'); // (6,17)
    move('RRR'); // (9,17)
    move('DD'); // (9,19) — a tempting S-turn
    move('RR'); // (11,19)
    move('UUUU'); // (11,15) — Interpreter's house landmark near (12,15)
    move('RR'); // (13,15)
    move('UUU'); // (13,12)
    move('LLLL'); // (9,12)
    move('UUU'); // (9,9)
    move('RRRR'); // (13,9) — Covenant stone landmark near (12,9)
    move('UU'); // (13,7)
    move('RRRR'); // (17,7) — Vanity Fair approach
    move('UU'); // (17,5)
    move('LL'); // (15,5)
    move('UUU'); // (15,2)
    move('RRRRRR'); // (21,2)
    move('U'); // (21,1) — Celestial City gate
    return p;
  }

  static Set<_Tile> _buildDeadEnds() {
    // A handful of short branches (와이어프레임) that look like legal moves
    // but lead to dead ends.
    final out = <_Tile>{};
    const branches = [
      // From (7,17), a detour east into the swamp.
      [_Tile(7, 17), _Tile(7, 18)],
      // From (9,12), a tempting north branch that truncates.
      [_Tile(8, 12), _Tile(7, 12), _Tile(7, 11)],
      // Near Vanity Fair, a detour south.
      [_Tile(17, 8), _Tile(18, 8), _Tile(18, 9)],
      // Near the Covenant stone, false path east.
      [_Tile(14, 9), _Tile(15, 9), _Tile(15, 8)],
      // Between the gate and interpreter's house.
      [_Tile(10, 19), _Tile(10, 20)],
      // Short feint west of the Wicket gate.
      [_Tile(3, 17), _Tile(3, 16)],
      // Near top — a teasing branch off the final corridor.
      [_Tile(19, 5), _Tile(19, 4)],
    ];
    for (final b in branches) {
      for (final t in b) {
        out.add(t);
      }
    }
    return out;
  }

  static List<_WallCell> _buildWalls() {
    final out = <_WallCell>[];
    final rng = Random(42);
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final t = _Tile(x, y);
        if (_pathSet.contains(t)) continue;
        if (_deadEndTiles.contains(t)) continue;
        if (_destructionRect.contains(x, y)) continue;
        if (_celestialRect.contains(x, y)) continue;
        if (_isSwamp(x, y)) continue;
        if (_isVanityBooth(x, y)) continue;
        if (_isLandmarkTile(x, y)) continue;
        // Only render walls that flank the path — gives the "corridor" look.
        if (!_neighborsPathOrCity(x, y)) continue;
        // 2 or 3 block tall walls — varied for silhouette.
        final h = 2 + ((x * 7 + y * 13 + rng.nextInt(3)) % 2);
        out.add(_WallCell(x, y, h));
      }
    }
    return out;
  }

  static bool _isSwamp(int x, int y) {
    // Slough of Despond — small marsh patch east of the Wicket Gate.
    return x >= 6 && x <= 8 && y >= 20 && y <= 21;
  }

  static bool _isVanityBooth(int x, int y) {
    // Vanity Fair — 3 colored booths clustered near (18..20, 6..7).
    return (x == 18 && y == 6) ||
        (x == 19 && y == 6) ||
        (x == 20 && y == 6) ||
        (x == 18 && y == 7) ||
        (x == 20 && y == 7);
  }

  static bool _isLandmarkTile(int x, int y) {
    for (final lm in _landmarks) {
      if (lm.x == x && lm.y == y) return true;
    }
    return false;
  }

  static bool _neighborsPathOrCity(int x, int y) {
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= gridSize || ny >= gridSize) continue;
        final t = _Tile(nx, ny);
        if (_pathSet.contains(t)) return true;
        if (_deadEndTiles.contains(t)) return true;
        if (_destructionRect.contains(nx, ny)) return true;
        if (_celestialRect.contains(nx, ny)) return true;
      }
    }
    return false;
  }

  static List<_Landmark> _buildLandmarks() {
    return const [
      // Wicket Gate — narrow door in the wall at (4,19)ish.
      _Landmark(4, 19, _LandmarkKind.wicketGate),
      // Interpreter's house — stone building next to path at (12,15).
      _Landmark(12, 15, _LandmarkKind.interpreterHouse),
      // Covenant stone — pillar at (12,9).
      _Landmark(12, 9, _LandmarkKind.covenantStone),
      // Lanterns along the path.
      _Landmark(4, 21, _LandmarkKind.lantern),
      _Landmark(9, 17, _LandmarkKind.lantern),
      _Landmark(13, 12, _LandmarkKind.lantern),
      _Landmark(17, 5, _LandmarkKind.lantern),
      _Landmark(21, 1, _LandmarkKind.lantern),
    ];
  }

  // ---------------------------------------------------------------------------
  // Painting
  // ---------------------------------------------------------------------------

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackdrop(canvas, size);

    // Centered on the grid; slight offset so the maze reads centered.
    final origin = Offset(
      size.width / 2 - (gridSize - 1) * _cos30 * blockSize / 2 +
          (gridSize - 1) * _cos30 * blockSize / 2 -
          (gridSize / 2) * (_cos30 * blockSize),
      size.height * 0.22,
    );

    // Sort all drawable items back-to-front.
    final items = <_Drawable>[];

    // City of Destruction (cubes).
    for (int y = _destructionRect.y; y < _destructionRect.y + _destructionRect.h; y++) {
      for (int x = _destructionRect.x; x < _destructionRect.x + _destructionRect.w; x++) {
        // Uneven ruin silhouette.
        final h = 1 + ((x * 3 + y * 5) % 3);
        for (int z = 0; z < h; z++) {
          items.add(_Drawable(x.toDouble(), y.toDouble(), z.toDouble(), _DrawKind.destruction));
        }
      }
    }

    // Celestial City — high golden rampart with central tower.
    for (int y = _celestialRect.y; y < _celestialRect.y + _celestialRect.h; y++) {
      for (int x = _celestialRect.x; x < _celestialRect.x + _celestialRect.w; x++) {
        final isEdge = x == _celestialRect.x ||
            x == _celestialRect.x + _celestialRect.w - 1 ||
            y == _celestialRect.y ||
            y == _celestialRect.y + _celestialRect.h - 1;
        final isCenter = x == _celestialRect.x + 2 && y == _celestialRect.y + 2;
        final int h;
        if (isCenter) {
          h = 7;
        } else if (isEdge) {
          h = 4 + ((x + y) % 2);
        } else {
          h = 2;
        }
        for (int z = 0; z < h; z++) {
          items.add(_Drawable(x.toDouble(), y.toDouble(), z.toDouble(),
              isCenter ? _DrawKind.celestialSpire : _DrawKind.celestialWall));
        }
      }
    }

    // Slough of Despond — water tiles, z=0 thin.
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (_isSwamp(x, y)) {
          items.add(_Drawable(x.toDouble(), y.toDouble(), 0, _DrawKind.swamp));
        }
      }
    }

    // Vanity Fair booths.
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (_isVanityBooth(x, y)) {
          items.add(_Drawable(x.toDouble(), y.toDouble(), 0, _DrawKind.vanityBooth));
          items.add(_Drawable(x.toDouble(), y.toDouble(), 1, _DrawKind.vanityBoothTop));
        }
      }
    }

    // Walls.
    for (final w in _wallCells) {
      for (int z = 0; z < w.h; z++) {
        items.add(_Drawable(w.x.toDouble(), w.y.toDouble(), z.toDouble(), _DrawKind.wall));
      }
    }

    // Landmarks (structures).
    for (final lm in _landmarks) {
      switch (lm.kind) {
        case _LandmarkKind.wicketGate:
          // Two pillars + lintel.
          items.add(_Drawable(lm.x.toDouble() - 0.15, lm.y.toDouble() - 0.2, 0, _DrawKind.gatePillar));
          items.add(_Drawable(lm.x.toDouble() - 0.15, lm.y.toDouble() - 0.2, 1, _DrawKind.gatePillar));
          items.add(_Drawable(lm.x.toDouble() - 0.15, lm.y.toDouble() - 0.2, 2, _DrawKind.gateLintel));
          break;
        case _LandmarkKind.interpreterHouse:
          // 2x2 stone, 2 tall.
          for (int z = 0; z < 2; z++) {
            items.add(_Drawable(lm.x.toDouble(), lm.y.toDouble(), z.toDouble(), _DrawKind.interpreter));
          }
          items.add(_Drawable(lm.x.toDouble(), lm.y.toDouble(), 2, _DrawKind.interpreterRoof));
          break;
        case _LandmarkKind.covenantStone:
          items.add(_Drawable(lm.x.toDouble() + 0.2, lm.y.toDouble() + 0.2, 0, _DrawKind.covenantStone));
          items.add(_Drawable(lm.x.toDouble() + 0.2, lm.y.toDouble() + 0.2, 1, _DrawKind.covenantStone));
          break;
        case _LandmarkKind.lantern:
          items.add(_Drawable(lm.x.toDouble() + 0.35, lm.y.toDouble() + 0.35, 0, _DrawKind.lanternPost));
          items.add(_Drawable(lm.x.toDouble() + 0.35, lm.y.toDouble() + 0.35, 1, _DrawKind.lanternPost));
          items.add(_Drawable(lm.x.toDouble() + 0.2, lm.y.toDouble() + 0.2, 2, _DrawKind.lanternHead));
          break;
      }
    }

    // Path tiles — keyed by ordering index so we can map chapters.
    for (int i = 0; i < _pathTiles.length; i++) {
      final t = _pathTiles[i];
      items.add(_Drawable(
        t.x.toDouble(),
        t.y.toDouble(),
        0,
        _DrawKind.path,
        pathIndex: i,
      ));
    }

    // Dead-end wireframes.
    for (final t in _deadEndTiles) {
      items.add(_Drawable(t.x.toDouble(), t.y.toDouble(), 0, _DrawKind.deadEnd));
    }

    // Depth sort — back-to-front (larger x+y-z drawn last).
    items.sort((a, b) => _depth(a).compareTo(_depth(b)));

    // Celestial aura behind the fortress.
    _paintCelestialAura(canvas, size, origin);

    // Intro sweep threshold — path reveals sequentially from start to gate.
    final pathIntroCount =
        (_pathTiles.length * introAnimation.clamp(0.0, 1.0)).round();

    for (final d in items) {
      _drawItem(canvas, origin, d, pathIntroCount);
    }

    // Celestial glow particles when intro completes.
    if (introAnimation >= 1.0) {
      _paintCelestialSparks(canvas, size, origin);
    }
  }

  double _depth(_Drawable d) => (d.x + 0.5) + (d.y + 0.5) - (d.z + 0.5);

  void _paintBackdrop(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.35, -0.4),
        radius: 1.1,
        colors: const [_bgAccent, _bg],
      ).createShader(rect);
    canvas.drawRect(rect, bg);
  }

  void _paintCelestialAura(Canvas canvas, Size size, Offset origin) {
    final center = _project(
      (_celestialRect.x + _celestialRect.w / 2).toDouble(),
      (_celestialRect.y + _celestialRect.h / 2).toDouble(),
      3,
      origin,
    );
    final pulse = 0.35 + 0.15 * sin(glowAnimation * 2 * pi);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          _celestialGold.withValues(alpha: 0.22 * pulse),
          _celestialGold.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.35));
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _paintCelestialSparks(Canvas canvas, Size size, Offset origin) {
    final center = _project(
      (_celestialRect.x + _celestialRect.w / 2).toDouble(),
      (_celestialRect.y + _celestialRect.h / 2).toDouble(),
      5,
      origin,
    );
    final rng = Random(7);
    final paint = Paint();
    for (int i = 0; i < 22; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = 8 + rng.nextDouble() * 60;
      final phase = (glowAnimation + i * 0.045) % 1.0;
      final alpha = (sin(phase * pi) * 0.7).clamp(0.0, 1.0);
      if (alpha <= 0) continue;
      final px = center.dx + cos(angle) * dist * (0.4 + phase);
      final py = center.dy + sin(angle) * dist * 0.35 - phase * 36;
      final r = 1.3 + rng.nextDouble() * 1.7;
      paint.color = _celestialGold.withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), r, paint);
    }
  }

  // ---------------------------------------------------------------------------
  // Per-item draw
  // ---------------------------------------------------------------------------

  void _drawItem(Canvas canvas, Offset origin, _Drawable d, int pathIntroCount) {
    switch (d.kind) {
      case _DrawKind.wall:
        _drawCube(canvas, origin, d.x, d.y, d.z, _wallTop, _wallSide);
        break;
      case _DrawKind.destruction:
        _drawCube(canvas, origin, d.x, d.y, d.z, _destructionTop, _destructionSide);
        // Occasional ember glow on top.
        if ((d.x.toInt() * 3 + d.y.toInt() * 5) % 5 == 0 && d.z >= 1) {
          final center = _project(d.x + 0.5, d.y + 0.5, d.z + 1.05, origin);
          final ember = Paint()
            ..color = _destructionEmber.withValues(
                alpha: 0.4 + 0.2 * sin(glowAnimation * 2 * pi))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          canvas.drawCircle(center, blockSize * 0.35, ember);
        }
        break;
      case _DrawKind.celestialWall:
        _drawCube(canvas, origin, d.x, d.y, d.z, _celestialGold, _celestialGoldDeep);
        break;
      case _DrawKind.celestialSpire:
        _drawCube(canvas, origin, d.x, d.y, d.z, _celestialIvory, _celestialGold);
        break;
      case _DrawKind.swamp:
        // Thin water tile, z=0..~0.2. Render as a slim top + hint of side.
        _drawCube(canvas, origin, d.x, d.y, d.z - 0.8, _swampWater, _swampDeep);
        break;
      case _DrawKind.vanityBooth:
        final palette = _vanityPalette(d.x.toInt(), d.y.toInt());
        _drawCube(canvas, origin, d.x, d.y, d.z, palette.$1, palette.$2);
        break;
      case _DrawKind.vanityBoothTop:
        final palette = _vanityPalette(d.x.toInt(), d.y.toInt());
        // Striped canopy — lighter top.
        _drawCube(
            canvas,
            origin,
            d.x + 0.08,
            d.y + 0.08,
            d.z,
            Color.lerp(palette.$1, Colors.white, 0.35)!,
            Color.lerp(palette.$2, Colors.white, 0.1)!);
        break;
      case _DrawKind.gatePillar:
        _drawNarrow(canvas, origin, d.x, d.y, d.z, 0.3, 1.3, _wicketGate,
            Color.lerp(_wicketGate, Colors.black, 0.3)!);
        // A second pillar across the gate opening.
        _drawNarrow(canvas, origin, d.x + 0.9, d.y, d.z, 0.3, 1.3, _wicketGate,
            Color.lerp(_wicketGate, Colors.black, 0.3)!);
        break;
      case _DrawKind.gateLintel:
        _drawCube(canvas, origin, d.x, d.y, d.z - 0.3, _wicketGate,
            Color.lerp(_wicketGate, Colors.black, 0.3)!);
        break;
      case _DrawKind.interpreter:
        _drawCube(canvas, origin, d.x, d.y, d.z, _interpreterStone,
            Color.lerp(_interpreterStone, Colors.black, 0.35)!);
        break;
      case _DrawKind.interpreterRoof:
        _drawCube(canvas, origin, d.x + 0.05, d.y + 0.05, d.z,
            _pathTop, Color.lerp(_pathTop, Colors.black, 0.35)!);
        break;
      case _DrawKind.covenantStone:
        _drawNarrow(canvas, origin, d.x, d.y, d.z, 0.5, 1.0, _covenantStone,
            Color.lerp(_covenantStone, Colors.black, 0.35)!);
        break;
      case _DrawKind.lanternPost:
        _drawNarrow(canvas, origin, d.x, d.y, d.z, 0.18, 1.0,
            const Color(0xFF3C2A1A),
            const Color(0xFF241808));
        break;
      case _DrawKind.lanternHead:
        final center = _project(d.x + 0.3, d.y + 0.3, d.z + 0.3, origin);
        final pulse = 0.75 + 0.25 * sin(glowAnimation * 2 * pi);
        // Lantern halo.
        final halo = Paint()
          ..color = _lanternGlow.withValues(alpha: 0.35 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(center, blockSize * 0.9, halo);
        // Lantern core.
        final core = Paint()..color = _lanternGlow.withValues(alpha: 0.95);
        canvas.drawCircle(center, blockSize * 0.28, core);
        break;
      case _DrawKind.path:
        _drawPathTile(canvas, origin, d, pathIntroCount);
        break;
      case _DrawKind.deadEnd:
        if (introAnimation >= 0.9) {
          _drawWireframeTile(canvas, origin, d.x, d.y, d.z);
        }
        break;
    }
  }

  (Color, Color) _vanityPalette(int x, int y) {
    final n = (x * 3 + y * 7) % 3;
    switch (n) {
      case 0:
        return (_vanityBooth1, Color.lerp(_vanityBooth1, Colors.black, 0.3)!);
      case 1:
        return (_vanityBooth2, Color.lerp(_vanityBooth2, Colors.black, 0.3)!);
      default:
        return (_vanityBooth3, Color.lerp(_vanityBooth3, Colors.black, 0.3)!);
    }
  }

  void _drawPathTile(Canvas canvas, Offset origin, _Drawable d, int pathIntroCount) {
    final idx = d.pathIndex ?? 0;
    if (idx >= pathIntroCount) {
      // Not yet revealed by intro — skip entirely.
      return;
    }
    // Map path index to chapter range.
    final double ratio =
        (idx + 1) * totalChapters / _pathTiles.length;
    final int requiredRead = ratio.ceil();
    final bool walked = readChapters >= requiredRead;

    // Breathing pulse along the path — brighter near the "head" of progress.
    final double waveLocal =
        sin(glowAnimation * 2 * pi + idx * 0.18);
    final double glow = (0.5 + 0.5 * waveLocal).clamp(0.0, 1.0);

    if (walked) {
      // Lit stone, terracotta, glowing.
      final top = Color.lerp(_pathTop, _pathTopLit, 0.45 + 0.35 * glow)!;
      final side = Color.lerp(_pathTop, Colors.black, 0.4)!;
      // Tile is slim (z=0.25) so it reads as paving, not a full wall cube.
      _drawSlab(canvas, origin, d.x, d.y, d.z, 0.25, top, side);

      // Warm halo under each lit stone.
      final center = _project(d.x + 0.5, d.y + 0.5, d.z + 0.26, origin);
      final halo = Paint()
        ..color = _pathTopLit.withValues(alpha: 0.18 + 0.12 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, blockSize * 0.7, halo);
    } else {
      // Un-walked stone: same shape, muted color.
      final top = Color.lerp(_pathTop, _bg, 0.55)!;
      final side = Color.lerp(_pathTop, Colors.black, 0.65)!;
      _drawSlab(canvas, origin, d.x, d.y, d.z, 0.22, top, side);
    }
  }

  // ---------------------------------------------------------------------------
  // Shape primitives
  // ---------------------------------------------------------------------------

  /// Full 1×1×1 cube.
  void _drawCube(Canvas canvas, Offset origin, double x, double y, double z,
      Color topColor, Color sideColor) {
    _drawBox(canvas, origin, x, y, z, 1, 1, 1, topColor, sideColor);
  }

  /// Flat slab (1×1×h, h<1).
  void _drawSlab(Canvas canvas, Offset origin, double x, double y, double z,
      double h, Color topColor, Color sideColor) {
    _drawBox(canvas, origin, x, y, z, 1, 1, h, topColor, sideColor);
  }

  /// Narrow pillar (w×w×h centered on tile).
  void _drawNarrow(Canvas canvas, Offset origin, double x, double y, double z,
      double w, double h, Color topColor, Color sideColor) {
    final pad = (1 - w) / 2;
    _drawBox(canvas, origin, x + pad, y + pad, z, w, w, h, topColor, sideColor);
  }

  /// Generalized axis-aligned box at (x,y,z), size (w,d,h).
  void _drawBox(Canvas canvas, Offset origin, double x, double y, double z,
      double w, double d, double h, Color topColor, Color sideColor) {
    final darkSide = Color.lerp(sideColor, Colors.black, 0.15)!;

    final p1 = _project(x + w, y, z, origin);
    final p2 = _project(x + w, y + d, z, origin);
    final p4 = _project(x, y, z + h, origin);
    final p5 = _project(x + w, y, z + h, origin);
    final p6 = _project(x + w, y + d, z + h, origin);
    final p7 = _project(x, y + d, z + h, origin);
    final p3 = _project(x, y + d, z, origin);

    // Top.
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

    // Left (front-y).
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

    // Right (front-x).
    final rightPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p5.dx, p5.dy)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = darkSide);
    canvas.drawPath(
      rightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  void _drawWireframeTile(
      Canvas canvas, Offset origin, double x, double y, double z) {
    final paint = Paint()
      ..color = _wireframe
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    final p4 = _project(x, y, z + 0.22, origin);
    final p5 = _project(x + 1, y, z + 0.22, origin);
    final p6 = _project(x + 1, y + 1, z + 0.22, origin);
    final p7 = _project(x, y + 1, z + 0.22, origin);

    final top = Path()
      ..moveTo(p4.dx, p4.dy)
      ..lineTo(p5.dx, p5.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p7.dx, p7.dy)
      ..close();
    canvas.drawPath(top, paint);
  }

  @override
  bool shouldRepaint(covariant PilgrimBMazePainter old) {
    return old.readChapters != readChapters ||
        old.glowAnimation != glowAnimation ||
        old.introAnimation != introAnimation ||
        old.totalChapters != totalChapters;
  }
}

// ---------------------------------------------------------------------------
// Small plain-data types (private)
// ---------------------------------------------------------------------------

@immutable
class _Tile {
  final int x;
  final int y;
  const _Tile(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is _Tile && other.x == x && other.y == y;

  @override
  int get hashCode => x * 1000003 ^ y;
}

class _WallCell {
  final int x;
  final int y;
  final int h;
  const _WallCell(this.x, this.y, this.h);
}

enum _LandmarkKind {
  wicketGate,
  interpreterHouse,
  covenantStone,
  lantern,
}

class _Landmark {
  final int x;
  final int y;
  final _LandmarkKind kind;
  const _Landmark(this.x, this.y, this.kind);
}

class _Rect {
  final int x;
  final int y;
  final int w;
  final int h;
  const _Rect(this.x, this.y, this.w, this.h);

  bool contains(int px, int py) =>
      px >= x && py >= y && px < x + w && py < y + h;
}

enum _DrawKind {
  wall,
  destruction,
  celestialWall,
  celestialSpire,
  swamp,
  vanityBooth,
  vanityBoothTop,
  gatePillar,
  gateLintel,
  interpreter,
  interpreterRoof,
  covenantStone,
  lanternPost,
  lanternHead,
  path,
  deadEnd,
}

class _Drawable {
  final double x;
  final double y;
  final double z;
  final _DrawKind kind;
  final int? pathIndex;
  _Drawable(this.x, this.y, this.z, this.kind, {this.pathIndex});
}
