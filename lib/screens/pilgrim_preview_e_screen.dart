import 'package:flutter/material.dart';

import '../painters/pilgrim_e_constellation_painter.dart';

class PilgrimPreviewEScreen extends StatefulWidget {
  const PilgrimPreviewEScreen({super.key});

  @override
  State<PilgrimPreviewEScreen> createState() => _PilgrimPreviewEScreenState();
}

class _PilgrimPreviewEScreenState extends State<PilgrimPreviewEScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final AnimationController _introCtrl;
  late final AnimationController _rotationCtrl;

  bool _rotating = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
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

  void _toggleRotation() {
    setState(() {
      _rotating = !_rotating;
      if (_rotating) {
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
                        painter: PilgrimEConstellationPainter(
                          glowAnimation: _glowCtrl.value,
                          introAnimation:
                              Curves.easeOutCubic.transform(_introCtrl.value),
                          rotationAngle: _rotationCtrl.value * 6.2831853,
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
            '천로역정 · Constellation Celestial Map',
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
              style: TextStyle(color: Color(0xFFC47B5A), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: _toggleRotation,
            icon: Icon(
              _rotating ? Icons.pause_circle_outline : Icons.sync,
              size: 16,
              color: const Color(0xFFD4A843),
            ),
            label: Text(
              _rotating ? '회전 멈춤' : '천구 회전',
              style: const TextStyle(
                color: Color(0xFFD4A843),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
