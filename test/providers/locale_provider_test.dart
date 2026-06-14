import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/providers/locale_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('저장값 없으면 기본은 한국어', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(await c.read(localeProvider.future), const Locale('ko'));
  });

  test('English 설정 후 재실행에서도 유지', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(localeProvider.future);
    await c.read(localeProvider.notifier).setLocale(const Locale('en'));
    expect(c.read(localeProvider).value, const Locale('en'));

    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    expect(await c2.read(localeProvider.future), const Locale('en'));
  });

  test('시스템 기본(null) 설정 시 재로드해도 null', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(localeProvider.future);
    await c.read(localeProvider.notifier).setLocale(null);
    expect(c.read(localeProvider).value, isNull);

    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    expect(await c2.read(localeProvider.future), isNull);
  });
}
