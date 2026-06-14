import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'share_service_web.dart' if (dart.library.io) 'share_service_stub.dart'
    as platform;

/// 구절 공유 카드의 배경 테마. 딥와인/크림/세피아 3종.
enum VerseCardTheme { deepWine, cream, sepia }

/// 한 테마의 색 구성.
class _CardStyle {
  const _CardStyle({
    required this.gradient,
    required this.text,
    required this.accent,
    required this.watermark,
    required this.label,
  });

  final List<Color> gradient; // 위→아래
  final Color text;
  final Color accent; // 인용 부호, 출처
  final Color watermark;
  final String label; // 사용자에게 보일 테마 이름
}

/// 좋아하는 절을 1080×1080 정사각 카드 이미지로 렌더링/공유한다.
///
/// 진도 카드([ShareService.renderShareCard])와 같은 `PictureRecorder` →
/// `toImage` PNG 파이프라인을 재사용한다.
class VerseImageService {
  VerseImageService._();

  static const double size = 1080;
  static const double _padding = 90;

  /// 본문 폰트 크기 자동 맞춤 범위(긴 절은 줄여 말줄임 없이 한 카드에).
  static const double minFont = 30;
  static const double maxFont = 74;
  static const double _fontStep = 2;

  /// 유입 추적용 — 워터마크에 노출되는 앱 URL.
  static const String appUrl = 'bible-blocks-omega.vercel.app';

  static const Map<VerseCardTheme, _CardStyle> _styles = {
    VerseCardTheme.deepWine: _CardStyle(
      gradient: [Color(0xFF4A1626), Color(0xFF1E0810)],
      text: Color(0xFFF6E8DC),
      accent: Color(0xFFD4A843),
      watermark: Color(0x80F6E8DC),
      label: '딥와인',
    ),
    VerseCardTheme.cream: _CardStyle(
      gradient: [Color(0xFFFBF4EA), Color(0xFFEFE2CE)],
      text: Color(0xFF3D3529),
      accent: Color(0xFFC47B5A),
      watermark: Color(0xFFA89F91),
      label: '크림',
    ),
    VerseCardTheme.sepia: _CardStyle(
      gradient: [Color(0xFFF4ECD8), Color(0xFFE2D2B4)],
      text: Color(0xFF5B4636),
      accent: Color(0xFF9C6B3F),
      watermark: Color(0x995B4636),
      label: '세피아',
    ),
  };

  static String themeLabel(VerseCardTheme theme) => _styles[theme]!.label;

  /// [text]가 [maxWidth]×[maxHeight] 안에 들어가는 가장 큰 폰트를 고른다.
  /// 한계까지 작아져도 안 들어가면 [minFont]을 반환(잘림 대신 작게).
  static double fitFontSize({
    required String text,
    required double maxWidth,
    required double maxHeight,
    double lineHeight = 1.4,
  }) {
    for (var fs = maxFont; fs > minFont; fs -= _fontStep) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: fs, height: lineHeight),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);
      if (tp.height <= maxHeight) return fs;
    }
    return minFont;
  }

  /// 카드를 렌더링해 PNG 바이트로 반환.
  static Future<Uint8List> renderVerseCard({
    required String verseText,
    required String citation,
    required VerseCardTheme theme,
  }) async {
    final style = _styles[theme]!;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    // 배경 그라디언트
    final bg = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(0, size),
        style.gradient,
      );
    canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), bg);

    const contentWidth = size - _padding * 2;

    // 장식용 인용 부호
    _paintText(
      canvas,
      text: '“',
      style: TextStyle(
        fontSize: 200,
        height: 1,
        fontWeight: FontWeight.bold,
        color: style.accent.withValues(alpha: 0.28),
      ),
      x: _padding,
      y: 70,
      width: contentWidth,
    );

    // 본문(자동 맞춤) — 카드 중앙 영역에 세로 중앙 정렬
    const verseTop = 300.0;
    const verseBottom = 820.0;
    const verseAreaHeight = verseBottom - verseTop;
    final fontSize = fitFontSize(
      text: verseText,
      maxWidth: contentWidth,
      maxHeight: verseAreaHeight,
    );
    final verseTp = _layout(
      text: verseText,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: style.text,
      ),
      width: contentWidth,
    );
    final verseY = verseTop + (verseAreaHeight - verseTp.height) / 2;
    verseTp.paint(canvas, Offset(_padding, verseY));

    // 출처 인용 — 본문 아래
    _paintText(
      canvas,
      text: '— $citation · 개역한글',
      style: TextStyle(
        fontSize: 34,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: style.accent,
      ),
      x: _padding,
      y: verseY + verseTp.height + 36,
      width: contentWidth,
    );

    // 워터마크 + URL — 하단 (유입 채널)
    _paintText(
      canvas,
      text: '바이블블록 · $appUrl',
      style: TextStyle(
        fontSize: 28,
        height: 1.2,
        color: style.watermark,
      ),
      x: _padding,
      y: size - 80,
      width: contentWidth,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return byteData!.buffer.asUint8List();
  }

  /// 카드를 렌더해 공유(모바일) 또는 다운로드(웹).
  static Future<void> shareVerseCard({
    required String verseText,
    required String citation,
    required VerseCardTheme theme,
  }) async {
    final bytes = await renderVerseCard(
      verseText: verseText,
      citation: citation,
      theme: theme,
    );
    if (kIsWeb) {
      platform.downloadImage(bytes, 'bible_verse.png');
      return;
    }
    final xfile = XFile.fromData(
      bytes,
      mimeType: 'image/png',
      name: 'bible_verse.png',
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [xfile],
        text: '"$verseText"\n— $citation (개역한글)\n\nhttps://$appUrl',
      ),
    );
  }

  static TextPainter _layout({
    required String text,
    required TextStyle style,
    required double width,
  }) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: width, maxWidth: width);
  }

  static void _paintText(
    Canvas canvas, {
    required String text,
    required TextStyle style,
    required double x,
    required double y,
    required double width,
  }) {
    _layout(text: text, style: style, width: width).paint(canvas, Offset(x, y));
  }
}
