import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/screens/onboarding/onboarding_screen.dart';

Widget _wrap() => const ProviderScope(
      child: MaterialApp(home: OnboardingScreen()),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('첫 화면(의도 선택)과 진행 점이 노출된다', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('어떻게 읽고 싶으세요?'), findsOneWidget);
    expect(find.text('건너뛰기'), findsOneWidget);
  });

  testWidgets('건너뛰기 시 온보딩 완료 플래그가 저장된다', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_done'), true);
  });

  testWidgets('의도 카드를 고르면 계획 선택 화면으로 넘어간다', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('매일 한 장'));
    await tester.pumpAndSettle();

    expect(find.text('짧은 계획으로 시작해볼까요?'), findsOneWidget);
  });
}
