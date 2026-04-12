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

  // E-01
  testWidgets('E-01: "체크리스트" AppBar 타이틀 표시', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    expect(find.text('체크리스트'), findsOneWidget);
  });

  // E-02
  testWidgets('E-02: 초기 상태 진행률 표시', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    expect(find.text('0 / 1189장'), findsOneWidget);
    expect(find.text('0.0%'), findsOneWidget);
  });

  // E-03
  testWidgets('E-03: 필터 칩 4개 렌더링', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('구약'), findsOneWidget);
    expect(find.text('신약'), findsOneWidget);
    expect(find.text('미완료'), findsOneWidget);
  });

  // E-04
  testWidgets('E-04: 기본 필터 "전체" — 66권 표시', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    expect(find.text('창세기'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });

  // E-05
  testWidgets('E-05: "구약" 필터 → 신약 책 숨김', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('구약'));
    await tester.pumpAndSettle();
    expect(find.text('창세기'), findsOneWidget);
    // 신약 첫 책이 안 보여야
    expect(find.text('마태복음'), findsNothing);
  });

  // E-06
  testWidgets('E-06: "신약" 필터 → 구약 책 숨김', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('신약'));
    await tester.pumpAndSettle();
    expect(find.text('창세기'), findsNothing);
  });

  // E-07
  testWidgets('E-07: 책 탭 → 아코디언 펼침 (장 그리드 표시)', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('창세기'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
  });

  // E-08
  testWidgets('E-08: 이미 펼쳐진 책 다시 탭 → 접힘', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('창세기'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);

    await tester.tap(find.text('창세기'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsNothing);
  });

  // E-09: 마태복음(신약 첫 번째, 화면에 보임) 사용
  testWidgets('E-09: 장 번호 탭 → 체크 토글', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('신약'));
    await tester.pumpAndSettle();

    // 마태복음 펼치기 (신약 첫 책, 화면에 보임)
    await tester.tap(find.text('마태복음'));
    await tester.pumpAndSettle();

    // 장 "1" 탭
    final gridItems = find.descendant(
      of: find.byType(GridView),
      matching: find.text('1'),
    );
    await tester.tap(gridItems);
    await tester.pumpAndSettle();

    expect(find.text('1 / 1189장'), findsOneWidget);
  });

  // E-10: 스크롤해서 빌레몬서(1장) 찾기
  testWidgets('E-10: 책 완독 시 체크마크 아이콘 변경', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('신약'));
    await tester.pumpAndSettle();

    // 빌레몬서까지 스크롤
    await tester.scrollUntilVisible(
      find.text('빌레몬서'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('빌레몬서'));
    await tester.pumpAndSettle();

    // 1장 체크 → 완독
    final ch1 = find.descendant(
      of: find.byType(GridView),
      matching: find.text('1'),
    );
    await tester.tap(ch1);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsWidgets);
  });
}
