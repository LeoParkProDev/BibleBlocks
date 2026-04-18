import 'dart:math';
import 'package:flutter/material.dart';

import '../painters/pilgrim_a_tower_painter.dart';

class PilgrimPreviewAScreen extends StatefulWidget {
  const PilgrimPreviewAScreen({super.key});

  @override
  State<PilgrimPreviewAScreen> createState() => _PilgrimPreviewAScreenState();
}

class _PilgrimPreviewAScreenState extends State<PilgrimPreviewAScreen>
    with TickerProviderStateMixin {
  static const int _totalChapters = 1189;

  late final AnimationController _glowCtrl;
  late final AnimationController _introCtrl;
  late final AnimationController _rotationCtrl;

  double _readChapters = 420;
  bool _autoRotate = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _introCtrl.dispose();
    _rotationCtrl.dispose();
    super.dispose();
  }

  void _replayIntro() {
    _introCtrl.reset();
    _introCtrl.forward();
  }

  void _toggleRotate() {
    setState(() {
      _autoRotate = !_autoRotate;
      if (_autoRotate) {
        _rotationCtrl.repeat();
      } else {
        _rotationCtrl.stop();
      }
    });
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
                animation: Listenable.merge([
                  _glowCtrl,
                  _introCtrl,
                  _rotationCtrl,
                ]),
                builder: (context, _) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: CustomPaint(
                        painter: PilgrimATowerPainter(
                          glowAnimation: _glowCtrl.value,
                          introAnimation:
                              Curves.easeOutCubic.transform(_introCtrl.value),
                          rotationAngle: _rotationCtrl.value * 2 * pi,
                          readStairs: _readChapters.round(),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
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
            '천로역정 · Spiral Celestial Tower',
            style: TextStyle(
              color: Color(0xFFF5E6C0),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _toggleRotate,
            icon: Icon(
              _autoRotate ? Icons.pause_circle_outline : Icons.sync,
              size: 16,
              color: const Color(0xFFD4A843),
            ),
            label: Text(
              _autoRotate ? '회전 멈춤' : '자동 회전',
              style: const TextStyle(color: Color(0xFFD4A843), fontSize: 13),
            ),
          ),
          const SizedBox(width: 4),
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

  Widget _buildControls() {
    final read = _readChapters.round();
    final pct = (_readChapters / _totalChapters * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '올라간 계단  $read / $_totalChapters',
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
                _preset('출발', 0),
                _preset('좁은 문', 120),
                _preset('허영의 시장', 600),
                _preset('빛나는 산', 900),
                _preset('천성', _totalChapters),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _preset(String label, int value) {
    return TextButton(
      onPressed: () => setState(() => _readChapters = value.toDouble()),
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
