import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/screens/settings/settings_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('설정 화면에 "개발자 후원하기" 타일이 렌더된다', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('개발자 후원하기'), findsOneWidget);
  });

  testWidgets('후원 타일은 탭 가능한 ListTile이다', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    await tester.pumpAndSettle();

    final tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('개발자 후원하기'),
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.onTap, isNotNull);
  });
}
