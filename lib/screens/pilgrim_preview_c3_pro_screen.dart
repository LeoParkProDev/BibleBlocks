import 'package:flutter/material.dart';

import '../painters/pilgrim_c3_pro_painter.dart';

class PilgrimPreviewC3ProScreen extends StatefulWidget {
  const PilgrimPreviewC3ProScreen({super.key});

  @override
  State<PilgrimPreviewC3ProScreen> createState() =>
      _PilgrimPreviewC3ProScreenState();
}

class _PilgrimPreviewC3ProScreenState extends State<PilgrimPreviewC3ProScreen>
    with TickerProviderStateMixin {
  static const int _totalChapters = 1189;

  late final AnimationController _glowCtrl;
  late final AnimationController _introCtrl;
  double _readChapters = 0;
  bool _showOverlay = true;

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
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: _sceneStack(),
                    ),
                  ),
                ),
                _controls(),
              ],
            ),
          ),
          if (_showOverlay)
            Positioned(
              top: 60,
              right: 20,
              child: _statsCard(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: const Color(0xFF1A1528),
        foregroundColor: const Color(0xFFD4A843),
        onPressed: () => setState(() => _showOverlay = !_showOverlay),
        child: Icon(_showOverlay ? Icons.visibility_off : Icons.visibility),
      ),
    );
  }

  Widget _sceneStack() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Static layer — repaints only when readChapters changes.
        // RepaintBoundary ensures Flutter's raster cache holds this layer
        // across glowAnimation frames.
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _introCtrl,
            builder: (context, _) => CustomPaint(
              painter: PilgrimC3ProStaticPainter(
                readChapters: _readChapters.round(),
                introAnimation:
                    Curves.easeOutCubic.transform(_introCtrl.value),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        // Overlay layer — celestial halo pulse + latest path-stone pulse.
        // Redraws every glow frame but only paints two circles.
        AnimatedBuilder(
          animation: _glowCtrl,
          builder: (context, _) => CustomPaint(
            painter: PilgrimC3ProOverlayPainter(
              glowAnimation: _glowCtrl.value,
              readChapters: _readChapters.round(),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }

  Widget _statsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xE61A1528),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A2E38)),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Color(0xFFE0D8C5),
          fontSize: 11,
          fontFamily: 'monospace',
          height: 1.5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'C3.pro (2-layer + RepaintBoundary)',
              style: TextStyle(
                color: Color(0xFFD4A843),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text('voxels cached  : $cachedVoxelCount'),
            Text('  terrain kept : $cachedTerrainCount'),
            const Text('sort           : cached'),
            const Text('fog culling    : on'),
            const Text('static layer   : RepaintBoundary'),
            const Text('  repaint on   : readChapters change'),
            const Text('overlay layer  : 2 pulse circles'),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            const Icon(Icons.rocket_launch, size: 14, color: Color(0xFFD4A843)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '천로역정 · C3.pro',
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
