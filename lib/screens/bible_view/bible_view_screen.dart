import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/bible_data.dart';
import '../../models/bible_model.dart';
import '../../painters/block_hit_test.dart';
import '../../painters/isometric_bible_painter.dart';
import '../../painters/noahs_ark_hit_test.dart';
import '../../painters/noahs_ark_painter.dart';
import '../../painters/pilgrim_c3_pro_painter.dart';
import '../../painters/solomons_temple_hit_test.dart';
import '../../painters/solomons_temple_painter.dart' show SolomonsTemplePainter, templeVoxels;
import '../../providers/auth_provider.dart';
import '../../providers/model_provider.dart';
import '../../providers/progress_provider.dart';
import '../../services/progress_service.dart';
import '../../services/share_service.dart';
import '../../services/share_service_web.dart'
    if (dart.library.io) '../../services/share_service_stub.dart' as platform;
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

  BlockCoord? _hitTest(Offset scenePos) {
    return switch (ref.read(modelProvider)) {
      BibleModelType.book => _hitTest(scenePos),
      BibleModelType.noahsArk => NoahsArkHitTest.hitTest(scenePos, _canvasSize, _rotationAngle),
      BibleModelType.solomonsTemple => SolomonsTempleHitTest.hitTest(scenePos, _canvasSize, _rotationAngle),
      BibleModelType.pilgrimMountain => null,
    };
  }

  int _toBlockIndex(BlockCoord coord) {
    return switch (ref.read(modelProvider)) {
      BibleModelType.book => BlockHitTest.toBlockIndex(coord),
      BibleModelType.noahsArk => NoahsArkHitTest.toBlockIndex(coord),
      BibleModelType.solomonsTemple => SolomonsTempleHitTest.toBlockIndex(coord),
      BibleModelType.pilgrimMountain => -1,
    };
  }

  String _tooltipText(int blockIndex) {
    return switch (ref.read(modelProvider)) {
      BibleModelType.book => BlockHitTest.tooltipText(blockIndex, _latestProgressData),
      BibleModelType.noahsArk => NoahsArkHitTest.tooltipText(blockIndex, _latestProgressData),
      BibleModelType.solomonsTemple => SolomonsTempleHitTest.tooltipText(blockIndex, _latestProgressData),
      BibleModelType.pilgrimMountain => '',
    };
  }

  Offset _blockTopCenter(BlockCoord coord) {
    return switch (ref.read(modelProvider)) {
      BibleModelType.book => BlockHitTest.blockTopCenter(coord, _canvasSize, _rotationAngle),
      BibleModelType.noahsArk => NoahsArkHitTest.blockTopCenter(coord, _canvasSize, _rotationAngle),
      BibleModelType.solomonsTemple => SolomonsTempleHitTest.blockTopCenter(coord, _canvasSize, _rotationAngle),
      BibleModelType.pilgrimMountain => Offset.zero,
    };
  }

  CustomPainter _buildPainter(BibleModelType modelType, Map<int, Set<int>> data) {
    return switch (modelType) {
      BibleModelType.book => IsometricBiblePainter(
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
      BibleModelType.noahsArk => NoahsArkPainter(
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
      BibleModelType.solomonsTemple => SolomonsTemplePainter(
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
      BibleModelType.pilgrimMountain =>
        throw StateError('pilgrimMountain uses its own two-layer render tree'),
    };
  }

  Widget _buildPilgrimScene(Map<int, Set<int>> data) {
    final readChapters = ProgressService.totalRead(data);
    final intro = Curves.easeOutCubic.transform(_introController.value);
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: PilgrimC3ProStaticPainter(
              readChapters: readChapters,
              introAnimation: intro,
            ),
          ),
        ),
        CustomPaint(
          painter: PilgrimC3ProOverlayPainter(
            glowAnimation: _glowController.value,
            readChapters: readChapters,
          ),
        ),
      ],
    );
  }

  void _onPointerHover(PointerHoverEvent event) {
    if (_introController.isAnimating) return;
    if (_canvasSize == Size.zero) return;
    final scenePos = _transformController.toScene(event.localPosition);
    final hit = _hitTest(scenePos);
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
      final hit = _hitTest(scenePos);
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

  Future<void> _shareProgress() async {
    final progressData = ref.read(progressProvider).value ?? {};
    final user = ref.read(authProvider).value;
    final isGuest = ref.read(isGuestProvider).value ?? false;
    final nickname = isGuest ? '게스트' : (user?.nickname ?? '사용자');

    final totalRead = ProgressService.totalRead(progressData);
    final percent = (totalRead / BibleData.totalChapters * 100).round();

    try {
      if (kIsWeb) {
        platform.shareViaKakao(
          nickname: nickname,
          percent: percent,
          totalRead: totalRead,
          totalChapters: BibleData.totalChapters,
          imageUrl: 'https://bible-blocks-omega.vercel.app/share_card.png?v=5',
          webUrl: 'https://bible-blocks-omega.vercel.app',
        );
      } else {
        await ShareService.shareProgress(
          progressData: progressData,
          nickname: nickname,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공유 실패: $e')),
        );
      }
    }
  }

  Widget _buildTooltip() {
    final blockIndex = _toBlockIndex(_hoveredBlock!);
    final text = _tooltipText(blockIndex);
    if (text.isEmpty) return const SizedBox.shrink();

    final canvasPos = _blockTopCenter(_hoveredBlock!);
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
    final modelType = ref.watch(modelProvider);

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
                if (_previousProgressData.isNotEmpty &&
                    data != _previousProgressData &&
                    modelType != BibleModelType.pilgrimMountain) {
                  final newBlocks = <int>{};
                  final totalBlocks = switch (modelType) {
                    BibleModelType.book => IsometricBiblePainter.totalPageBlocks,
                    BibleModelType.noahsArk => ArkVoxels.structuralCount,
                    BibleModelType.solomonsTemple => templeVoxels.length,
                    BibleModelType.pilgrimMountain => 0,
                  };
                  for (int i = 0; i < totalBlocks; i++) {
                    final range = switch (modelType) {
                      BibleModelType.book => BlockHitTest.blockChapterRange(i),
                      BibleModelType.noahsArk => NoahsArkHitTest.blockChapterRange(i),
                      BibleModelType.solomonsTemple => SolomonsTempleHitTest.blockChapterRange(i),
                      BibleModelType.pilgrimMountain => (globalStart: 0, globalEnd: 0),
                    };
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
                                child: modelType == BibleModelType.pilgrimMountain
                                    ? _buildPilgrimScene(data)
                                    : CustomPaint(
                                        painter: _buildPainter(modelType, data),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _shareProgress(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.share,
                            color: AppColors.gold,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go('/settings'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white70,
                        size: 20,
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
