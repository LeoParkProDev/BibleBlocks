import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/bible_data.dart';
import '../painters/isometric_bible_painter.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import 'share_service_web.dart' if (dart.library.io) 'share_service_stub.dart'
    as platform;

class ShareService {
  /// Mobile: render image + open native share sheet.
  static Future<void> shareProgress({
    required Map<int, Set<int>> progressData,
    required String nickname,
  }) async {
    final totalRead = ProgressService.totalRead(progressData);
    final percent = (totalRead / BibleData.totalChapters * 100).round();
    final shareText = '$nickname의 바이블블록 — $percent% 완료!\n'
        '바이블블록으로 성경 읽기 습관을 만들어보세요.';

    final imageBytes = await renderShareCard(
      progressData: progressData,
      nickname: nickname,
    );

    if (kIsWeb) {
      platform.downloadImage(imageBytes, 'bible_blocks_share.png');
    } else {
      final xfile = XFile.fromData(
        imageBytes,
        mimeType: 'image/png',
        name: 'bible_blocks_share.png',
      );
      await Share.shareXFiles([xfile], text: shareText);
    }
  }

  /// Web: trigger browser download.
  static void downloadImageOnWeb(Uint8List bytes) {
    platform.downloadImage(bytes, 'bible_blocks_share.png');
  }

  /// Render the 1080x1080 share card and return PNG bytes.
  static Future<Uint8List> renderShareCard({
    required Map<int, Set<int>> progressData,
    required String nickname,
  }) async {
    final totalRead = ProgressService.totalRead(progressData);
    final percent = (totalRead / BibleData.totalChapters * 100).round();

    const width = 1080.0;
    const height = 1080.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // Dark background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()..color = AppColors.darkBg,
    );

    // Gradient overlay
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF151530), Color(0xFF0a0a1a)],
      ).createShader(const Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), gradientPaint);

    // Draw 3D bible blocks
    canvas.save();
    canvas.translate(width / 2, height / 2 + 80);
    canvas.scale(2.5);
    final painter = IsometricBiblePainter(
      progressData: progressData,
      rotationAngle: 0.0,
      introAnimation: 1.0,
      fillAnimation: 1.0,
    );
    painter.paint(canvas, const Size(0, 0));
    canvas.restore();

    // Text styles
    final titleStyle = ui.TextStyle(
      color: const Color(0xFFFFFFFF),
      fontSize: 48,
      fontWeight: FontWeight.bold,
    );
    final subtitleStyle = ui.TextStyle(
      color: const Color(0xAAFFFFFF),
      fontSize: 32,
    );
    final percentStyle = ui.TextStyle(
      color: AppColors.gold,
      fontSize: 96,
      fontWeight: FontWeight.bold,
    );
    final brandStyle = ui.TextStyle(
      color: const Color(0x66FFFFFF),
      fontSize: 24,
    );

    _drawText(canvas, '$nickname의 바이블블록', titleStyle, width, 60);
    _drawText(canvas, '$percent%', percentStyle, width, 160);
    _drawText(canvas, '$totalRead / ${BibleData.totalChapters}장 완료', subtitleStyle, width, 280);
    _drawText(canvas, '바이블블록', brandStyle, width, height - 70);

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static void _drawText(
    Canvas canvas,
    String text,
    ui.TextStyle style,
    double maxWidth,
    double y,
  ) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: TextAlign.center),
    )
      ..pushStyle(style)
      ..addText(text);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: maxWidth));
    canvas.drawParagraph(paragraph, Offset(0, y));
  }
}
