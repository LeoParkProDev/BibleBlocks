import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import 'app_localizations_ko.dart';

export 'app_localizations.dart';

/// 번역 접근 헬퍼.
///
/// 델리게이트가 트리에 없는 경우(위젯 테스트가 자체 MaterialApp을 만들 때 등)
/// 한국어로 폴백한다 — 앱 기본 언어가 한국어이므로 기존 테스트/화면이 그대로 동작.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this) ?? AppLocalizationsKo();
}
