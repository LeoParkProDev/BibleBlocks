import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bible_blocks/models/bible_model.dart';
import 'package:bible_blocks/painters/psalm_tree_painter.dart';
import 'package:bible_blocks/providers/model_provider.dart';
import 'package:bible_blocks/providers/progress_provider.dart';
import 'package:bible_blocks/screens/bible_view/bible_view_screen.dart';

class _FakeProgress extends ProgressNotifier {
  @override
  Future<Map<int, Set<int>>> build() async => {
        0: {1, 2, 3, 4, 5},
      };
}

/// Forces the model selection to the Psalm Tree.
class _FixedModel extends ModelNotifier {
  @override
  BibleModelType build() => BibleModelType.psalmTree;
}

Widget _wrap() {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, state) => const BibleViewScreen()),
    GoRoute(
      path: '/reader/:book/:chapter',
      builder: (_, state) => const Scaffold(body: Text('reader')),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, state) => const Scaffold(body: Text('settings')),
    ),
  ]);
  return ProviderScope(
    overrides: [
      progressProvider.overrideWith(_FakeProgress.new),
      modelProvider.overrideWith(_FixedModel.new),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('시냇가의 나무 모델 선택 시 PsalmTreePainter로 렌더되고 예외 없음',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    final customPaints =
        tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    final hasTreePainter =
        customPaints.any((cp) => cp.painter is PsalmTreePainter);
    expect(hasTreePainter, true,
        reason: 'expected the tree to be painted by PsalmTreePainter');

    expect(tester.takeException(), isNull);

    // Block interaction is supported, so the rotate controls are present.
    expect(find.byIcon(Icons.rotate_right), findsOneWidget);
  });

  testWidgets('시냇가의 나무 enum이 모델 목록에 노출된다', (tester) async {
    expect(BibleModelType.values.contains(BibleModelType.psalmTree), true);
    expect(BibleModelType.psalmTree.label, '시냇가의 나무');
    expect(BibleModelType.psalmTree.description,
        '시편 1편 — 읽을수록 내 나무가 자랍니다');
    expect(BibleModelType.psalmTree.supportsBlockInteraction, true);
  });
}
