import 'dart:math';
import 'package:flutter/material.dart';

// PilgrimD — Journey Scroll (Side-Scrolling Diorama)
// A long horizontal parchment showing 14 stages of the pilgrim's journey,
// from City of Destruction (left) to the Celestial City (right). A single
// continuous winding voxel path connects all stages.

enum ScrollVoxelKind {
  pathStone,
  ruin,
  gate,
  stoneCottage,
  candle,
  cross,
  tomb,
  hill,
  palace,
  valleyFloor,
  cliff,
  tentRed,
  tentBlue,
  tentGreen,
  fortress,
  goldPeak,
  meadow,
  water,
  cityWall,
  cityTower,
  cityGate,
}

class ScrollVoxel {
  final double x;
  final double y;
  final double z;
  final ScrollVoxelKind kind;
  final int order;
  const ScrollVoxel({
    required this.x,
    required this.y,
    required this.z,
    required this.kind,
    this.order = -1,
  });
}

class ScrollStage {
  final double centerX;
  final String label;
  const ScrollStage(this.centerX, this.label);
}

class ScrollScene {
  static const double totalLength = 220;
  static const List<ScrollStage> stages = [
    ScrollStage(6, '멸망의 도시'),
    ScrollStage(22, '좁은 문'),
    ScrollStage(38, '해석자의 집'),
    ScrollStage(54, '십자가와 무덤'),
    ScrollStage(70, '난관의 언덕'),
    ScrollStage(86, '미의 궁전'),
    ScrollStage(102, '겸손의 골짜기'),
    ScrollStage(118, '사망의 골짜기'),
    ScrollStage(134, '허영의 시장'),
    ScrollStage(150, '절망의 성'),
    ScrollStage(166, '빛나는 산'),
    ScrollStage(182, '매혹의 땅'),
    ScrollStage(198, '요단강'),
    ScrollStage(214, '천성'),
  ];

  static ScrollScene? _instance;
  static ScrollScene get instance => _instance ??= ScrollScene._build();

  final List<ScrollVoxel> voxels;
  final List<ScrollVoxel> pathVoxels; // ordered left→right
  final int maxOrder;
  ScrollScene._(this.voxels, this.pathVoxels, this.maxOrder);

  static double _pathY(double x) {
    return sin(x * 0.22) * 1.1 + sin(x * 0.09 + 1.1) * 0.8;
  }

  static ScrollVoxel _v(
      double x, double y, double z, ScrollVoxelKind k, int order) {
    return ScrollVoxel(x: x, y: y, z: z, kind: k, order: order);
  }

  static ScrollScene _build() {
    final voxels = <ScrollVoxel>[];
    final pathVoxels = <ScrollVoxel>[];
    int order = 0;

    // Path — 3-wide winding strip
    const step = 0.8;
    for (double x = 2; x <= totalLength - 4; x += step) {
      final yc = _pathY(x);
      for (int dy = -1; dy <= 1; dy++) {
        final v = ScrollVoxel(
          x: x,
          y: yc + dy.toDouble(),
          z: 0,
          kind: ScrollVoxelKind.pathStone,
          order: order++,
        );
        voxels.add(v);
        if (dy == 0) pathVoxels.add(v);
      }
    }

    for (final stage in stages) {
      _addStageDiorama(voxels, stage, order);
      order += 200;
    }

    return ScrollScene._(voxels, pathVoxels, order);
  }

  static void _addStageDiorama(
      List<ScrollVoxel> out, ScrollStage s, int baseOrder) {
    final x = s.centerX;
    final yBase = _pathY(x);
    int n = 0;
    void add(double dx, double dy, double z, ScrollVoxelKind k) {
      out.add(_v(x + dx, yBase + dy, z, k, baseOrder + n++));
    }

    switch (s.label) {
      case '멸망의 도시':
        for (int i = -3; i <= -1; i++) {
          for (int z = 0; z < 2 + i.abs() % 2; z++) {
            add(i.toDouble(), -2, z.toDouble(), ScrollVoxelKind.ruin);
          }
        }
        add(-2, -3, 0, ScrollVoxelKind.ruin);
        add(-3, -1, 0, ScrollVoxelKind.ruin);
        break;
      case '좁은 문':
        add(0, -2, 0, ScrollVoxelKind.gate);
        add(0, -2, 1, ScrollVoxelKind.gate);
        add(0, -2, 2, ScrollVoxelKind.gate);
        add(-1, -2, 2, ScrollVoxelKind.gate);
        add(1, -2, 2, ScrollVoxelKind.gate);
        break;
      case '해석자의 집':
        for (int dx = -1; dx <= 1; dx++) {
          for (int dz = 0; dz < 2; dz++) {
            add(dx.toDouble(), -3, dz.toDouble(),
                ScrollVoxelKind.stoneCottage);
          }
        }
        add(0, -3, 2, ScrollVoxelKind.stoneCottage);
        add(0, -2.5, 0.6, ScrollVoxelKind.candle);
        break;
      case '십자가와 무덤':
        add(0, -2, 0, ScrollVoxelKind.cross);
        add(0, -2, 1, ScrollVoxelKind.cross);
        add(0, -2, 2, ScrollVoxelKind.cross);
        add(0, -2, 3, ScrollVoxelKind.cross);
        add(-1, -2, 2, ScrollVoxelKind.cross);
        add(1, -2, 2, ScrollVoxelKind.cross);
        for (int dx = -1; dx <= 1; dx++) {
          add(dx.toDouble(), -3.5, 0, ScrollVoxelKind.tomb);
        }
        break;
      case '난관의 언덕':
        for (int dx = -2; dx <= 2; dx++) {
          final h = (3 - (dx.abs())).clamp(0, 3);
          for (int z = 0; z < h; z++) {
            add(dx.toDouble(), -2.5, z.toDouble(), ScrollVoxelKind.hill);
          }
        }
        break;
      case '미의 궁전':
        for (int dx = -2; dx <= 2; dx++) {
          for (int dz = 0; dz < 3; dz++) {
            add(dx.toDouble(), -3, dz.toDouble(), ScrollVoxelKind.palace);
          }
        }
        for (int dx = -1; dx <= 1; dx++) {
          add(dx.toDouble(), -3, 3, ScrollVoxelKind.palace);
        }
        add(0, -3, 4, ScrollVoxelKind.palace);
        break;
      case '겸손의 골짜기':
        for (int dx = -2; dx <= 2; dx++) {
          add(dx.toDouble(), -2.5, -0.3, ScrollVoxelKind.valleyFloor);
        }
        break;
      case '사망의 골짜기':
        for (int dx = -2; dx <= 2; dx += 2) {
          for (int dz = 0; dz < 3; dz++) {
            add(dx.toDouble(), -2.8, dz.toDouble(), ScrollVoxelKind.cliff);
            add(dx.toDouble(), 2.8, dz.toDouble(), ScrollVoxelKind.cliff);
          }
        }
        break;
      case '허영의 시장':
        final kinds = [
          ScrollVoxelKind.tentRed,
          ScrollVoxelKind.tentBlue,
          ScrollVoxelKind.tentGreen,
        ];
        for (int dx = -2; dx <= 2; dx++) {
          final k = kinds[(dx + 2) % 3];
          add(dx.toDouble(), -3, 0, k);
          add(dx.toDouble(), -3, 1, k);
        }
        break;
      case '절망의 성':
        for (int dx = -2; dx <= 2; dx++) {
          for (int dz = 0; dz < 3; dz++) {
            add(dx.toDouble(), -3, dz.toDouble(), ScrollVoxelKind.fortress);
          }
        }
        add(-2, -3, 3, ScrollVoxelKind.fortress);
        add(2, -3, 3, ScrollVoxelKind.fortress);
        break;
      case '빛나는 산':
        for (int dx = -2; dx <= 2; dx++) {
          final h = (4 - (dx.abs())).clamp(1, 4);
          for (int z = 0; z < h; z++) {
            add(dx.toDouble(), -2.5, z.toDouble(), ScrollVoxelKind.goldPeak);
          }
        }
        break;
      case '매혹의 땅':
        for (int dx = -3; dx <= 3; dx++) {
          add(dx.toDouble(), -2, 0, ScrollVoxelKind.meadow);
          if (dx % 2 == 0) {
            add(dx.toDouble(), -2, 1, ScrollVoxelKind.meadow);
          }
        }
        break;
      case '요단강':
        for (int dx = -2; dx <= 2; dx++) {
          for (int dy = -1; dy <= 1; dy++) {
            add(dx.toDouble(), dy.toDouble(), -0.2, ScrollVoxelKind.water);
          }
        }
        break;
      case '천성':
        for (int dx = -1; dx <= 5; dx++) {
          for (int dz = 0; dz < 4; dz++) {
            add(dx.toDouble(), -3.5, dz.toDouble(), ScrollVoxelKind.cityWall);
          }
        }
        for (int tx = 0; tx <= 4; tx += 2) {
          for (int dz = 4; dz < 7; dz++) {
            add(tx.toDouble(), -3.5, dz.toDouble(), ScrollVoxelKind.cityTower);
          }
        }
        add(1, -3.5, 0, ScrollVoxelKind.cityGate);
        add(3, -3.5, 0, ScrollVoxelKind.cityGate);
        break;
    }
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class PilgrimDScrollPainter extends CustomPainter {
  final double glowAnimation;
  final double introAnimation;

  PilgrimDScrollPainter({
    required this.glowAnimation,
    required this.introAnimation,
  });

  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;
  static const double _blockSize = 10.0;

  Offset _project(double x, double y, double z, Offset origin) {
    return Offset(
      origin.dx + (x - y) * _cos30 * _blockSize,
      origin.dy + (x + y) * _sin30 * _blockSize - z * _blockSize,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawScrollBorders(canvas, size);

    final origin = Offset(60, size.height * 0.55);
    final scene = ScrollScene.instance;
    final reveal = introAnimation * scene.maxOrder;

    final sorted = [...scene.voxels]
      ..sort((a, b) => ((a.x + a.y) - (b.x + b.y)).compareTo(0) == 0
          ? a.z.compareTo(b.z)
          : ((a.x + a.y).compareTo(b.x + b.y)));

    for (final v in sorted) {
      if (v.order > reveal) continue;
      _drawVoxel(canvas, v, origin);
    }

    _drawCityHalo(canvas, origin, scene);
    _drawStageLabels(canvas, origin, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF0A0A1A),
            Color(0xFF14142A),
            Color(0xFF2B1E28),
            Color(0xFF4A3828),
          ],
          stops: [0, 0.4, 0.75, 1],
        ).createShader(rect),
    );
  }

  void _drawScrollBorders(Canvas canvas, Size size) {
    final borderPaint = Paint()..color = const Color(0xFF3B2E22);
    const h = 18.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, h), borderPaint);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - h, size.width, h),
      borderPaint,
    );

    final vinePaint = Paint()
      ..color = const Color(0xFFD4A843)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()..moveTo(0, h * 0.5);
    for (double x = 0; x < size.width; x += 20) {
      path.quadraticBezierTo(
          x + 10, h * 0.5 + 6, x + 20, h * 0.5);
    }
    canvas.drawPath(path, vinePaint);
    final path2 = Path()..moveTo(0, size.height - h * 0.5);
    for (double x = 0; x < size.width; x += 20) {
      path2.quadraticBezierTo(
          x + 10, size.height - h * 0.5 - 6, x + 20, size.height - h * 0.5);
    }
    canvas.drawPath(path2, vinePaint);

    final dot = Paint()..color = const Color(0xFFD4A843);
    for (double x = 10; x < size.width; x += 40) {
      canvas.drawCircle(Offset(x, h * 0.5), 1.8, dot);
      canvas.drawCircle(Offset(x, size.height - h * 0.5), 1.8, dot);
    }
  }

  void _drawCityHalo(Canvas canvas, Offset origin, ScrollScene scene) {
    final last = ScrollScene.stages.last;
    final p = _project(last.centerX + 2, -3, 4, origin);
    final pulse = 0.55 + 0.45 * sin(glowAnimation * 2 * pi);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(212, 168, 67, 0.35 * pulse),
          const Color(0x00D4A843),
        ],
      ).createShader(Rect.fromCircle(center: p, radius: 140));
    canvas.drawCircle(p, 140, paint);
  }

  void _drawStageLabels(Canvas canvas, Offset origin, Size size) {
    for (final s in ScrollScene.stages) {
      final anchor = _project(s.centerX, ScrollScene._pathY(s.centerX), 0, origin);
      final y = (anchor.dy + 28).clamp(size.height - 40, size.height - 22);
      final tp = TextPainter(
        text: TextSpan(
          text: s.label,
          style: const TextStyle(
            color: Color(0xFFE0D8C5),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(anchor.dx - tp.width / 2, y));
    }
  }

  void _drawVoxel(Canvas canvas, ScrollVoxel v, Offset origin) {
    final bs = _blockSize;
    final center = _project(v.x, v.y, v.z + 0.5, origin);
    final base = _colorFor(v);
    final (t, l, r) = _shade(base);

    final topPath = Path()
      ..moveTo(center.dx, center.dy - bs * 0.5)
      ..lineTo(center.dx + _cos30 * bs * 0.5, center.dy - _sin30 * bs * 0.5)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx - _cos30 * bs * 0.5, center.dy - _sin30 * bs * 0.5)
      ..close();
    canvas.drawPath(topPath, Paint()..color = t);

    final leftPath = Path()
      ..moveTo(center.dx - _cos30 * bs * 0.5, center.dy - _sin30 * bs * 0.5)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx, center.dy + bs)
      ..lineTo(center.dx - _cos30 * bs * 0.5, center.dy + bs - _sin30 * bs * 0.5)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = l);

    final rightPath = Path()
      ..moveTo(center.dx + _cos30 * bs * 0.5, center.dy - _sin30 * bs * 0.5)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx, center.dy + bs)
      ..lineTo(center.dx + _cos30 * bs * 0.5, center.dy + bs - _sin30 * bs * 0.5)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = r);
  }

  (Color, Color, Color) _shade(Color base) {
    Color dim(Color c, double f) => Color.fromARGB(
          c.a.round(),
          (c.r * 255 * f).clamp(0, 255).round(),
          (c.g * 255 * f).clamp(0, 255).round(),
          (c.b * 255 * f).clamp(0, 255).round(),
        );
    return (base, dim(base, 0.72), dim(base, 0.55));
  }

  Color _colorFor(ScrollVoxel v) {
    switch (v.kind) {
      case ScrollVoxelKind.pathStone:
        return const Color(0xFFC47B5A);
      case ScrollVoxelKind.ruin:
        return const Color(0xFF3A2418);
      case ScrollVoxelKind.gate:
        return const Color(0xFFD4A843);
      case ScrollVoxelKind.stoneCottage:
        return const Color(0xFF8B7355);
      case ScrollVoxelKind.candle:
        final pulse = 0.7 + 0.3 * sin(glowAnimation * 4 * pi);
        return Color.fromRGBO(255, 210, 120, pulse);
      case ScrollVoxelKind.cross:
        return const Color(0xFFE4B95C);
      case ScrollVoxelKind.tomb:
        return const Color(0xFF5B5048);
      case ScrollVoxelKind.hill:
        return const Color(0xFF7A5A3E);
      case ScrollVoxelKind.palace:
        return const Color(0xFFF0E4CD);
      case ScrollVoxelKind.valleyFloor:
        return const Color(0xFF3D3224);
      case ScrollVoxelKind.cliff:
        return const Color(0xFF1A1820);
      case ScrollVoxelKind.tentRed:
        return const Color(0xFFB8523A);
      case ScrollVoxelKind.tentBlue:
        return const Color(0xFF4A6780);
      case ScrollVoxelKind.tentGreen:
        return const Color(0xFF5B7A4A);
      case ScrollVoxelKind.fortress:
        return const Color(0xFF2B2638);
      case ScrollVoxelKind.goldPeak:
        return const Color(0xFFE4B95C);
      case ScrollVoxelKind.meadow:
        return const Color(0xFF6A8A5A);
      case ScrollVoxelKind.water:
        final pulse = 0.8 + 0.2 * sin(glowAnimation * 2 * pi);
        return Color.fromRGBO(82, 120, 168, pulse);
      case ScrollVoxelKind.cityWall:
        return const Color(0xFFD4A843);
      case ScrollVoxelKind.cityTower:
        final pulse = 0.8 + 0.2 * sin(glowAnimation * 2 * pi);
        return Color.fromRGBO(255, 230, 150, pulse);
      case ScrollVoxelKind.cityGate:
        return const Color(0xFFF5E6C0);
    }
  }

  @override
  bool shouldRepaint(covariant PilgrimDScrollPainter old) =>
      old.glowAnimation != glowAnimation ||
      old.introAnimation != introAnimation;
}
