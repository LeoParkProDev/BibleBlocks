import 'package:flutter/material.dart';

import '../painters/pilgrim_c_mountain_painter.dart';

class PilgrimPreviewCScreen extends StatefulWidget {
  const PilgrimPreviewCScreen({super.key});

  @override
  State<PilgrimPreviewCScreen> createState() => _PilgrimPreviewCScreenState();
}

class _PilgrimPreviewCScreenState extends State<PilgrimPreviewCScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _pulse;

  // Simulated progress — adjustable via slider to preview the journey.
  double _progress = 0.35;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const totalChapters = PilgrimCLandscape.totalChapters;
    final readChapters = (_progress * totalChapters).round();

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a1a),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              readChapters: readChapters,
              totalChapters: totalChapters,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: InteractiveViewer(
                    minScale: 0.6,
                    maxScale: 3.0,
                    boundaryMargin: const EdgeInsets.all(200),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_intro, _pulse]),
                      builder: (context, _) {
                        return CustomPaint(
                          size: Size.infinite,
                          painter: PilgrimCMountainPainter(
                            introAnimation:
                                Curves.easeOutCubic.transform(_intro.value),
                            pulseAnimation: _pulse.value,
                            readChapters: readChapters,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            _ControlsBar(
              progress: _progress,
              readChapters: readChapters,
              totalChapters: totalChapters,
              onProgressChanged: (v) => setState(() => _progress = v),
              onReplayIntro: () {
                _intro
                  ..reset()
                  ..forward();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final int readChapters;
  final int totalChapters;
  const _Header({required this.readChapters, required this.totalChapters});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF16162A),
            Color(0xFF0a0a1a),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.landscape_rounded,
              color: Color(0xFFD4A843), size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Pilgrim\'s Progress — Mountain Landscape',
                style: TextStyle(
                  color: Color(0xFFF5E6C0),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'City of Destruction  >  The Way  >  Celestial City',
                style: TextStyle(
                  color: Color(0xFFA89F91),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFC47B5A).withValues(alpha: 0.18),
              border: Border.all(
                  color: const Color(0xFFC47B5A).withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$readChapters / $totalChapters',
              style: const TextStyle(
                color: Color(0xFFE9A583),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ControlsBar extends StatelessWidget {
  final double progress;
  final int readChapters;
  final int totalChapters;
  final ValueChanged<double> onProgressChanged;
  final VoidCallback onReplayIntro;

  const _ControlsBar({
    required this.progress,
    required this.readChapters,
    required this.totalChapters,
    required this.onProgressChanged,
    required this.onReplayIntro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F22),
        border: Border(
          top: BorderSide(color: Color(0xFF1E1E36), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Pilgrim Progress',
                style: TextStyle(
                  color: Color(0xFFA89F91),
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onReplayIntro,
                icon: const Icon(Icons.replay_rounded,
                    size: 16, color: Color(0xFFD4A843)),
                label: const Text('Replay Intro',
                    style: TextStyle(
                        color: Color(0xFFD4A843), fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFC47B5A),
              inactiveTrackColor: const Color(0xFF2A2A40),
              thumbColor: const Color(0xFFE9A583),
              overlayColor: const Color(0xFFC47B5A).withValues(alpha: 0.15),
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: progress,
              onChanged: onProgressChanged,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _Legend(color: Color(0xFFC47B5A), label: 'The Way'),
              _Legend(color: Color(0xFFE8C67A), label: 'Shining Mts'),
              _Legend(color: Color(0xFF3A6A8A), label: 'Jordan'),
              _Legend(color: Color(0xFFD4A843), label: 'Celestial City'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 6,
              )
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFA89F91), fontSize: 11),
        ),
      ],
    );
  }
}
