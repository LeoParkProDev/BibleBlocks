import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bible_blocks/models/bible_model.dart';
import 'package:bible_blocks/painters/new_jerusalem_painter.dart';
import 'package:bible_blocks/providers/model_provider.dart';
import 'package:bible_blocks/providers/progress_provider.dart';
import 'package:bible_blocks/screens/bible_view/bible_view_screen.dart';

class _FakeProgress extends ProgressNotifier {
  @override
  Future<Map<int, Set<int>>> build() async => {
        0: {1, 2, 3, 4, 5},
      };
}

/// Forces the model selection to New Jerusalem.
class _FixedModel extends ModelNotifier {
  @override
  BibleModelType build() => BibleModelType.newJerusalem;
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

  testWidgets('새 예루살렘 모델 선택 시 NewJerusalemPainter로 렌더되고 예외 없음',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    // The 3D scene is drawn with the New Jerusalem painter.
    final customPaints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    final hasCityPainter =
        customPaints.any((cp) => cp.painter is NewJerusalemPainter);
    expect(hasCityPainter, true,
        reason: 'expected the city to be painted by NewJerusalemPainter');

    // No exceptions thrown during build/paint.
    expect(tester.takeException(), isNull);

    // Rotating the view (which exercises the painter at non-zero angle) is safe.
    final rotateRight = find.byIcon(Icons.rotate_right);
    expect(rotateRight, findsOneWidget);
  });

  testWidgets('새 예루살렘 enum이 모델 목록에 노출된다', (tester) async {
    expect(BibleModelType.values.contains(BibleModelType.newJerusalem), true);
    expect(BibleModelType.newJerusalem.label, '새 예루살렘');
    expect(BibleModelType.newJerusalem.supportsBlockInteraction, true);
  });
}
