import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/screens/settings/settings_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // 후원 카드는 리스트 맨 아래(진행도 초기화 아래)에 있어 스크롤 필요
  Future<void> scrollToDonation(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('개발자 후원하기'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('설정 화면에 "개발자 후원하기" 타일이 렌더된다', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    await tester.pumpAndSettle();
    await scrollToDonation(tester);

    expect(find.text('개발자 후원하기'), findsOneWidget);
  });

  testWidgets('후원 타일은 탭 가능한 ListTile이며 초기화 아래에 위치한다', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    await tester.pumpAndSettle();
    await scrollToDonation(tester);

    final tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('개발자 후원하기'),
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.onTap, isNotNull);

    // 진행도 초기화보다 아래에 렌더되는지
    final resetY = tester.getTopLeft(find.text('진행도 초기화')).dy;
    final donationY = tester.getTopLeft(find.text('개발자 후원하기')).dy;
    expect(donationY, greaterThan(resetY));
  });

  testWidgets('성경 본문 출처(개역한글·대한성서공회) 표기가 있다', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('성경 본문 출처'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('개역한글'), findsOneWidget);
    expect(find.textContaining('대한성서공회'), findsOneWidget);
  });
}
