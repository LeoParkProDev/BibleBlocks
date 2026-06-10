import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 리더 읽기 테마 (유버전식 흰색/세피아/검정).
enum ReaderTheme { light, sepia, dark }

class ReaderThemeColors {
  const ReaderThemeColors({
    required this.background,
    required this.text,
    required this.secondary,
    required this.brightness,
  });
  final Color background;
  final Color text;
  final Color secondary;
  final Brightness brightness;
}

extension ReaderThemeExt on ReaderTheme {
  ReaderThemeColors get colors => switch (this) {
        ReaderTheme.light => const ReaderThemeColors(
            background: Color(0xFFFAF8F5),
            text: Color(0xFF2E2A24),
            secondary: Color(0xFFA89F91),
            brightness: Brightness.light,
          ),
        ReaderTheme.sepia => const ReaderThemeColors(
            background: Color(0xFFF4ECD8),
            text: Color(0xFF5B4636),
            secondary: Color(0xFF9C8A6E),
            brightness: Brightness.light,
          ),
        ReaderTheme.dark => const ReaderThemeColors(
            background: Color(0xFF121212),
            text: Color(0xFFCFC9C0),
            secondary: Color(0xFF7E7970),
            brightness: Brightness.dark,
          ),
      };

  String get label => switch (this) {
        ReaderTheme.light => '흰색',
        ReaderTheme.sepia => '세피아',
        ReaderTheme.dark => '검정',
      };
}

/// 읽기 환경 설정값.
class ReaderPrefs {
  const ReaderPrefs({
    this.theme = ReaderTheme.light,
    this.fontSize = 18,
    this.lineHeight = 1.8,
  });

  final ReaderTheme theme;
  final double fontSize;
  final double lineHeight;

  static const double minFont = 14;
  static const double maxFont = 32;
  static const double fontStep = 1.5;

  ReaderPrefs copyWith({
    ReaderTheme? theme,
    double? fontSize,
    double? lineHeight,
  }) =>
      ReaderPrefs(
        theme: theme ?? this.theme,
        fontSize: fontSize ?? this.fontSize,
        lineHeight: lineHeight ?? this.lineHeight,
      );
}

const _kTheme = 'reader_theme';
const _kFont = 'reader_font_size';
const _kLine = 'reader_line_height';

final readerPrefsProvider =
    NotifierProvider<ReaderPrefsNotifier, ReaderPrefs>(ReaderPrefsNotifier.new);

class ReaderPrefsNotifier extends Notifier<ReaderPrefs> {
  @override
  ReaderPrefs build() {
    _load();
    return const ReaderPrefs();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      var s = state;
      final t = p.getString(_kTheme);
      if (t != null) {
        final match = ReaderTheme.values.where((e) => e.name == t);
        if (match.isNotEmpty) s = s.copyWith(theme: match.first);
      }
      final f = p.getDouble(_kFont);
      if (f != null) s = s.copyWith(fontSize: f);
      final l = p.getDouble(_kLine);
      if (l != null) s = s.copyWith(lineHeight: l);
      state = s;
    } catch (_) {
      // 저장값이 없거나 읽기 실패 시 기본값 유지
    }
  }

  Future<void> setTheme(ReaderTheme theme) async {
    state = state.copyWith(theme: theme);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTheme, theme.name);
  }

  Future<void> increaseFont() =>
      _setFont(state.fontSize + ReaderPrefs.fontStep);

  Future<void> decreaseFont() =>
      _setFont(state.fontSize - ReaderPrefs.fontStep);

  Future<void> _setFont(double value) async {
    final clamped = value.clamp(ReaderPrefs.minFont, ReaderPrefs.maxFont);
    state = state.copyWith(fontSize: clamped);
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kFont, clamped);
  }

  Future<void> setLineHeight(double value) async {
    state = state.copyWith(lineHeight: value);
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kLine, value);
  }
}
