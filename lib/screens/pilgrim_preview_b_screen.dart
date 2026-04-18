import 'package:flutter/material.dart';

import '../painters/pilgrim_b_maze_painter.dart';

/// Standalone preview screen for the Pilgrim's Progress isometric maze.
///
/// Lets the reviewer scrub the "chapters read" slider to see the path light up
/// from the City of Destruction to the Celestial City. Includes a subtle
/// ambient glow loop and a one-shot intro sweep on first build.
class PilgrimPreviewBScreen extends StatefulWidget {
  const PilgrimPreviewBScreen({super.key});

  @override
  State<PilgrimPreviewBScreen> createState() => _PilgrimPreviewBScreenState();
}

class _PilgrimPreviewBScreenState extends State<PilgrimPreviewBScreen>
    with TickerProviderStateMixin {
  static const int _totalChapters = 1189;

  late final AnimationController _glowCtrl;
  late final AnimationController _introCtrl;

  // Scrubbable progress — starts at ~halfway so the path reads as partially lit.
  double _readChapters = 420;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _introCtrl.dispose();
    super.dispose();
  }

  void _replayIntro() {
    _introCtrl.reset();
    _introCtrl.forward();
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
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: CustomPaint(
                            painter: PilgrimBMazePainter(
                              readChapters: _readChapters.round(),
                              glowAnimation: _glowCtrl.value,
                              introAnimation:
                                  Curves.easeOutCubic.transform(_introCtrl.value),
                              totalChapters: _totalChapters,
                            ),
                            child: SizedBox.expand(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _buildControls(),
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
          const Text(
            '천로역정 · Isometric Labyrinth',
            style: TextStyle(
              color: Color(0xFFF5E6C0),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _replayIntro,
            icon: const Icon(Icons.replay, size: 16, color: Color(0xFFC47B5A)),
            label: const Text(
              '인트로 재생',
              style: TextStyle(
                color: Color(0xFFC47B5A),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final read = _readChapters.round();
    final pct = (_readChapters / _totalChapters * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x000A0A1A), Color(0xFF0A0A1A)],
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '읽은 장  $read / $_totalChapters',
                  style: const TextStyle(
                    color: Color(0xFFE0D8C5),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$pct %',
                  style: const TextStyle(
                    color: Color(0xFFD4A843),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFC47B5A),
                inactiveTrackColor: const Color(0xFF2A2438),
                thumbColor: const Color(0xFFD4A843),
                overlayColor: const Color(0x33D4A843),
                trackHeight: 3,
              ),
              child: Slider(
                value: _readChapters,
                min: 0,
                max: _totalChapters.toDouble(),
                onChanged: (v) => setState(() => _readChapters = v),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PresetButton(
                  label: '출발',
                  onTap: () => setState(() => _readChapters = 0),
                ),
                _PresetButton(
                  label: '좁은 문',
                  onTap: () => setState(() => _readChapters = 200),
                ),
                _PresetButton(
                  label: '중간',
                  onTap: () => setState(() => _readChapters = 594),
                ),
                _PresetButton(
                  label: '허영의 시장',
                  onTap: () => setState(() => _readChapters = 950),
                ),
                _PresetButton(
                  label: '천성',
                  onTap: () => setState(() => _readChapters = _totalChapters.toDouble()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFC47B5A),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 30),
      ),
      child: Text(label),
    );
  }
}
