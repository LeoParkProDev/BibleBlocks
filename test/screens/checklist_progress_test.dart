import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/screens/checklist/checklist_screen.dart';

Widget buildTestApp() {
  return const ProviderScope(
    child: MaterialApp(home: ChecklistScreen()),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // F-01: 마태복음 사용 (신약 첫 책, 화면에 보임)
  testWidgets('F-01: 장 체크 시 상단 진행률 숫자 즉시 업데이트', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('0 / 1189장'), findsOneWidget);

    await tester.tap(find.text('신약'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마태복음'));
    await tester.pumpAndSettle();

    final ch1 = find.descendant(
      of: find.byType(GridView),
      matching: find.text('1'),
    );
    await tester.tap(ch1);
    await tester.pumpAndSettle();

    expect(find.text('1 / 1189장'), findsOneWidget);
  });

  // F-02
  testWidgets('F-02: 장 체크 시 퍼센트 즉시 업데이트', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('0.0%'), findsOneWidget);

    await tester.tap(find.text('신약'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마태복음'));
    await tester.pumpAndSettle();

    final ch1 = find.descendant(
      of: find.byType(GridView),
      matching: find.text('1'),
    );
    await tester.tap(ch1);
    await tester.pumpAndSettle();

    expect(find.text('0.0%'), findsNothing);
    expect(find.text('0.1%'), findsOneWidget);
  });

  // F-03
  testWidgets('F-03: 장 체크 시 해당 책 미니 프로그레스바 업데이트', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('창세기'));
    await tester.pumpAndSettle();

    final ch1 = find.descendant(
      of: find.byType(GridView),
      matching: find.text('1'),
    );
    await tester.tap(ch1);
    await tester.pumpAndSettle();

    expect(find.text('1/50장'), findsOneWidget);
  });

  // F-04: 스크롤해서 빌레몬서 찾기
  testWidgets('F-04: "미완료" 필터 — 완독 책 제외', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // 신약 → 빌레몬서 스크롤
    await tester.tap(find.text('신약'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('빌레몬서'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('빌레몬서'));
    await tester.pumpAndSettle();

    final ch1 = find.descendant(
      of: find.byType(GridView),
      matching: find.text('1'),
    );
    await tester.tap(ch1);
    await tester.pumpAndSettle();

    // "미완료" 필터
    await tester.tap(find.text('미완료'));
    await tester.pumpAndSettle();

    expect(find.text('빌레몬서'), findsNothing);
  });

  // F-05
  testWidgets('F-05: 장 그리드 7열 레이아웃 확인', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('창세기'));
    await tester.pumpAndSettle();

    final gridView = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 7);
  });
}
