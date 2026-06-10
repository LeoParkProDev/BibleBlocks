import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/providers/reader_prefs_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('기본값: 흰색 테마, 글자 18, 줄간격 1.8', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final p = c.read(readerPrefsProvider);
    expect(p.theme, ReaderTheme.light);
    expect(p.fontSize, 18);
    expect(p.lineHeight, 1.8);
  });

  test('글자 크기 증가/감소', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(readerPrefsProvider.notifier);
    final base = c.read(readerPrefsProvider).fontSize;
    await n.increaseFont();
    expect(c.read(readerPrefsProvider).fontSize, base + ReaderPrefs.fontStep);
    await n.decreaseFont();
    expect(c.read(readerPrefsProvider).fontSize, base);
  });

  test('글자 크기는 최대/최소를 넘지 않는다', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(readerPrefsProvider.notifier);
    for (var i = 0; i < 50; i++) {
      await n.increaseFont();
    }
    expect(c.read(readerPrefsProvider).fontSize, ReaderPrefs.maxFont);
    for (var i = 0; i < 50; i++) {
      await n.decreaseFont();
    }
    expect(c.read(readerPrefsProvider).fontSize, ReaderPrefs.minFont);
  });

  test('테마 변경이 상태에 반영된다', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(readerPrefsProvider.notifier).setTheme(ReaderTheme.dark);
    expect(c.read(readerPrefsProvider).theme, ReaderTheme.dark);
  });

  test('설정이 SharedPreferences에 저장된다', () async {
    final c1 = ProviderContainer();
    await c1.read(readerPrefsProvider.notifier).setTheme(ReaderTheme.sepia);
    await c1.read(readerPrefsProvider.notifier).setLineHeight(2.2);
    c1.dispose();

    // 새 컨테이너가 저장값을 로드하는지
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    c2.read(readerPrefsProvider); // build 트리거
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final p = c2.read(readerPrefsProvider);
    expect(p.theme, ReaderTheme.sepia);
    expect(p.lineHeight, 2.2);
  });
}
