import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bible_data.dart';
import '../../painters/block_hit_test.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _bounceController;
  late AnimationController _rotationController;
  late AnimationController _fillController;
  late AnimationController _introController;
  bool _introPlayed = false;
  double _rotationAngle = 0.0;
  int _rotationDirection = 0; // -1: left, 0: stop, 1: right
  final TransformationController _transformController =
      TransformationController();

  BlockCoord? _hoveredBlock;
  BlockCoord? _pressedBlock;
  Offset? _cursorScenePos;
  Offset? _pointerDownPos;
  Map<int, Set<int>> _latestProgressData = {};
  Map<int, Set<int>> _previousProgressData = {};
  Set<int> _newlyFilledBlocks = {};
  Size _canvasSize = Size.zero;
  Timer? _tooltipTimer;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
      setState(() {
        _rotationAngle += _rotationDirection * 0.02;
      });
    });
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..value = 1.0;
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    _glowController.dispose();
    _bounceController.dispose();
    _rotationController.dispose();
    _fillController.dispose();
    _introController.dispose();
    _transformController.dispose();
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

  void _startRotation(int direction) {
    _rotationDirection = direction;
    _rotationController.repeat();
  }

  void _stopRotation() {
    _rotationDirection = 0;
    _rotationController.stop();
  }

  void _onPointerHover(PointerHoverEvent event) {
    if (_introController.isAnimating) return;
    if (_canvasSize == Size.zero) return;
    final scenePos = _transformController.toScene(event.localPosition);
    final hit = BlockHitTest.hitTest(scenePos, _canvasSize, _rotationAngle);
    setState(() {
      _hoveredBlock = hit;
      _cursorScenePos = scenePos;
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_canvasSize == Size.zero) return;
    final scenePos = _transformController.toScene(event.localPosition);
    setState(() {
      _cursorScenePos = scenePos;
    });
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerDownPos = event.localPosition;
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_introController.isAnimating) return;
    if (_pointerDownPos == null) return;
    final distance = (event.localPosition - _pointerDownPos!).distance;
    if (distance < 10 && _canvasSize != Size.zero) {
      final scenePos = _transformController.toScene(event.localPosition);
      final hit = BlockHitTest.hitTest(scenePos, _canvasSize, _rotationAngle);
      if (hit != null) {
        _handleBlockTap(hit);
      }
    }
    _pointerDownPos = null;
  }

  void _handleBlockTap(BlockCoord block) {
    setState(() {
      _pressedBlock = block;
      _hoveredBlock = block;
    });
    _bounceController.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _pressedBlock = null);
    });

    // Mobile: auto-dismiss tooltip after 2s
    _tooltipTimer?.cancel();
    _tooltipTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _hoveredBlock = null);
    });
  }

  Widget _buildTooltip() {
    final blockIndex = BlockHitTest.toBlockIndex(_hoveredBlock!);
    final text = BlockHitTest.tooltipText(blockIndex, _latestProgressData);
    if (text.isEmpty) return const SizedBox.shrink();

    final canvasPos = BlockHitTest.blockTopCenter(_hoveredBlock!, _canvasSize, _rotationAngle);
    final screenPos =
        MatrixUtils.transformPoint(_transformController.value, canvasPos);

    return Positioned(
      left: screenPos.dx,
      top: screenPos.dy - 8,
      child: IgnorePointer(
        child: FractionalTranslation(
          translation: const Offset(-0.5, -1.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.gold, width: 0.5),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
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
          clipBehavior: Clip.none,
          children: [
            // 3D 뷰
            progressAsync.when(
              data: (data) {
                if (!_introPlayed) {
                  _introPlayed = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _introController.forward(from: 0.0);
                  });
                }
                if (_previousProgressData.isNotEmpty && data != _previousProgressData) {
                  final newBlocks = <int>{};
                  for (int i = 0; i < IsometricBiblePainter.totalPageBlocks; i++) {
                    final range = BlockHitTest.blockChapterRange(i);
                    bool wasFullBefore = true;
                    bool isFullNow = true;
                    for (int g = range.globalStart; g < range.globalEnd; g++) {
                      if (!ProgressService.isGlobalIndexRead(_previousProgressData, g)) wasFullBefore = false;
                      if (!ProgressService.isGlobalIndexRead(data, g)) isFullNow = false;
                    }
                    if (!wasFullBefore && isFullNow) newBlocks.add(i);
                  }
                  if (newBlocks.isNotEmpty) {
                    _newlyFilledBlocks = newBlocks;
                    _fillController.forward(from: 0.0);
                  }
                }
                _previousProgressData = Map.of(data);
                _latestProgressData = data;
                _checkCompletion(data);
                return MouseRegion(
                  onExit: (_) => setState(() {
                    _hoveredBlock = null;
                    _cursorScenePos = null;
                  }),
                  child: Listener(
                    onPointerHover: _onPointerHover,
                    onPointerMove: _onPointerMove,
                    onPointerDown: _onPointerDown,
                    onPointerUp: _onPointerUp,
                    child: AnimatedBuilder(
                      animation: Listenable.merge(
                          [_glowController, _bounceController, _rotationController, _fillController, _introController]),
                      builder: (context, _) {
                        return InteractiveViewer(
                          transformationController: _transformController,
                          minScale: 0.5,
                          maxScale: 3.0,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              _canvasSize = Size(
                                  constraints.maxWidth, constraints.maxHeight);
                              return SizedBox.expand(
                                child: CustomPaint(
                                  painter: IsometricBiblePainter(
                                    progressData: data,
                                    glowAnimation: _glowController.value,
                                    hoveredBlock: _hoveredBlock,
                                    pressedBlock: _pressedBlock,
                                    bounceAnimation: _bounceController.value,
                                    cursorScenePos: _cursorScenePos,
                                    rotationAngle: _rotationAngle,
                                    newlyFilledBlocks: _newlyFilledBlocks,
                                    fillAnimation: _fillController.value,
                                    introAnimation: _introController.value,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
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

            // 툴팁
            if (_hoveredBlock != null && _canvasSize != Size.zero)
              _buildTooltip(),

            // 하단 회전 버튼 + 힌트
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onLongPressStart: (_) => _startRotation(-1),
                    onLongPressEnd: (_) => _stopRotation(),
                    onTapDown: (_) => _startRotation(-1),
                    onTapUp: (_) => _stopRotation(),
                    onTapCancel: _stopRotation,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.rotate_left, color: Colors.white54, size: 24),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    '핀치로 확대 · 드래그로 이동',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onLongPressStart: (_) => _startRotation(1),
                    onLongPressEnd: (_) => _stopRotation(),
                    onTapDown: (_) => _startRotation(1),
                    onTapUp: (_) => _stopRotation(),
                    onTapCancel: _stopRotation,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.rotate_right, color: Colors.white54, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
