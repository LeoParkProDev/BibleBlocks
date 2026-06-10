import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/painters/block_hit_test.dart';
import 'package:bible_blocks/providers/progress_provider.dart';
import 'package:bible_blocks/screens/bible_view/bible_view_screen.dart';

class _FakeProgress extends ProgressNotifier {
  @override
  Future<Map<int, Set<int>>> build() async => {
        0: {1, 2},
      };
}

Widget _wrap() {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, state) => const BibleViewScreen()),
    GoRoute(
      path: '/reader/:book/:chapter',
      builder: (_, state) => Scaffold(
        body: Text(
          'reader-${state.pathParameters['book']}-${state.pathParameters['chapter']}',
        ),
      ),
    ),
  ]);
  return ProviderScope(
    overrides: [progressProvider.overrideWith(_FakeProgress.new)],
    child: MaterialApp.router(routerConfig: router),
  );
}

/// 최상단 레이어(z=11) 블록의 윗면 중심 — 가려지지 않아 탭이 확실히 닿는다.
Offset _blockPos(WidgetTester tester) {
  final size = tester.getSize(find.byType(InteractiveViewer));
  return BlockHitTest.blockTopCenter((x: 4, y: 0, z: 11), size, 0);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('블록 탭 → 우하단에 범위 패널 + 읽으러 가기 버튼 표시', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tapAt(_blockPos(tester));
    await tester.pumpAndSettle();

    expect(find.text('읽으러 가기'), findsOneWidget);
    expect(find.textContaining('읽음'), findsOneWidget); // "n / m장 읽음"
  });

  testWidgets('읽으러 가기 탭 → 리더 라우트로 이동', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tapAt(_blockPos(tester));
    await tester.pumpAndSettle();

    await tester.tap(find.text('읽으러 가기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('reader-'), findsOneWidget);
  });

  testWidgets('빈 곳 탭 → 선택 해제되어 패널이 사라진다', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tapAt(_blockPos(tester));
    await tester.pumpAndSettle();
    expect(find.text('읽으러 가기'), findsOneWidget);

    await tester.tapAt(const Offset(30, 300)); // 블록·버튼 없는 영역
    await tester.pumpAndSettle();
    expect(find.text('읽으러 가기'), findsNothing);
  });

  testWidgets('패널 X 버튼 → 선택 해제', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tapAt(_blockPos(tester));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('읽으러 가기'), findsNothing);
  });
}
