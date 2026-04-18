import 'package:flutter/material.dart';

import '../painters/pilgrim_d_scroll_painter.dart';

class PilgrimPreviewDScreen extends StatefulWidget {
  const PilgrimPreviewDScreen({super.key});

  @override
  State<PilgrimPreviewDScreen> createState() => _PilgrimPreviewDScreenState();
}

class _PilgrimPreviewDScreenState extends State<PilgrimPreviewDScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final AnimationController _introCtrl;
  final ScrollController _scrollCtrl = ScrollController();

  static const double _canvasWidth = 2100;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..forward();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _introCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _replayIntro() {
    _introCtrl.reset();
    _introCtrl.forward();
    _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _jumpToStage(int index) {
    final stage = ScrollScene.stages[index];
    final targetX =
        (stage.centerX / ScrollScene.totalLength) * _canvasWidth - 200;
    _scrollCtrl.animateTo(
      targetX.clamp(0, _canvasWidth - MediaQuery.of(context).size.width),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge([_glowCtrl, _introCtrl]),
                builder: (context, _) {
                  return SingleChildScrollView(
                    controller: _scrollCtrl,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: _canvasWidth,
                      height: double.infinity,
                      child: CustomPaint(
                        painter: PilgrimDScrollPainter(
                          glowAnimation: _glowCtrl.value,
                          introAnimation:
                              Curves.easeOutCubic.transform(_introCtrl.value),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildStageChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFD4A843),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '천로역정 · Journey Scroll',
              style: TextStyle(
                color: Color(0xFFF5E6C0),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _replayIntro,
            icon: const Icon(Icons.replay, size: 16, color: Color(0xFFC47B5A)),
            label: const Text(
              '인트로',
              style: TextStyle(color: Color(0xFFC47B5A), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageChips() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: ScrollScene.stages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final s = ScrollScene.stages[i];
          return ActionChip(
            label: Text(s.label),
            labelStyle: const TextStyle(
              color: Color(0xFFC47B5A),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: const Color(0xFF1A1528),
            side: const BorderSide(color: Color(0xFF3A2E38)),
            onPressed: () => _jumpToStage(i),
          );
        },
      ),
    );
  }
}
