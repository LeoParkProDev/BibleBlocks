import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/screens/bible_view/bible_view_screen.dart';
import 'package:bible_blocks/theme/app_colors.dart';

Widget buildTestApp() {
  return const ProviderScope(
    child: MaterialApp(home: BibleViewScreen()),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // G-01
  testWidgets('G-01: 다크 배경 적용', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.darkBg);
  });

  // G-02
  testWidgets('G-02: 상단 좌측 진행률 뱃지 + 우측 계정 아이콘', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('0 / 1189'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  // G-03
  testWidgets('G-03: 하단 힌트 텍스트', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('핀치로 확대 · 드래그로 이동'), findsOneWidget);
  });

  // G-04
  testWidgets('G-04: InteractiveViewer 존재', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
  });
}
