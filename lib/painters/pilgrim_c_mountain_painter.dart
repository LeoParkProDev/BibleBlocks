import 'dart:math';
import 'package:flutter/material.dart';

// =============================================================================
// PilgrimC Mountain Painter
// -----------------------------------------------------------------------------
// Voxel/isometric rendering of a Pilgrim's Progress mountain landscape.
//
// World layout (x, y, z):
//   x -> east   (0..GRID_W-1)
//   y -> south  (0..GRID_H-1)
//   z -> up     (terrain top = heightmap[x][y])
//
// The Way runs as a continuous path of stone voxels that float +0.5 above the
// terrain so it is always legible. Landmarks are carved as tagged voxel
// regions. 1,189 "chapters" are mapped onto the path segments in order of
// path progression, so pilgrimage progress visually fills the trail.
// =============================================================================

// ---------- Voxel types -----------------------------------------------------

enum PilgrimCVoxelType {
  terrainLow,
  terrainMid,
  terrainHigh,
  terrainPeak,
  swampMud,
  swampWater,
  interpreterHouse,
  interpreterRoof,
  valleyHumble,
  valleyShadow,
  shiningPeak,
  jordanRiver,
  celestialWall,
  celestialTower,
  celestialGate,
  tree,
  bush,
  cloud,
  pathStone,
  burden,
  cross,
  ruinedBrick,
  emberFire,
  wicketGateStone,
  wicketGateGlow,
  treeOfLife,
  gemstone,
  apollyonBody,
  apollyonWing,
  smoke,
  lava,
  skull,
  deadTree,
  fairTent,
  fairFlag,
  cage,
}

class PilgrimCVoxel {
  final int x;
  final int y;
  final int z;
  final PilgrimCVoxelType type;
  final int pathIndex; // -1 if not a path stone
  const PilgrimCVoxel({
    required this.x,
    required this.y,
    required this.z,
    required this.type,
    this.pathIndex = -1,
  });
}

// ---------- Builder ---------------------------------------------------------

class PilgrimCLandscape {
  static const int gridW = 60;
  static const int gridH = 40;
  static const int totalChapters = 1189;

  // Lazily built, cached.
  static List<PilgrimCVoxel>? _voxels;
  static List<List<int>>? _heightmap;
  static List<_PathWaypoint>? _pathSegments;
  static int _maxHeight = 0;

  static List<PilgrimCVoxel> get voxels {
    _ensureBuilt();
    return _voxels!;
  }

  static List<List<int>> get heightmap {
    _ensureBuilt();
    return _heightmap!;
  }

  static int get maxHeight {
    _ensureBuilt();
    return _maxHeight;
  }

  static int get pathLength {
    _ensureBuilt();
    return _pathSegments!.length;
  }

  static void _ensureBuilt() {
    if (_voxels != null) return;
    final hm = _buildHeightmap();
    final voxels = <PilgrimCVoxel>[];

    // Terrain column voxels
    for (int x = 0; x < gridW; x++) {
      for (int y = 0; y < gridH; y++) {
        final h = hm[x][y];
        if (h < 0) continue;
        // Render only the top few slabs to keep voxel count sane while
        // preserving the isometric silhouette — lower columns are hidden
        // by upper rows anyway.
        final start = max(0, h - 3);
        for (int z = start; z <= h; z++) {
          voxels.add(PilgrimCVoxel(
            x: x,
            y: y,
            z: z,
            type: _classifyTerrain(x, y, z, h),
          ));
        }
      }
    }

    // Landmark overlays (swamps, valleys, river, peak, city).
    _addLandmarks(voxels, hm);

    // Trees / bushes / clouds.
    _addScenery(voxels, hm);

    // The Way — path from Wicket Gate (west) to Celestial City (east).
    final waypoints = _buildPathWaypoints();
    _pathSegments = waypoints;
    for (int i = 0; i < waypoints.length; i++) {
      final wp = waypoints[i];
      final groundH = hm[wp.x][wp.y];
      // Path floats slightly above terrain so it is always visible.
      final pz = groundH + 1;
      voxels.add(PilgrimCVoxel(
        x: wp.x,
        y: wp.y,
        z: pz,
        type: PilgrimCVoxelType.pathStone,
        pathIndex: i,
      ));
    }

    // Precompute max height for lighting normalization.
    int mx = 0;
    for (int x = 0; x < gridW; x++) {
      for (int y = 0; y < gridH; y++) {
        if (hm[x][y] > mx) mx = hm[x][y];
      }
    }
    _maxHeight = mx;
    _heightmap = hm;
    _voxels = voxels;
  }

  // -------------------------------------------------------------------------
  // Heightmap — layered sinusoidal noise + hand-placed features
  // -------------------------------------------------------------------------
  static List<List<int>> _buildHeightmap() {
    final hm =
        List.generate(gridW, (_) => List<int>.filled(gridH, 0, growable: false));
    final rng = Random(7);

    // Base rolling hills via layered sine waves.
    for (int x = 0; x < gridW; x++) {
      for (int y = 0; y < gridH; y++) {
        final nx = x / gridW;
        final ny = y / gridH;

        // Large-scale ridge that rises toward Celestial City in the east.
        final rise = (nx * 1.2).clamp(0.0, 1.0);

        // Layered waves.
        final w1 = sin(nx * 4.2 + 0.3) * cos(ny * 3.1 + 1.1) * 2.5;
        final w2 = sin(nx * 9.0 + ny * 6.2) * 1.2;
        final w3 = cos(nx * 13.0 - ny * 8.0 + 0.7) * 0.6;
        final jitter = (rng.nextDouble() - 0.5) * 0.6;

        double h = 2.0 + rise * 4.0 + w1 + w2 + w3 + jitter;

        // Carve a gentle plain corridor near mid-y for the first third of
        // the journey so the City of Destruction / Plain section reads clear.
        if (nx < 0.18) {
          h = 1.5 + (rng.nextDouble() - 0.5) * 0.4;
        }

        hm[x][y] = h.clamp(0, 14).round();
      }
    }

    // Slough of Despond — depression around (x=10..14, y=16..22)
    for (int x = 10; x <= 14; x++) {
      for (int y = 16; y <= 22; y++) {
        hm[x][y] = 0;
      }
    }

    // Interpreter's plateau — flat raised ground around (x=18..21, y=14..17)
    for (int x = 18; x <= 21; x++) {
      for (int y = 14; y <= 17; y++) {
        hm[x][y] = 3;
      }
    }

    // Valley of Humiliation — narrow dip around (x=25..29, y=18..22)
    for (int x = 25; x <= 29; x++) {
      for (int y = 18; y <= 22; y++) {
        hm[x][y] = 1;
      }
    }

    // Valley of the Shadow of Death — black canyon (x=31..35, y=17..23)
    for (int x = 31; x <= 35; x++) {
      for (int y = 17; y <= 23; y++) {
        hm[x][y] = (y == 20) ? 0 : 2; // narrow 1-wide floor with cliffs
      }
      // Tall cliff walls.
      hm[x][17] = 7;
      hm[x][23] = 7;
    }

    // Delectable / Shining Mountains — tall range (x=40..46, y=10..28)
    for (int x = 40; x <= 46; x++) {
      for (int y = 10; y <= 28; y++) {
        final cx = (x - 43).abs();
        final cy = (y - 19).abs();
        final dist = sqrt((cx * cx + cy * cy * 0.7).toDouble());
        final peakH = (13 - dist * 1.3).round();
        if (peakH > hm[x][y]) hm[x][y] = peakH.clamp(3, 13);
      }
    }

    // Jordan riverbed — low strip around x=50
    for (int x = 49; x <= 51; x++) {
      for (int y = 12; y <= 28; y++) {
        hm[x][y] = 0;
      }
    }

    // Celestial City plateau on the eastern edge (x=54..58, y=16..24)
    for (int x = 54; x <= 58; x++) {
      for (int y = 16; y <= 24; y++) {
        hm[x][y] = 6;
      }
    }

    return hm;
  }

  static PilgrimCVoxelType _classifyTerrain(int x, int y, int z, int topH) {
    if (topH <= 1) return PilgrimCVoxelType.terrainLow;
    if (topH <= 4) return PilgrimCVoxelType.terrainLow;
    if (topH <= 7) return PilgrimCVoxelType.terrainMid;
    if (topH <= 10) return PilgrimCVoxelType.terrainHigh;
    return PilgrimCVoxelType.terrainPeak;
  }

  // -------------------------------------------------------------------------
  // Landmarks (stamped as voxels over the terrain).
  // -------------------------------------------------------------------------
  static void _addLandmarks(
      List<PilgrimCVoxel> voxels, List<List<int>> hm) {
    // City of Destruction (멸망의 도시) — ruined buildings + embers
    for (int x = 0; x <= 4; x++) {
      for (int y = 20; y <= 26; y++) {
        final bh = hm[x][y];
        if ((x + y) % 3 == 0) {
          final ruinH = bh + 2 + (x % 2);
          for (int z = bh + 1; z <= ruinH; z++) {
            voxels.add(PilgrimCVoxel(x: x, y: y, z: z,
                type: PilgrimCVoxelType.ruinedBrick));
          }
        }
      }
    }
    for (final pos in const [(1, 21), (3, 23), (2, 25), (0, 22), (4, 24)]) {
      final bh = hm[pos.$1][pos.$2];
      voxels.add(PilgrimCVoxel(x: pos.$1, y: pos.$2, z: bh + 1,
          type: PilgrimCVoxelType.emberFire));
    }

    // Wicket Gate (좁은 문) — white stone pillars + arch + glow
    final gateH = hm[6][20];
    for (int z = gateH + 1; z <= gateH + 4; z++) {
      voxels.add(PilgrimCVoxel(x: 6, y: 19, z: z,
          type: PilgrimCVoxelType.wicketGateStone));
      voxels.add(PilgrimCVoxel(x: 6, y: 21, z: z,
          type: PilgrimCVoxelType.wicketGateStone));
    }
    voxels.add(PilgrimCVoxel(x: 6, y: 20, z: gateH + 4,
        type: PilgrimCVoxelType.wicketGateStone));
    voxels.add(PilgrimCVoxel(x: 6, y: 20, z: gateH + 2,
        type: PilgrimCVoxelType.wicketGateGlow));
    voxels.add(PilgrimCVoxel(x: 6, y: 20, z: gateH + 3,
        type: PilgrimCVoxelType.wicketGateGlow));

    // Slough of Despond — mud + dark water filling the depression.
    for (int x = 10; x <= 14; x++) {
      for (int y = 16; y <= 22; y++) {
        voxels.add(PilgrimCVoxel(
          x: x, y: y, z: 0,
          type: PilgrimCVoxelType.swampWater,
        ));
        if ((x + y) % 2 == 0) {
          voxels.add(PilgrimCVoxel(
            x: x, y: y, z: 1,
            type: PilgrimCVoxelType.swampMud,
          ));
        }
      }
    }

    // Interpreter's House — stone cottage on plateau at (19..20, 15..16)
    for (int x = 19; x <= 20; x++) {
      for (int y = 15; y <= 16; y++) {
        for (int z = 4; z <= 5; z++) {
          voxels.add(PilgrimCVoxel(
            x: x, y: y, z: z,
            type: PilgrimCVoxelType.interpreterHouse,
          ));
        }
      }
    }
    // Pitched roof peak.
    voxels.add(const PilgrimCVoxel(
      x: 19, y: 15, z: 6, type: PilgrimCVoxelType.interpreterRoof));
    voxels.add(const PilgrimCVoxel(
      x: 20, y: 15, z: 6, type: PilgrimCVoxelType.interpreterRoof));
    voxels.add(const PilgrimCVoxel(
      x: 19, y: 16, z: 6, type: PilgrimCVoxelType.interpreterRoof));
    voxels.add(const PilgrimCVoxel(
      x: 20, y: 16, z: 6, type: PilgrimCVoxelType.interpreterRoof));
    voxels.add(const PilgrimCVoxel(
      x: 19, y: 15, z: 7, type: PilgrimCVoxelType.interpreterRoof));
    voxels.add(const PilgrimCVoxel(
      x: 20, y: 16, z: 7, type: PilgrimCVoxelType.interpreterRoof));

    // Cross Hill (십자가 언덕) — Christian's burden falls off at the cross
    // Raise mound
    for (int x = 22; x <= 24; x++) {
      for (int y = 16; y <= 18; y++) {
        if (hm[x][y] < 4) hm[x][y] = 4;
      }
    }
    // Gold cross (vertical beam + crossbar)
    voxels.add(const PilgrimCVoxel(x: 23, y: 17, z: 5, type: PilgrimCVoxelType.cross));
    voxels.add(const PilgrimCVoxel(x: 23, y: 17, z: 6, type: PilgrimCVoxelType.cross));
    voxels.add(const PilgrimCVoxel(x: 23, y: 17, z: 7, type: PilgrimCVoxelType.cross));
    voxels.add(const PilgrimCVoxel(x: 22, y: 17, z: 6, type: PilgrimCVoxelType.cross)); // left arm
    voxels.add(const PilgrimCVoxel(x: 24, y: 17, z: 6, type: PilgrimCVoxelType.cross)); // right arm
    // Burden tumbled at base
    voxels.add(const PilgrimCVoxel(x: 23, y: 18, z: 4, type: PilgrimCVoxelType.burden));
    voxels.add(const PilgrimCVoxel(x: 24, y: 18, z: 4, type: PilgrimCVoxelType.burden));
    voxels.add(const PilgrimCVoxel(x: 23, y: 19, z: 3, type: PilgrimCVoxelType.burden));
    voxels.add(const PilgrimCVoxel(x: 24, y: 19, z: 3, type: PilgrimCVoxelType.burden));
    voxels.add(const PilgrimCVoxel(x: 25, y: 19, z: 3, type: PilgrimCVoxelType.burden));

    // Valley of Humiliation — moss/darker ground tinting (add a thin layer).
    for (int x = 25; x <= 29; x++) {
      for (int y = 18; y <= 22; y++) {
        voxels.add(PilgrimCVoxel(
          x: x, y: y, z: 1,
          type: PilgrimCVoxelType.valleyHumble,
        ));
      }
    }

    // Apollyon (아폴리온) — dragon beast in the Valley of Humiliation
    // Body core
    for (int z = 3; z <= 5; z++) {
      voxels.add(PilgrimCVoxel(x: 27, y: 20, z: z, type: PilgrimCVoxelType.apollyonBody));
    }
    voxels.add(const PilgrimCVoxel(x: 27, y: 19, z: 4, type: PilgrimCVoxelType.apollyonBody));
    voxels.add(const PilgrimCVoxel(x: 27, y: 21, z: 4, type: PilgrimCVoxelType.apollyonBody));
    // Head
    voxels.add(const PilgrimCVoxel(x: 26, y: 20, z: 5, type: PilgrimCVoxelType.apollyonBody));
    voxels.add(const PilgrimCVoxel(x: 26, y: 20, z: 6, type: PilgrimCVoxelType.apollyonBody));
    // Wings spread (y=18..22)
    for (int y = 18; y <= 22; y++) {
      if (y == 20) continue;
      voxels.add(PilgrimCVoxel(x: 27, y: y, z: 5, type: PilgrimCVoxelType.apollyonWing));
      if (y == 18 || y == 22) {
        voxels.add(PilgrimCVoxel(x: 27, y: y, z: 6, type: PilgrimCVoxelType.apollyonWing));
      }
    }
    voxels.add(const PilgrimCVoxel(x: 28, y: 18, z: 5, type: PilgrimCVoxelType.apollyonWing));
    voxels.add(const PilgrimCVoxel(x: 28, y: 22, z: 5, type: PilgrimCVoxelType.apollyonWing));
    // Tail
    voxels.add(const PilgrimCVoxel(x: 28, y: 20, z: 3, type: PilgrimCVoxelType.apollyonBody));
    voxels.add(const PilgrimCVoxel(x: 29, y: 20, z: 3, type: PilgrimCVoxelType.apollyonBody));
    voxels.add(const PilgrimCVoxel(x: 29, y: 20, z: 4, type: PilgrimCVoxelType.apollyonBody));
    // Smoke
    for (final s in const [(26, 19, 7), (26, 21, 7), (27, 20, 7), (28, 19, 6), (28, 21, 6)]) {
      voxels.add(PilgrimCVoxel(x: s.$1, y: s.$2, z: s.$3, type: PilgrimCVoxelType.smoke));
    }

    // Valley of the Shadow of Death — deep chasm with lava, skulls, dead trees
    for (int x = 31; x <= 35; x++) {
      // Towering cliff walls (z=3..12)
      for (int z = 3; z <= 12; z++) {
        voxels.add(PilgrimCVoxel(x: x, y: 17, z: z,
            type: PilgrimCVoxelType.valleyShadow));
        voxels.add(PilgrimCVoxel(x: x, y: 23, z: z,
            type: PilgrimCVoxelType.valleyShadow));
      }
      // Second cliff row for thickness
      for (int z = 3; z <= 10; z++) {
        voxels.add(PilgrimCVoxel(x: x, y: 18, z: z,
            type: PilgrimCVoxelType.valleyShadow));
        voxels.add(PilgrimCVoxel(x: x, y: 22, z: z,
            type: PilgrimCVoxelType.valleyShadow));
      }
      // Dark floor
      for (int y = 19; y <= 21; y++) {
        voxels.add(PilgrimCVoxel(x: x, y: y, z: 0,
            type: PilgrimCVoxelType.valleyShadow));
      }
    }
    // Lava cracks in the floor
    for (final lv in const [(32, 19), (33, 20), (34, 21), (31, 20)]) {
      voxels.add(PilgrimCVoxel(x: lv.$1, y: lv.$2, z: 0,
          type: PilgrimCVoxelType.lava));
    }
    // Skulls scattered
    for (final sk in const [(31, 19, 1), (33, 21, 1), (35, 19, 1), (34, 20, 1)]) {
      voxels.add(PilgrimCVoxel(x: sk.$1, y: sk.$2, z: sk.$3,
          type: PilgrimCVoxelType.skull));
    }
    // Dead trees on cliff tops
    for (final dt in const [(31, 17, 13), (33, 17, 13), (35, 23, 13), (32, 23, 13)]) {
      voxels.add(PilgrimCVoxel(x: dt.$1, y: dt.$2, z: dt.$3,
          type: PilgrimCVoxelType.deadTree));
      voxels.add(PilgrimCVoxel(x: dt.$1, y: dt.$2, z: dt.$3 + 1,
          type: PilgrimCVoxelType.deadTree));
    }

    // Vanity Fair (허영의 시장) — colorful tents, flags, cage at x=36..38
    // Flatten terrain for marketplace
    for (int x = 36; x <= 38; x++) {
      for (int y = 17; y <= 22; y++) {
        if (hm[x][y] < 3) hm[x][y] = 3;
      }
    }
    // Tents (3 colorful stalls)
    for (final tent in const [(36, 18), (37, 20), (38, 22)]) {
      final bh = hm[tent.$1][tent.$2];
      for (int z = bh + 1; z <= bh + 2; z++) {
        voxels.add(PilgrimCVoxel(x: tent.$1, y: tent.$2, z: z,
            type: PilgrimCVoxelType.fairTent));
        voxels.add(PilgrimCVoxel(x: tent.$1, y: tent.$2 + 1, z: z,
            type: PilgrimCVoxelType.fairTent));
      }
      // Tent roof (one higher)
      voxels.add(PilgrimCVoxel(x: tent.$1, y: tent.$2, z: bh + 3,
          type: PilgrimCVoxelType.fairTent));
      voxels.add(PilgrimCVoxel(x: tent.$1, y: tent.$2 + 1, z: bh + 3,
          type: PilgrimCVoxelType.fairTent));
    }
    // Flags on poles
    for (final flag in const [(36, 17), (37, 19), (38, 21)]) {
      final bh = hm[flag.$1][flag.$2];
      for (int z = bh + 1; z <= bh + 4; z++) {
        voxels.add(PilgrimCVoxel(x: flag.$1, y: flag.$2, z: z,
            type: PilgrimCVoxelType.fairFlag));
      }
    }
    // Cage
    final cageH = hm[37][22];
    for (int z = cageH + 1; z <= cageH + 2; z++) {
      voxels.add(PilgrimCVoxel(x: 37, y: 22, z: z,
          type: PilgrimCVoxelType.cage));
    }

    // Shining Mountains — replace peak tops with bright shining voxels.
    for (int x = 40; x <= 46; x++) {
      for (int y = 10; y <= 28; y++) {
        final h = hm[x][y];
        if (h >= 10) {
          voxels.add(PilgrimCVoxel(
            x: x, y: y, z: h,
            type: PilgrimCVoxelType.shiningPeak,
          ));
        }
      }
    }

    // Jordan River — flowing blue band.
    for (int x = 49; x <= 51; x++) {
      for (int y = 12; y <= 28; y++) {
        voxels.add(PilgrimCVoxel(
          x: x, y: y, z: 0,
          type: PilgrimCVoxelType.jordanRiver,
        ));
      }
    }

    // Celestial City — expanded fortress (Rev 21), x=54..58, y=16..24
    // Outer walls — higher (z=7..12)
    for (int x = 54; x <= 58; x++) {
      for (int y = 16; y <= 24; y++) {
        final isEdge = x == 54 || x == 58 || y == 16 || y == 24;
        if (isEdge) {
          for (int z = 7; z <= 12; z++) {
            voxels.add(PilgrimCVoxel(x: x, y: y, z: z,
                type: PilgrimCVoxelType.celestialWall));
          }
        }
      }
    }
    // Corner towers (4) — tallest
    for (final pos in const [(54, 16), (58, 16), (54, 24), (58, 24)]) {
      for (int z = 13; z <= 16; z++) {
        voxels.add(PilgrimCVoxel(x: pos.$1, y: pos.$2, z: z,
            type: PilgrimCVoxelType.celestialTower));
      }
    }
    // Mid-wall towers (4)
    for (final pos in const [(56, 16), (56, 24), (54, 20), (58, 20)]) {
      for (int z = 13; z <= 15; z++) {
        voxels.add(PilgrimCVoxel(x: pos.$1, y: pos.$2, z: z,
            type: PilgrimCVoxelType.celestialTower));
      }
    }
    // Facade flanking towers
    for (final pos in const [(54, 18), (54, 22)]) {
      for (int z = 13; z <= 15; z++) {
        voxels.add(PilgrimCVoxel(x: pos.$1, y: pos.$2, z: z,
            type: PilgrimCVoxelType.celestialTower));
      }
    }
    // Inner keep — tall central structure
    for (int x = 55; x <= 57; x++) {
      for (int y = 19; y <= 21; y++) {
        for (int z = 7; z <= 13; z++) {
          voxels.add(PilgrimCVoxel(x: x, y: y, z: z,
              type: PilgrimCVoxelType.celestialTower));
        }
      }
    }
    // Gate (3 tall)
    for (int z = 7; z <= 9; z++) {
      voxels.add(PilgrimCVoxel(x: 54, y: 20, z: z,
          type: PilgrimCVoxelType.celestialGate));
    }
    // Trees of Life (생명나무, Rev 22:2)
    for (final pos in const [(55, 17), (57, 23)]) {
      for (int z = 7; z <= 9; z++) {
        voxels.add(PilgrimCVoxel(x: pos.$1, y: pos.$2, z: z,
            type: PilgrimCVoxelType.treeOfLife));
      }
    }
    // Gemstones on walls (계시록 21장 보석 기초석)
    for (final gem in const [
      (54, 17, 9), (54, 19, 11), (54, 23, 9),
      (58, 17, 10), (58, 21, 9), (58, 23, 11),
      (55, 16, 10), (57, 24, 9), (56, 16, 11), (56, 24, 10),
    ]) {
      voxels.add(PilgrimCVoxel(x: gem.$1, y: gem.$2, z: gem.$3,
          type: PilgrimCVoxelType.gemstone));
    }
  }

  // -------------------------------------------------------------------------
  // Scenery — trees/bushes/clouds
  // -------------------------------------------------------------------------
  static void _addScenery(
      List<PilgrimCVoxel> voxels, List<List<int>> hm) {
    final rng = Random(42);
    // Trees — taller canopy with occasional 3-slab trunks
    for (int i = 0; i < 140; i++) {
      final x = rng.nextInt(gridW);
      final y = rng.nextInt(gridH);
      final h = hm[x][y];
      if (h < 2 || h > 9) continue;
      // Avoid landmark regions.
      if (_inRect(x, y, 10, 16, 14, 22)) continue; // swamp
      if (_inRect(x, y, 18, 14, 21, 17)) continue; // interpreter
      if (_inRect(x, y, 25, 18, 29, 22)) continue; // humiliation
      if (_inRect(x, y, 31, 17, 35, 23)) continue; // shadow
      if (_inRect(x, y, 40, 10, 46, 28)) continue; // shining mts
      if (_inRect(x, y, 49, 12, 51, 28)) continue; // jordan
      if (_inRect(x, y, 54, 16, 58, 24)) continue; // city
      final tall = rng.nextDouble() < 0.35;
      voxels.add(PilgrimCVoxel(x: x, y: y, z: h + 1, type: PilgrimCVoxelType.tree));
      voxels.add(PilgrimCVoxel(x: x, y: y, z: h + 2, type: PilgrimCVoxelType.tree));
      if (tall) {
        voxels.add(PilgrimCVoxel(x: x, y: y, z: h + 3, type: PilgrimCVoxelType.tree));
      }
    }
    // Bushes
    for (int i = 0; i < 110; i++) {
      final x = rng.nextInt(gridW);
      final y = rng.nextInt(gridH);
      final h = hm[x][y];
      if (h < 1 || h > 8) continue;
      voxels.add(PilgrimCVoxel(
        x: x, y: y, z: h + 1,
        type: PilgrimCVoxelType.bush,
      ));
    }
    // Clouds — more clusters spread across sky
    for (final cluster in const [
      (8, 4), (22, 6), (36, 4), (48, 8), (15, 32), (44, 34),
      (3, 14), (28, 2), (52, 30), (38, 26), (18, 36), (55, 6),
    ]) {
      final cx = cluster.$1;
      final cy = cluster.$2;
      for (int dx = 0; dx < 3; dx++) {
        for (int dy = 0; dy < 2; dy++) {
          voxels.add(PilgrimCVoxel(
            x: cx + dx, y: cy + dy, z: 14,
            type: PilgrimCVoxelType.cloud,
          ));
        }
      }
      voxels.add(PilgrimCVoxel(
        x: cx + 1, y: cy, z: 15,
        type: PilgrimCVoxelType.cloud,
      ));
    }
  }

  static bool _inRect(int x, int y, int x0, int y0, int x1, int y1) {
    return x >= x0 && x <= x1 && y >= y0 && y <= y1;
  }

  // -------------------------------------------------------------------------
  // Path waypoints — dense catmull-style polyline through landmarks.
  // -------------------------------------------------------------------------
  static List<_PathWaypoint> _buildPathWaypoints() {
    // Ordered anchor nodes the path must pass through.
    const anchors = <(int, int)>[
      (2, 22),   // City of Destruction
      (6, 20),
      (10, 19),  // Slough of Despond approach
      (14, 19),  // Slough crossing
      (17, 18),
      (19, 16),  // Interpreter's House
      (22, 17),
      (25, 20),  // Valley of Humiliation
      (29, 20),
      (33, 20),  // Valley of the Shadow
      (37, 19),
      (40, 19),  // Delectable foothills
      (43, 19),  // Shining Mountain saddle
      (46, 19),
      (48, 19),
      (50, 20),  // Jordan crossing
      (52, 20),
      (54, 20),  // Celestial Gate
    ];

    // Densify via linear interpolation — one voxel per cell along the trail.
    final dense = <_PathWaypoint>[];
    final used = <int>{}; // pack (x<<16)|y to dedupe
    for (int a = 0; a < anchors.length - 1; a++) {
      final x0 = anchors[a].$1;
      final y0 = anchors[a].$2;
      final x1 = anchors[a + 1].$1;
      final y1 = anchors[a + 1].$2;
      final dx = x1 - x0;
      final dy = y1 - y0;
      final steps = max(dx.abs(), dy.abs());
      for (int s = 0; s <= steps; s++) {
        final t = s / steps;
        final px = (x0 + dx * t).round();
        final py = (y0 + dy * t).round();
        final key = (px << 16) | py;
        if (used.contains(key)) continue;
        used.add(key);
        dense.add(_PathWaypoint(px, py));
      }
    }
    return dense;
  }
}

class _PathWaypoint {
  final int x;
  final int y;
  const _PathWaypoint(this.x, this.y);
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class PilgrimCMountainPainter extends CustomPainter {
  final double introAnimation; // 0..1
  final double pulseAnimation; // 0..1 (looping)
  final int readChapters; // 0..totalChapters

  PilgrimCMountainPainter({
    required this.introAnimation,
    required this.pulseAnimation,
    required this.readChapters,
  });

  // Isometric projection constants.
  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;
  static const double blockSize = 7.0;

  // Theme colors.
  static const Color _bg = Color(0xFF0a0a1a);
  static const Color _gold = Color(0xFFD4A843);
  static const Color _goldBright = Color(0xFFF5D467);
  static const Color _terracotta = Color(0xFFC47B5A);
  static const Color _secondary = Color(0xFF7A8E99);

  // Terrain palette.
  static const Color _tLow = Color(0xFF3B2A1E);     // dark earth
  static const Color _tMid = Color(0xFF5E5234);     // olive brown
  static const Color _tHigh = Color(0xFF897246);    // tan ridge
  static const Color _tPeak = Color(0xFFB89464);    // peak rock (receives gold)

  // Feature palette.
  static const Color _swampMud = Color(0xFF2A1F14);
  static const Color _swampWater = Color(0xFF1A2633);
  static const Color _interpreterStone = Color(0xFFC7BFAE);
  static const Color _interpreterRoof = Color(0xFF7A4A22);
  static const Color _valleyHumble = Color(0xFF3B4A3B);
  static const Color _valleyShadow = Color(0xFF0B0B12);
  static const Color _shining = Color(0xFFE8C67A);
  static const Color _jordanBlue = Color(0xFF3A6A8A);
  static const Color _jordanLight = Color(0xFF6A9EBF);
  static const Color _cityWall = Color(0xFFB88C3D);
  static const Color _cityTower = Color(0xFFE3B656);
  static const Color _cityGate = Color(0xFFF5E3A0);
  static const Color _treeLeaf = Color(0xFF3E5A3E);
  static const Color _bushLeaf = Color(0xFF57734E);
  static const Color _cloud = Color(0xFFD8D4E0);
  static const Color _pathStone = Color(0xFFC47B5A);
  static const Color _pathStoneLit = Color(0xFFE9A583);

  // ---------------------------------------------------------------------------

  Offset project(double x, double y, double z, Offset origin) {
    return Offset(
      origin.dx + (x - y) * _cos30 * blockSize,
      origin.dy + (x + y) * _sin30 * blockSize - z * blockSize,
    );
  }

  double _depthKey(num x, num y, num z) =>
      x.toDouble() + y.toDouble() - z.toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient: deep night with a sunset band near horizon.
    _drawBackground(canvas, size);

    // Anchor the scene so its center sits near canvas middle.
    const cx = (PilgrimCLandscape.gridW - 1) / 2.0;
    const cy = (PilgrimCLandscape.gridH - 1) / 2.0;
    final originShift = Offset(
      -(cx - cy) * _cos30 * blockSize,
      -(cx + cy) * _sin30 * blockSize,
    );
    final origin = Offset(
      size.width * 0.50 + originShift.dx,
      size.height * 0.52 + originShift.dy,
    );

    // Sort voxels back-to-front.
    final voxels = PilgrimCLandscape.voxels;
    final sorted = List<PilgrimCVoxel>.from(voxels)
      ..sort((a, b) {
        final da = _depthKey(a.x, a.y, a.z);
        final db = _depthKey(b.x, b.y, b.z);
        return da.compareTo(db);
      });

    final pathLen = PilgrimCLandscape.pathLength;
    final readCount =
        readChapters.clamp(0, PilgrimCLandscape.totalChapters);
    // How many path stones are "lit" by chapter progress.
    final litPathStones =
        (readCount * pathLen / PilgrimCLandscape.totalChapters).floor();

    for (final v in sorted) {
      // Intro stagger: diagonal reveal from west to east / low to high.
      final order = v.x + v.z * 0.5;
      final maxOrder =
          PilgrimCLandscape.gridW + PilgrimCLandscape.maxHeight * 0.5;
      final blockDelay = (order / maxOrder).clamp(0.0, 1.0) * 0.55;
      final localT =
          ((introAnimation - blockDelay) / 0.45).clamp(0.0, 1.0);
      if (localT <= 0) continue;
      final introOpacity = localT;
      final introZOff = (1.0 - localT) * 3.0;

      // Cloud drift + path pulse + city pulse handled below per-type.
      double zOff = introZOff;
      double extraAlpha = 1.0;

      switch (v.type) {
        case PilgrimCVoxelType.cloud:
          // Gentle horizontal drift expressed as a z-lift shimmer.
          zOff += sin(pulseAnimation * 2 * pi + v.x * 0.3) * 0.2;
          break;
        case PilgrimCVoxelType.swampWater:
          final wave = sin(pulseAnimation * 2 * pi + v.x * 0.7 + v.y * 0.5);
          extraAlpha = (0.75 + wave * 0.20).clamp(0.5, 1.0);
          break;
        case PilgrimCVoxelType.jordanRiver:
          final wave = sin(pulseAnimation * 2 * pi + v.y * 0.9);
          extraAlpha = (0.80 + wave * 0.18).clamp(0.5, 1.0);
          break;
        default:
          break;
      }

      // Path stone lighting — sequential glow by chapter progress.
      Color topColor;
      bool isLitPath = false;
      if (v.type == PilgrimCVoxelType.pathStone) {
        // Intro wave lights up stones in sequence so the Way "reveals".
        final introLight = (introAnimation * pathLen).floor();
        final progressLit = v.pathIndex < litPathStones;
        final introLit = v.pathIndex < introLight;
        isLitPath = progressLit || introLit;
        topColor = isLitPath ? _pathStoneLit : _pathStone;
      } else {
        topColor = _topColorForVoxel(v);
      }

      final vz = v.z.toDouble() + zOff;
      final alpha = (introOpacity * extraAlpha).clamp(0.0, 1.0);

      final color = alpha < 1.0
          ? topColor.withValues(alpha: topColor.a * alpha)
          : topColor;

      _drawCube(canvas, origin, v.x.toDouble(), v.y.toDouble(), vz, color);

      // Gold wash on true peaks (simulated rim light from east).
      if (v.type == PilgrimCVoxelType.terrainPeak && v.z >= 10) {
        final rimCenter = project(
            v.x.toDouble() + 0.5, v.y.toDouble() + 0.5, vz + 1.0, origin);
        final rimPaint = Paint()
          ..color = _gold.withValues(alpha: 0.18 * introOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(rimCenter, blockSize * 0.8, rimPaint);
      }

      // Path stone glow when lit.
      if (v.type == PilgrimCVoxelType.pathStone && isLitPath) {
        final glowCenter = project(
            v.x.toDouble() + 0.5, v.y.toDouble() + 0.5, vz + 1.3, origin);
        final pulse = 0.5 + 0.5 * sin(pulseAnimation * 2 * pi);
        final glowPaint = Paint()
          ..color = _terracotta
              .withValues(alpha: 0.18 + 0.10 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(glowCenter, blockSize * 0.55, glowPaint);
      }
    }

    // Celestial City aura — pulsing gold halo.
    final cityCenter = project(56.0, 20.0, 11.0, origin);
    final pulse = 0.5 + 0.5 * sin(pulseAnimation * 2 * pi);
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _goldBright.withValues(alpha: (0.35 + 0.15 * pulse) * introAnimation),
          _gold.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: cityCenter, radius: blockSize * 20),
      );
    canvas.drawCircle(cityCenter, blockSize * 20, auraPaint);

    // Foreground vignette.
    _drawVignette(canvas, size);
  }

  // -------------------------------------------------------------------------

  Color _topColorForVoxel(PilgrimCVoxel v) {
    switch (v.type) {
      case PilgrimCVoxelType.terrainLow:
        return _tLow;
      case PilgrimCVoxelType.terrainMid:
        return _tMid;
      case PilgrimCVoxelType.terrainHigh:
        return _tHigh;
      case PilgrimCVoxelType.terrainPeak:
        // Lerp toward gold at the very top.
        final t = ((v.z - 8) / 6).clamp(0.0, 1.0);
        return Color.lerp(_tPeak, _gold, t * 0.55)!;
      case PilgrimCVoxelType.swampMud:
        return _swampMud;
      case PilgrimCVoxelType.swampWater:
        return _swampWater;
      case PilgrimCVoxelType.interpreterHouse:
        return _interpreterStone;
      case PilgrimCVoxelType.interpreterRoof:
        return _interpreterRoof;
      case PilgrimCVoxelType.valleyHumble:
        return _valleyHumble;
      case PilgrimCVoxelType.valleyShadow:
        return _valleyShadow;
      case PilgrimCVoxelType.shiningPeak:
        return _shining;
      case PilgrimCVoxelType.jordanRiver:
        // Gradient from darker west edge to lighter east.
        final t = ((v.x - 49) / 2).clamp(0.0, 1.0);
        return Color.lerp(_jordanBlue, _jordanLight, t)!;
      case PilgrimCVoxelType.celestialWall:
        return _cityWall;
      case PilgrimCVoxelType.celestialTower:
        return _cityTower;
      case PilgrimCVoxelType.celestialGate:
        return _cityGate;
      case PilgrimCVoxelType.tree:
        return _treeLeaf;
      case PilgrimCVoxelType.bush:
        return _bushLeaf;
      case PilgrimCVoxelType.cloud:
        return _cloud;
      case PilgrimCVoxelType.pathStone:
        return _pathStone;
      case PilgrimCVoxelType.burden:
        return const Color(0xFF5A3A20);
      case PilgrimCVoxelType.cross:
        return _gold;
      case PilgrimCVoxelType.ruinedBrick:
        return const Color(0xFF2A1A14);
      case PilgrimCVoxelType.emberFire:
        return const Color(0xFFE85A20);
      case PilgrimCVoxelType.wicketGateStone:
        return const Color(0xFFE8E0D0);
      case PilgrimCVoxelType.wicketGateGlow:
        return _goldBright;
      case PilgrimCVoxelType.treeOfLife:
        return const Color(0xFF4A8A3A);
      case PilgrimCVoxelType.gemstone:
        return const Color(0xFF50C878);
      case PilgrimCVoxelType.apollyonBody:
        return const Color(0xFF6A1010);
      case PilgrimCVoxelType.apollyonWing:
        return const Color(0xFF4A0808);
      case PilgrimCVoxelType.smoke:
        return const Color(0xFF505050);
      case PilgrimCVoxelType.lava:
        return const Color(0xFFFF4500);
      case PilgrimCVoxelType.skull:
        return const Color(0xFFD0C8B0);
      case PilgrimCVoxelType.deadTree:
        return const Color(0xFF3A2A1A);
      case PilgrimCVoxelType.fairTent:
        return const Color(0xFFC04040);
      case PilgrimCVoxelType.fairFlag:
        return const Color(0xFF4040C0);
      case PilgrimCVoxelType.cage:
        return const Color(0xFF383838);
    }
  }

  // -------------------------------------------------------------------------

  void _drawCube(Canvas canvas, Offset origin, double x, double y, double z,
      Color topColor) {
    final sideColor = Color.lerp(topColor, Colors.black, 0.30)!;
    final darkSideColor = Color.lerp(topColor, Colors.black, 0.50)!;

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
        ..color = Colors.white.withValues(alpha: 0.07)
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
        ..color = Colors.white.withValues(alpha: 0.04)
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
        ..color = Colors.white.withValues(alpha: 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  // -------------------------------------------------------------------------

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = _bg;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Sunset band on the east (right).
    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          _bg.withValues(alpha: 0.0),
          _terracotta.withValues(alpha: 0.18),
          _gold.withValues(alpha: 0.30),
          _bg.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 0.80, 1.0],
      ).createShader(Offset.zero & size);
    final bandRect = Rect.fromLTWH(
        0, size.height * 0.35, size.width, size.height * 0.25);
    canvas.drawRect(bandRect, bandPaint);

    // Faint stars.
    final rng = Random(11);
    final starPaint = Paint();
    for (int i = 0; i < 60; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = rng.nextDouble() * size.height * 0.55;
      final a = 0.15 + rng.nextDouble() * 0.4;
      starPaint.color = Colors.white.withValues(alpha: a * introAnimation);
      canvas.drawCircle(Offset(sx, sy), rng.nextDouble() * 0.9 + 0.4,
          starPaint);
    }
  }

  void _drawVignette(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: 0.35),
        ],
        stops: const [0.65, 1.0],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  // -------------------------------------------------------------------------

  @override
  bool shouldRepaint(covariant PilgrimCMountainPainter old) {
    return old.introAnimation != introAnimation ||
        old.pulseAnimation != pulseAnimation ||
        old.readChapters != readChapters;
  }
}
