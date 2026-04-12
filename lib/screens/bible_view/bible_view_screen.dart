import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bible_data.dart';
import '../../painters/isometric_bible_painter.dart';
import '../../providers/progress_provider.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';

class BibleViewScreen extends ConsumerStatefulWidget {
  const BibleViewScreen({super.key});

  @override
  ConsumerState<BibleViewScreen> createState() => _BibleViewScreenState();
}

class _BibleViewScreenState extends ConsumerState<BibleViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _checkCompletion(Map<int, Set<int>> data) {
    final isComplete =
        ProgressService.totalRead(data) >= BibleData.totalChapters;
    if (isComplete && !_glowController.isAnimating) {
      _glowController.repeat();
    } else if (!isComplete && _glowController.isAnimating) {
      _glowController.stop();
      _glowController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(progressProvider);
    final totalRead = ref.watch(totalReadProvider);
    final overallProgress = ref.watch(overallProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Stack(
          children: [
            // 3D 뷰
            progressAsync.when(
              data: (data) {
                _checkCompletion(data);
                return AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, _) {
                    return InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: SizedBox.expand(
                        child: CustomPaint(
                          painter: IsometricBiblePainter(
                            progressData: data,
                            glowAnimation: _glowController.value,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
              error: (e, _) => Center(
                child: Text('오류: $e',
                    style: const TextStyle(color: Colors.white)),
              ),
            ),

            // 상단 진행률 오버레이
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  const Text(
                    '내 성경',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalRead / ${BibleData.totalChapters}  (${(overallProgress * 100).toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 하단 힌트
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '핀치로 확대 · 드래그로 이동',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
