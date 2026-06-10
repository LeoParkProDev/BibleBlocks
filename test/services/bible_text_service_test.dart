import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bible_blocks/services/bible_text_service.dart';

/// load 호출 횟수를 세는 가짜 번들. 항상 동일한 2장짜리 책을 돌려준다.
class _CountingBundle extends CachingAssetBundle {
  int loadCount = 0;
  @override
  Future<ByteData> load(String key) async {
    loadCount++;
    final json = jsonEncode({
      'book': 0,
      'chapters': [
        [
          [1, '창 1:1 본문'],
          [2, '창 1:2 본문'],
        ],
        [
          [1, '창 2:1 본문'],
        ],
      ],
    });
    final bytes = utf8.encode(json);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

void main() {
  test('loadChapter는 해당 장의 절(번호+본문) 목록을 반환', () async {
    final svc = BibleTextService(bundle: _CountingBundle());
    final ch1 = await svc.loadChapter(0, 1);
    expect(ch1.map((v) => v.number).toList(), [1, 2]);
    expect(ch1.map((v) => v.text).toList(), ['창 1:1 본문', '창 1:2 본문']);
  });

  test('같은 책 재요청 시 디스크는 1회만 읽는다 (캐시)', () async {
    final bundle = _CountingBundle();
    final svc = BibleTextService(bundle: bundle);
    await svc.loadChapter(0, 1);
    await svc.loadChapter(0, 2);
    expect(bundle.loadCount, 1);
  });

  test('범위 밖 장은 RangeError', () async {
    final svc = BibleTextService(bundle: _CountingBundle());
    expect(() => svc.loadChapter(0, 99), throwsRangeError);
  });

  test('범위 밖 책은 RangeError', () async {
    final svc = BibleTextService(bundle: _CountingBundle());
    expect(() => svc.loadChapter(999, 1), throwsRangeError);
  });
}
