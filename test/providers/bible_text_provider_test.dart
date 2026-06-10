import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bible_blocks/services/bible_text_service.dart';
import 'package:bible_blocks/providers/bible_text_provider.dart';

class _FakeService extends BibleTextService {
  _FakeService() : super(bundle: rootBundle);
  @override
  Future<List<BibleVerse>> loadChapter(int b, int c) async =>
      const [BibleVerse(1, '절1'), BibleVerse(2, '절2')];
}

void main() {
  test('chapterTextProvider는 서비스의 절 목록을 반환', () async {
    final container = ProviderContainer(overrides: [
      bibleTextServiceProvider.overrideWithValue(_FakeService()),
    ]);
    addTearDown(container.dispose);
    final verses =
        await container.read(chapterTextProvider((book: 0, chapter: 1)).future);
    expect(verses.map((v) => v.text).toList(), ['절1', '절2']);
    expect(verses.map((v) => v.number).toList(), [1, 2]);
  });
}
