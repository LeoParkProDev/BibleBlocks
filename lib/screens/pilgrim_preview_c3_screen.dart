import 'package:flutter/material.dart';

import '../painters/pilgrim_c3_revelation_painter.dart';

class PilgrimPreviewC3Screen extends StatefulWidget {
  const PilgrimPreviewC3Screen({super.key});

  @override
  State<PilgrimPreviewC3Screen> createState() => _PilgrimPreviewC3ScreenState();
}

class _PilgrimPreviewC3ScreenState extends State<PilgrimPreviewC3Screen>
    with TickerProviderStateMixin {
  static const int _totalChapters = 1189;

  late final AnimationController _glowCtrl;
  late final AnimationController _introCtrl;
  double _readChapters = 0;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
    _introCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..forward();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _introCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge([_glowCtrl, _introCtrl]),
                builder: (_, _) => Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: CustomPaint(
                      painter: PilgrimC3Painter(
                        glowAnimation: _glowCtrl.value,
                        introAnimation:
                            Curves.easeOutCubic.transform(_introCtrl.value),
                        readChapters: _readChapters.round(),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
            _controls(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            const Icon(Icons.circle, size: 10, color: Color(0xFFD4A843)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                '천로역정 · C3 Light of Revelation',
                style: TextStyle(
                  color: Color(0xFFF5E6C0),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                _introCtrl.reset();
                _introCtrl.forward();
              },
              icon: const Icon(Icons.replay, size: 16, color: Color(0xFFC47B5A)),
              label: const Text('인트로',
                  style: TextStyle(color: Color(0xFFC47B5A), fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _controls() {
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
                Text('읽은 장  $read / $_totalChapters',
                    style: const TextStyle(
                        color: Color(0xFFE0D8C5),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text('$pct %',
                    style: const TextStyle(
                        color: Color(0xFFD4A843),
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
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
                _preset('초반', 200),
                _preset('중간', 594),
                _preset('후반', 950),
                _preset('완독', _totalChapters),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _preset(String label, int v) => TextButton(
        onPressed: () => setState(() => _readChapters = v.toDouble()),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFC47B5A),
          textStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: const Size(0, 30),
        ),
        child: Text(label),
      );
}
