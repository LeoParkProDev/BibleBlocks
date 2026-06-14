import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bible_blocks/l10n/l10n.dart';

Future<AppLocalizations> _resolve(WidgetTester tester, Locale? locale) async {
  late AppLocalizations t;
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(builder: (context) {
      t = context.l10n;
      return const SizedBox();
    }),
  ));
  return t;
}

void main() {
  testWidgets('영어 로케일 → 영어 문자열', (tester) async {
    final t = await _resolve(tester, const Locale('en'));
    expect(t.navChecklist, 'Checklist');
    expect(t.navBlocks, 'Blocks');
    expect(t.loginKakao, 'Sign in with Kakao');
    expect(t.onbStart, 'Start');
  });

  testWidgets('한국어 로케일 → 한국어 문자열', (tester) async {
    final t = await _resolve(tester, const Locale('ko'));
    expect(t.navChecklist, '체크리스트');
    expect(t.settingsTitle, '설정');
    expect(t.onbIntentTitle, '어떻게 읽고 싶으세요?');
  });

  testWidgets('델리게이트 없으면 한국어로 폴백(기존 위젯테스트 호환)', (tester) async {
    late AppLocalizations t;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        t = context.l10n;
        return const SizedBox();
      }),
    ));
    expect(t.navChecklist, '체크리스트');
    expect(t.skip, '건너뛰기');
  });
}
