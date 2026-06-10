import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/providers/last_position_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('초기값은 null (기록 없음)', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(lastPositionProvider), isNull);
  });

  test('set으로 위치가 기록된다', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(lastPositionProvider.notifier).set(17, 42);
    expect(c.read(lastPositionProvider), (book: 17, chapter: 42));
  });

  test('위치가 SharedPreferences에 저장되어 다시 로드된다', () async {
    final c1 = ProviderContainer();
    await c1.read(lastPositionProvider.notifier).set(39, 3);
    c1.dispose();

    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    c2.read(lastPositionProvider); // build 트리거
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c2.read(lastPositionProvider), (book: 39, chapter: 3));
  });
}
