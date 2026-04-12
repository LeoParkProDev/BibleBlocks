import 'dart:math';
import 'package:flutter/material.dart';

import '../data/bible_data.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import 'block_hit_test.dart';

class IsometricBiblePainter extends CustomPainter {
  final Map<int, Set<int>> progressData;
  final double glowAnimation;
  final BlockCoord? hoveredBlock;
  final BlockCoord? pressedBlock;
  final double bounceAnimation;
  final Offset? cursorScenePos;
  final double rotationAngle;
  final Set<int> newlyFilledBlocks;
  final double fillAnimation;
  final double introAnimation; // 0.0 ~ 1.0

  IsometricBiblePainter({
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

  // 책 구조 상수
  static const int bookWidth = 8;
  static const int bookHeight = 12;
  static const int bookDepth = 2;
  static const int totalPageBlocks = bookWidth * bookHeight * bookDepth;

  // 아이소메트릭 투영 상수
  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;
  static const double blockSize = 14.0;

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

  /// 블록 내 모든 장이 읽혔는지 확인
  bool _isBlockFullyRead(int blockIndex) {
    final globalStart =
        (blockIndex * BibleData.totalChapters / totalPageBlocks).floor();
    final globalEnd =
        ((blockIndex + 1) * BibleData.totalChapters / totalPageBlocks).floor();
    if (globalEnd <= globalStart) return false;
    for (int g = globalStart; g < globalEnd; g++) {
      if (!ProgressService.isGlobalIndexRead(progressData, g)) return false;
    }
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.65);
    if (isComplete && glowAnimation > 0) _drawCompletionGlow(canvas, size, origin);

    final normAngle = rotationAngle % (2 * pi);
    final absAngle = normAngle < 0 ? normAngle + 2 * pi : normAngle;
    final frontFirst = absAngle > pi / 2 && absAngle < 3 * pi / 2;

    if (frontFirst) {
      _drawFrontCover(canvas, origin);
      _drawPageBlocks(canvas, origin);
      _drawBackCover(canvas, origin);
    } else {
      _drawBackCover(canvas, origin);
      _drawPageBlocks(canvas, origin);
      _drawFrontCover(canvas, origin);
    }
    _drawSpine(canvas, origin);

    if (isComplete && glowAnimation > 0) _drawParticles(canvas, size, origin);
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

  void _drawPageBlocks(Canvas canvas, Offset origin) {
    final normAngle = rotationAngle % (2 * pi);
    final absAngle = normAngle < 0 ? normAngle + 2 * pi : normAngle;

    // Y direction: back-to-front vs front-to-back
    final yReverse = absAngle > pi / 2 && absAngle < 3 * pi / 2;
    // X direction: left-to-right vs right-to-left
    final xReverse = absAngle > pi && absAngle < 2 * pi;

    final yStart = yReverse ? 0 : bookDepth - 1;
    final yEnd = yReverse ? bookDepth : -1;
    final yStep = yReverse ? 1 : -1;

    final xStart = xReverse ? 0 : bookWidth - 1;
    final xEnd = xReverse ? bookWidth : -1;
    final xStep = xReverse ? 1 : -1;

    for (int y = yStart; y != yEnd; y += yStep) {
      for (int z = bookHeight - 1; z >= 0; z--) {
        for (int x = xStart; x != xEnd; x += xStep) {
          final blockIndex = y * (bookWidth * bookHeight) + z * bookWidth + x;
          final globalStart =
              (blockIndex * BibleData.totalChapters / totalPageBlocks).floor();
          final globalEnd =
              ((blockIndex + 1) * BibleData.totalChapters / totalPageBlocks)
                  .floor();

          int readCount = 0;
          int totalCount = max(1, globalEnd - globalStart);
          for (int g = globalStart; g < globalEnd; g++) {
            if (ProgressService.isGlobalIndexRead(progressData, g)) {
              readCount++;
            }
          }

          final fillRatio = readCount / totalCount;

          // Intro animation: blocks appear bottom-to-top, back-to-front
          double introOpacity = 1.0;
          double introZOffset = 0.0;
          if (introAnimation < 1.0) {
            final order = (bookHeight - 1 - z) * bookDepth + (bookDepth - 1 - y);
            final maxOrder = bookHeight * bookDepth;
            final blockDelay = order / maxOrder * 0.6;
            final localT = ((introAnimation - blockDelay) / 0.4).clamp(0.0, 1.0);
            introOpacity = localT;
            introZOffset = (1.0 - localT) * 3.0;
          }
          if (introOpacity <= 0) continue;

          // z-offset: proximity float + bounce
          double zOffset = _proximityZOffset(
              x.toDouble(), y.toDouble(), z.toDouble(), origin);
          final isPressed = pressedBlock != null &&
              pressedBlock!.x == x &&
              pressedBlock!.y == y &&
              pressedBlock!.z == z;
          if (isPressed) zOffset += _bounceZOffset;
          final effectiveZ = z.toDouble() + zOffset;

          // Fill animation for newly filled blocks
          final isNewlyFilled = newlyFilledBlocks.contains(blockIndex);
          double animOpacity = 1.0;
          double extraZOffset = 0.0;
          if (isNewlyFilled && fillAnimation < 1.0) {
            final blockDelay = (blockIndex % 20) * 0.05;
            final localT = ((fillAnimation - blockDelay) / (1.0 - blockDelay)).clamp(0.0, 1.0);
            extraZOffset = (1.0 - localT) * 2.0;
            animOpacity = localT;
          }

          if (fillRatio >= 1.0) {
            _drawCube(canvas, origin, x.toDouble(), y.toDouble(),
                effectiveZ + extraZOffset + introZOffset,
                AppColors.pageIvory.withValues(alpha: animOpacity * introOpacity),
                AppColors.pageIvoryDark.withValues(alpha: animOpacity * introOpacity));
          } else if (readCount > 0) {
            final baseAlpha = 0.15 + fillRatio * 0.35;
            _drawCube(
              canvas,
              origin,
              x.toDouble(),
              y.toDouble(),
              effectiveZ + extraZOffset + introZOffset,
              AppColors.pageIvory.withValues(alpha: baseAlpha * animOpacity * introOpacity),
              AppColors.pageIvoryDark.withValues(alpha: baseAlpha * animOpacity * introOpacity),
            );
          } else {
            // Skip wireframes during intro (they appear when intro completes)
            if (introAnimation >= 1.0) {
              _drawWireframeCube(
                  canvas, origin, x.toDouble(), y.toDouble(), effectiveZ);
            }
          }

          // Highlight hovered block
          final isHovered = hoveredBlock != null &&
              hoveredBlock!.x == x &&
              hoveredBlock!.y == y &&
              hoveredBlock!.z == z;
          if (isHovered) {
            _drawBlockHighlight(
                canvas, origin, x.toDouble(), y.toDouble(), effectiveZ);
          }
        }
      }
    }
  }

  void _drawFrontCover(Canvas canvas, Offset origin) {
    if (introAnimation < 0.3) return;
    for (int z = bookHeight - 1; z >= 0; z--) {
      for (int x = 0; x < bookWidth; x++) {
        final blockIndex = 0 * (bookWidth * bookHeight) + z * bookWidth + x;
        final adjacentFilled = _isBlockFullyRead(blockIndex);

        if (adjacentFilled) {
          final isCross = isCrossPosition(x, z);
          final topColor =
              isCross ? AppColors.gold : AppColors.coverBrown;
          final sideColor = isCross
              ? AppColors.gold.withValues(alpha: 0.8)
              : AppColors.coverDark;

          _drawCube(canvas, origin, x.toDouble(), -1.0, z.toDouble(), topColor,
              sideColor);

          if (isCross && isComplete && glowAnimation > 0) {
            final center = project(x + 0.5, -0.5, z + 0.5, origin);
            final glowPaint = Paint()
              ..color = AppColors.gold.withValues(alpha: 0.3 * glowAnimation)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
            canvas.drawCircle(center, blockSize * 1.2, glowPaint);
          }
        } else {
          _drawWireframeCube(
              canvas, origin, x.toDouble(), -1.0, z.toDouble());
        }
      }
    }
  }

  void _drawBackCover(Canvas canvas, Offset origin) {
    if (introAnimation < 0.3) return;
    final backY = bookDepth.toDouble();
    for (int z = bookHeight - 1; z >= 0; z--) {
      for (int x = 0; x < bookWidth; x++) {
        final blockIndex =
            (bookDepth - 1) * (bookWidth * bookHeight) + z * bookWidth + x;
        final adjacentFilled = _isBlockFullyRead(blockIndex);

        if (adjacentFilled) {
          _drawCube(canvas, origin, x.toDouble(), backY, z.toDouble(),
              AppColors.coverBrown, AppColors.coverDark);
        } else {
          _drawWireframeCube(
              canvas, origin, x.toDouble(), backY, z.toDouble());
        }
      }
    }
  }

  void _drawSpine(Canvas canvas, Offset origin) {
    if (introAnimation < 0.3) return;
    for (int y = bookDepth; y >= -1; y--) {
      for (int z = bookHeight - 1; z >= 0; z--) {
        bool adjacentFilled = false;
        if (y >= 0 && y < bookDepth) {
          final blockIndex = y * (bookWidth * bookHeight) + z * bookWidth + 0;
          adjacentFilled = _isBlockFullyRead(blockIndex);
        } else {
          final checkY = y == -1 ? 0 : bookDepth - 1;
          final blockIndex =
              checkY * (bookWidth * bookHeight) + z * bookWidth + 0;
          adjacentFilled = _isBlockFullyRead(blockIndex);
        }

        if (adjacentFilled) {
          _drawCube(canvas, origin, -1.0, y.toDouble(), z.toDouble(),
              AppColors.spineBrown, AppColors.spineBrown.withValues(alpha: 0.8));
        } else {
          _drawWireframeCube(
              canvas, origin, -1.0, y.toDouble(), z.toDouble());
        }
      }
    }
  }

  static bool isCrossPosition(int x, int z) {
    const cx = 3;
    const cx2 = 4;
    const cz = 5;
    if ((x == cx || x == cx2) && z >= 2 && z <= 9) return true;
    if ((z == cz || z == cz + 1) && x >= 1 && x <= 6) return true;
    return false;
  }

  void _drawCube(Canvas canvas, Offset origin, double x, double y, double z,
      Color topColor, Color sideColor) {
    final p1 = project(x + 1, y, z, origin);
    final p2 = project(x + 1, y + 1, z, origin);
    final p3 = project(x, y + 1, z, origin);
    final p4 = project(x, y, z + 1, origin);
    final p5 = project(x + 1, y, z + 1, origin);
    final p6 = project(x + 1, y + 1, z + 1, origin);
    final p7 = project(x, y + 1, z + 1, origin);

    // 윗면 (z+1)
    final topPath = Path()
      ..moveTo(p4.dx, p4.dy)
      ..lineTo(p5.dx, p5.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p7.dx, p7.dy)
      ..close();
    canvas.drawPath(
      topPath,
      Paint()..color = topColor,
    );
    canvas.drawPath(
      topPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // 왼쪽면
    final leftPath = Path()
      ..moveTo(p3.dx, p3.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p7.dx, p7.dy)
      ..close();
    canvas.drawPath(
      leftPath,
      Paint()..color = sideColor,
    );
    canvas.drawPath(
      leftPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // 오른쪽면
    final rightPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p5.dx, p5.dy)
      ..close();
    canvas.drawPath(
      rightPath,
      Paint()
        ..color = Color.lerp(sideColor, Colors.black, 0.15)!,
    );
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
  bool shouldRepaint(covariant IsometricBiblePainter oldDelegate) {
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
