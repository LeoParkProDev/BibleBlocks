import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/app.dart';
import 'package:bible_blocks/providers/auth_provider.dart';

class _AlwaysGuestNotifier extends IsGuestNotifier {
  @override
  bool build() => true;
}

Widget buildTestApp() {
  return ProviderScope(
    overrides: [
      isGuestProvider.overrideWith(() => _AlwaysGuestNotifier()),
    ],
    child: const BibleBlocksApp(),
  );
}

/// BottomNavigationBar 안의 특정 탭을 찾아서 탭
Future<void> tapNavTab(WidgetTester tester, String label) async {
  final navBarFinder = find.byType(BottomNavigationBar);
  final target = find.descendant(of: navBarFinder, matching: find.text(label));
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // I-01
  testWidgets('I-01: 앱 시작 시 탭1 (내 성경) 표시', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    // BottomNavigationBar에 '내 성경' 라벨 존재
    expect(find.text('내 성경'), findsWidgets);
  });

  // I-02
  testWidgets('I-02: 탭2 (체크리스트) 전환', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tapNavTab(tester, '체크리스트');

    expect(find.text('0 / 1189장'), findsOneWidget);
  });

  // I-03
  testWidgets('I-03: 탭 전환 시 상태 유지 (StatefulShellRoute)', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // 탭2로 이동
    await tapNavTab(tester, '체크리스트');

    // 신약 필터
    await tester.tap(find.text('신약'));
    await tester.pumpAndSettle();

    // 탭1로 이동
    await tapNavTab(tester, '내 성경');

    // 다시 탭2로 복귀
    await tapNavTab(tester, '체크리스트');

    // 구약 첫 책이 안 보이면 신약 필터 유지된 것
    expect(find.text('창세기'), findsNothing);
  });

  // I-04
  testWidgets('I-04: 탭2 체크 → 탭1 진행률 반영', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // 탭2로 이동
    await tapNavTab(tester, '체크리스트');

    // 신약 → 마태복음 1장 체크
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

    // 탭1로 이동
    await tapNavTab(tester, '내 성경');

    // 진행률 반영
    expect(find.textContaining('1 / 1189'), findsOneWidget);
  });

  // I-05
  testWidgets('I-05: BottomNavigationBar 아이템 3개', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final navBar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navBar.items.length, 3);
    expect(navBar.items[0].label, '내 성경');
    expect(navBar.items[1].label, '체크리스트');
    expect(navBar.items[2].label, '설정');
  });
}
