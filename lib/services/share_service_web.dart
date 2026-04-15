import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void downloadImage(Uint8List bytes, String filename) {
  final base64 = base64Encode(bytes);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = 'data:image/png;base64,$base64'
    ..download = filename;
  anchor.click();
}

void shareViaKakao({
  required String nickname,
  required int percent,
  required int totalRead,
  required int totalChapters,
  required String imageUrl,
  required String webUrl,
}) {
  _kakaoShareSendDefault(
    nickname.toJS,
    percent.toJS,
    totalRead.toJS,
    totalChapters.toJS,
    imageUrl.toJS,
    webUrl.toJS,
  );
}

@JS('_kakaoShareSendDefault')
external void _kakaoShareSendDefault(
  JSString nickname,
  JSNumber percent,
  JSNumber totalRead,
  JSNumber totalChapters,
  JSString imageUrl,
  JSString webUrl,
);
