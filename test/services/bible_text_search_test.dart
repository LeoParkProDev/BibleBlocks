import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bible_blocks/services/bible_text_service.dart';

/// 책 인덱스별로 다른 본문을 돌려주는 가짜 번들(검색 결과를 특정해 검증).
class _FakeBibleBundle extends CachingAssetBundle {
  static const _texts = {
    0: '태초에 하나님이 천지를 창조하시니라',
    18: '여호와는 나의 목자시니 내게 부족함이 없으리로다',
    42: '하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니',
  };

  @override
  Future<ByteData> load(String key) async {
    final b = int.parse(RegExp(r'/(\d+)\.json').firstMatch(key)!.group(1)!);
    final text = _texts[b] ?? '빈 구절 $b';
    final json = jsonEncode({
      'book': b,
      'chapters': [
        [
          [1, text],
        ],
      ],
    });
    return ByteData.view(Uint8List.fromList(utf8.encode(json)).buffer);
  }
}

void main() {
  group('findMatch (순수 로직)', () {
    test('부분일치 — 원문 내 범위를 정확히 반환', () {
      final m = BibleTextService.findMatch('하나님이 세상을 이처럼 사랑하사', '사랑');
      expect(m, isNotNull);
      final text = '하나님이 세상을 이처럼 사랑하사';
      expect(text.substring(m!.$1, m.$2), '사랑');
    });

    test('없는 단어는 null', () {
      expect(
        BibleTextService.findMatch('태초에 하나님이', '컴퓨터'),
        isNull,
      );
    });

    test('공백 무시 — 쿼리의 공백을 무시하고 매칭', () {
      final m = BibleTextService.findMatch('여호와는 나의 목자시니', '여호와는나의');
      expect(m, isNotNull);
      expect('여호와는 나의 목자시니'.substring(m!.$1, m.$2), '여호와는 나의');
    });

    test('빈 쿼리/공백 쿼리는 null', () {
      expect(BibleTextService.findMatch('아무 본문', ''), isNull);
      expect(BibleTextService.findMatch('아무 본문', '   '), isNull);
    });
  });

  group('search (전체 스캔)', () {
    late BibleTextService svc;
    setUp(() => svc = BibleTextService(bundle: _FakeBibleBundle()));

    test('존재하는 단어 매칭 — 올바른 책/장/절', () async {
      final results = await svc.search('사랑');
      expect(results.length, 1);
      expect(results.first.bookIndex, 42);
      expect(results.first.chapter, 1);
      expect(results.first.verse, 1);
      expect(
        results.first.text.substring(
          results.first.matchStart,
          results.first.matchEnd,
        ),
        '사랑',
      );
    });

    test('여러 책에 걸친 단어 매칭', () async {
      final results = await svc.search('하나님');
      // book 0, 42 두 곳
      expect(results.map((r) => r.bookIndex).toSet(), {0, 42});
    });

    test('없는 단어는 0건', () async {
      expect(await svc.search('블록체인'), isEmpty);
    });

    test('빈 쿼리는 0건', () async {
      expect(await svc.search(''), isEmpty);
    });

    test('공백 무시 — 전체 스캔에서도 동작', () async {
      final results = await svc.search('여호와는나의');
      expect(results.length, 1);
      expect(results.first.bookIndex, 18);
    });

    test('진행률 콜백이 호출된다', () async {
      var lastProgress = 0.0;
      await svc.search('하나님', onProgress: (p) => lastProgress = p);
      expect(lastProgress, 1.0);
    });

    test('limit을 넘기지 않는다', () async {
      final results = await svc.search('하나님', limit: 1);
      expect(results.length, 1);
    });
  });
}
