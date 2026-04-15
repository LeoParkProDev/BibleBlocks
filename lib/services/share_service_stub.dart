import 'dart:typed_data';

void downloadImage(Uint8List bytes, String filename) {
  // No-op on non-web platforms.
}

void shareViaKakao({
  required String nickname,
  required int percent,
  required int totalRead,
  required int totalChapters,
  required String imageUrl,
  required String webUrl,
}) {
  // No-op on non-web platforms; native share is used instead.
}
