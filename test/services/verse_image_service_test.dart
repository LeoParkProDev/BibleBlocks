import 'package:flutter_test/flutter_test.dart';
import 'package:bible_blocks/services/verse_image_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fitFontSize', () {
    test('짧은 텍스트는 상한 폰트를 받는다', () {
      final size = VerseImageService.fitFontSize(
        text: '짧은 절',
        maxWidth: 900,
        maxHeight: 600,
      );
      expect(size, VerseImageService.maxFont);
    });

    test('아주 긴 텍스트는 더 작은 폰트로 줄어든다', () {
      final long = '주는 나의 목자시니 내게 부족함이 없으리로다 ' * 20;
      final size = VerseImageService.fitFontSize(
        text: long,
        maxWidth: 900,
        maxHeight: 600,
      );
      expect(size, lessThan(VerseImageService.maxFont));
      expect(size, greaterThanOrEqualTo(VerseImageService.minFont));
    });

    test('긴 텍스트의 폰트는 짧은 텍스트보다 작거나 같다', () {
      final short = VerseImageService.fitFontSize(
        text: '여호와는',
        maxWidth: 900,
        maxHeight: 400,
      );
      final long = VerseImageService.fitFontSize(
        text: '여호와는 나의 목자시니 ' * 40,
        maxWidth: 900,
        maxHeight: 400,
      );
      expect(long, lessThanOrEqualTo(short));
    });

    test('극단적으로 긴 텍스트도 하한 폰트 이상을 보장(말줄임 방지)', () {
      final size = VerseImageService.fitFontSize(
        text: '가' * 3000,
        maxWidth: 900,
        maxHeight: 300,
      );
      expect(size, greaterThanOrEqualTo(VerseImageService.minFont));
    });
  });

  group('renderVerseCard', () {
    test('PNG 바이트를 생성한다 (스모크)', () async {
      final bytes = await VerseImageService.renderVerseCard(
        verseText: '여호와는 나의 목자시니 내게 부족함이 없으리로다',
        citation: '시편 23:1',
        theme: VerseCardTheme.deepWine,
      );
      expect(bytes, isNotEmpty);
      // PNG 매직 넘버
      expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    });

    test('모든 테마가 렌더된다', () async {
      for (final theme in VerseCardTheme.values) {
        final bytes = await VerseImageService.renderVerseCard(
          verseText: '태초에 하나님이 천지를 창조하시니라',
          citation: '창세기 1:1',
          theme: theme,
        );
        expect(bytes, isNotEmpty);
      }
    });

    test('매우 긴 절도 예외 없이 렌더된다', () async {
      final bytes = await VerseImageService.renderVerseCard(
        verseText: '여호와는 나의 목자시니 내게 부족함이 없으리로다 ' * 15,
        citation: '시편 23:1',
        theme: VerseCardTheme.cream,
      );
      expect(bytes, isNotEmpty);
    });
  });
}
