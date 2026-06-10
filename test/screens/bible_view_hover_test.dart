import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/providers/progress_provider.dart';
import 'package:bible_blocks/screens/bible_view/bible_view_screen.dart';

class _FakeProgress extends ProgressNotifier {
  @override
  Future<Map<int, Set<int>>> build() async => {
        0: {1, 2, 3},
      };
}

Widget _wrap() => ProviderScope(
      overrides: [progressProvider.overrideWith(_FakeProgress.new)],
      child: const MaterialApp(home: BibleViewScreen()),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('블록뷰(book)에서 마우스 호버 시 예외가 발생하지 않는다', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle(); // 인트로 애니메이션 종료 대기

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();

    // 캔버스 중앙(책 블록 위)으로 호버 이동 — 재귀 버그 시 StackOverflow
    await gesture.moveTo(tester.getCenter(find.byType(InteractiveViewer)));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('블록뷰(book)에서 블록 탭 시 예외 없이 처리된다', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tapAt(tester.getCenter(find.byType(InteractiveViewer)));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
