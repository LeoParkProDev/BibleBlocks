import 'dart:math';
import 'package:flutter/material.dart';

import '../data/bible_data.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';

class IsometricBiblePainter extends CustomPainter {
  final Map<int, Set<int>> progressData;
  final double glowAnimation; // 0.0~1.0 for completion glow

  IsometricBiblePainter({
    required this.progressData,
    this.glowAnimation = 0.0,
  });

  // 책 구조 상수
  static const int bookWidth = 8; // x 방향 (페이지 가로)
  static const int bookHeight = 12; // z 방향 (페이지 세로)
  static const int bookDepth = 2; // y 방향 (책 두께 - 페이지 레이어)
  static const int totalPageBlocks = bookWidth * bookHeight * bookDepth; // 192

  // 아이소메트릭 투영 상수
  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;
  static const double blockSize = 14.0;

  bool get isComplete =>
      ProgressService.totalRead(progressData) >= BibleData.totalChapters;

  Offset project(double x, double y, double z, Offset origin) {
    return Offset(
      origin.dx + (x - y) * _cos30 * blockSize,
      origin.dy + (x + y) * _sin30 * blockSize - z * blockSize,
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

    // 완독 시 배경 글로우
    if (isComplete && glowAnimation > 0) {
      _drawCompletionGlow(canvas, size, origin);
    }

    // 뒤에서 앞 순서로 그리기 (painter's algorithm)
    // 1) 뒷표지
    _drawBackCover(canvas, origin);
    // 2) 책등
    _drawSpine(canvas, origin);
    // 3) 페이지 블록들 (뒤→앞)
    _drawPageBlocks(canvas, origin);
    // 4) 앞표지
    _drawFrontCover(canvas, origin);

    // 완독 시 파티클
    if (isComplete && glowAnimation > 0) {
      _drawParticles(canvas, size, origin);
    }
  }

  void _drawPageBlocks(Canvas canvas, Offset origin) {
    // 뒤(y=bookDepth-1)부터 앞(y=0)으로, 위(z=bookHeight-1)부터 아래(z=0)로,
    // 왼쪽(x=0)부터 오른쪽(x=bookWidth-1)으로
    for (int y = bookDepth - 1; y >= 0; y--) {
      for (int z = bookHeight - 1; z >= 0; z--) {
        for (int x = 0; x < bookWidth; x++) {
          final blockIndex = y * (bookWidth * bookHeight) + z * bookWidth + x;
          // 1189장을 192블록에 매핑: 나눠서 여러 장이 하나의 블록에
          final globalStart =
              (blockIndex * BibleData.totalChapters / totalPageBlocks).floor();
          final globalEnd =
              ((blockIndex + 1) * BibleData.totalChapters / totalPageBlocks)
                  .floor();

          // 블록 내 읽은 비율 계산
          int readCount = 0;
          int totalCount = max(1, globalEnd - globalStart);
          for (int g = globalStart; g < globalEnd; g++) {
            if (ProgressService.isGlobalIndexRead(progressData, g)) {
              readCount++;
            }
          }

          final fillRatio = readCount / totalCount;

          if (fillRatio >= 1.0) {
            // 블록 내 모든 장 완독 → 불투명 블록
            _drawCube(canvas, origin, x.toDouble(), y.toDouble(),
                z.toDouble(), AppColors.pageIvory, AppColors.pageIvoryDark);
          } else if (readCount > 0) {
            // 부분 읽음 → 반투명 블록 (진행 중 표시)
            _drawCube(
              canvas,
              origin,
              x.toDouble(),
              y.toDouble(),
              z.toDouble(),
              AppColors.pageIvory.withValues(alpha: 0.15 + fillRatio * 0.35),
              AppColors.pageIvoryDark.withValues(alpha: 0.15 + fillRatio * 0.35),
            );
          } else {
            _drawWireframeCube(canvas, origin, x.toDouble(), y.toDouble(),
                z.toDouble());
          }
        }
      }
    }
  }

  void _drawFrontCover(Canvas canvas, Offset origin) {
    // 앞표지: y = -1 (앞)에 x × z 면
    // 표지가 물질화하려면 y=0 레이어 블록들이 채워져야 함
    for (int z = bookHeight - 1; z >= 0; z--) {
      for (int x = 0; x < bookWidth; x++) {
        // y=0 레이어의 같은 (x,z) 블록이 완전히 채워져야 표지 물질화
        final blockIndex = 0 * (bookWidth * bookHeight) + z * bookWidth + x;
        final adjacentFilled = _isBlockFullyRead(blockIndex);

        if (adjacentFilled) {
          // 십자가 위치인지 확인
          final isCross = isCrossPosition(x, z);
          final topColor =
              isCross ? AppColors.gold : AppColors.coverBrown;
          final sideColor =
              isCross ? AppColors.gold.withValues(alpha: 0.8) : AppColors.coverDark;

          _drawCube(canvas, origin, x.toDouble(), -1.0, z.toDouble(), topColor,
              sideColor);

          // 완독 시 십자가 글로우
          if (isCross && isComplete && glowAnimation > 0) {
            final center =
                project(x + 0.5, -0.5, z + 0.5, origin);
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
    // 뒷표지: y = bookDepth (뒤)
    final backY = bookDepth.toDouble();
    for (int z = bookHeight - 1; z >= 0; z--) {
      for (int x = 0; x < bookWidth; x++) {
        // y=bookDepth-1 레이어 블록이 완전히 채워져야 뒷표지 물질화
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
    // 책등: x = -1, 모든 y와 z
    for (int y = bookDepth; y >= -1; y--) {
      for (int z = bookHeight - 1; z >= 0; z--) {
        // 인접 블록이 완전히 채워져야 책등 물질화
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
    // 8x12 그리드에서 십자가 패턴 (가로 중앙, 세로 중앙)
    const cx = 3; // 중앙 x (0-indexed, 8칸이면 3~4)
    const cx2 = 4;
    const cz = 5; // 중앙 z 기준
    // 세로 바: x=3,4, z=2~9
    if ((x == cx || x == cx2) && z >= 2 && z <= 9) return true;
    // 가로 바: z=5,6, x=1~6
    if ((z == cz || z == cz + 1) && x >= 1 && x <= 6) return true;
    return false;
  }

  void _drawCube(Canvas canvas, Offset origin, double x, double y, double z,
      Color topColor, Color sideColor) {
    // 큐브의 8개 꼭짓점
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

    // 왼쪽면 (x 방향, y에서 y+1)
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

    // 오른쪽면 (y 방향, x에서 x+1)
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

    // 윗면
    final topPath = Path()
      ..moveTo(p4.dx, p4.dy)
      ..lineTo(p5.dx, p5.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p7.dx, p7.dy)
      ..close();
    canvas.drawPath(topPath, paint);

    // 왼쪽면
    final leftPath = Path()
      ..moveTo(p3.dx, p3.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p7.dx, p7.dy)
      ..close();
    canvas.drawPath(leftPath, paint);

    // 오른쪽면
    final rightPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p6.dx, p6.dy)
      ..lineTo(p5.dx, p5.dy)
      ..close();
    canvas.drawPath(rightPath, paint);
  }

  void _drawCompletionGlow(Canvas canvas, Size size, Offset origin) {
    // 중앙에서 퍼져나가는 금색 글로우
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
    final random = Random(42); // 고정 시드로 일관된 위치
    final particlePaint = Paint();

    for (int i = 0; i < 30; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final dist = 50 + random.nextDouble() * 150;
      final phase = (glowAnimation + i * 0.033) % 1.0;
      final alpha = sin(phase * pi) * 0.7;

      if (alpha > 0) {
        final px = origin.dx + cos(angle) * dist * phase;
        final py = origin.dy - 100 + sin(angle) * dist * 0.5 * phase - phase * 80;
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
        oldDelegate.glowAnimation != glowAnimation;
  }
}
