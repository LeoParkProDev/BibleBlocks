import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 표시 언어 설정.
///
/// 값 의미:
/// - `Locale('ko')` / `Locale('en')` : 명시적으로 선택한 언어
/// - `null` : 시스템 기본(기기 언어 따라감)
///
/// 저장값이 없으면 **한국어**가 기본(한국 우선 앱). `'system'`을 저장하면
/// 시스템 기본으로 동작한다.
final localeProvider =
    AsyncNotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

class LocaleNotifier extends AsyncNotifier<Locale?> {
  static const _key = 'app_locale';
  static const _system = 'system';

  @override
  Future<Locale?> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code == null) return const Locale('ko'); // 기본: 한국어
      if (code == _system) return null; // 시스템 기본
      return Locale(code);
    } catch (_) {
      return const Locale('ko');
    }
  }

  /// [locale]을 설정. null이면 "시스템 기본".
  Future<void> setLocale(Locale? locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, locale?.languageCode ?? _system);
    } catch (_) {
      // 무시 — 저장 실패해도 런타임 상태는 갱신
    }
    state = AsyncValue.data(locale);
  }
}
