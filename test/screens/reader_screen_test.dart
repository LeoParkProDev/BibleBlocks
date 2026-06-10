import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/services/bible_text_service.dart';
import 'package:bible_blocks/providers/bible_text_provider.dart';
import 'package:bible_blocks/providers/progress_provider.dart';
import 'package:bible_blocks/screens/reader/reader_screen.dart';

class _FakeService extends BibleTextService {
  _FakeService() : super(bundle: rootBundle);
  @override
  Future<List<BibleVerse>> loadChapter(int b, int c) async =>
      List.generate(40, (i) => BibleVerse(i + 1, 'verse-text-$i'));
}

/// 읽음 상태를 제어 가능한 가짜 progress notifier.
class _FakeProgress extends ProgressNotifier {
  _FakeProgress(this._data);
  final Map<int, Set<int>> _data;
  @override
  Future<Map<int, Set<int>>> build() async => _data;
  @override
  Future<void> toggleChapter(int b, int c) async {
    final set = _data.putIfAbsent(b, () => <int>{});
    set.contains(c) ? set.remove(c) : set.add(c);
    state = AsyncValue.data({..._data});
  }
}

Widget _wrap(Map<int, Set<int>> initial) => ProviderScope(
      overrides: [
        bibleTextServiceProvider.overrideWithValue(_FakeService()),
        progressProvider.overrideWith(() => _FakeProgress(initial)),
      ],
      child: const MaterialApp(home: ReaderScreen(bookIndex: 0, chapter: 1)),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('본문 절(번호+본문)이 렌더된다', (tester) async {
    await tester.pumpWidget(_wrap({}));
    await tester.pumpAndSettle();
    expect(find.textContaining('verse-text-0'), findsOneWidget);
  });

  testWidgets('처음엔 읽음 버튼이 없고, 끝까지 스크롤하면 등장', (tester) async {
    await tester.pumpWidget(_wrap({}));
    await tester.pumpAndSettle();
    expect(find.text('✓ 이 장 읽음 완료'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('✓ 이 장 읽음 완료'), findsOneWidget);
  });

  testWidgets('이미 읽은 장은 해제 버튼이 즉시 표시', (tester) async {
    await tester.pumpWidget(_wrap({
      0: {1},
    }));
    await tester.pumpAndSettle();
    expect(find.text('✓ 읽음 · 탭하여 해제'), findsOneWidget);
  });

  testWidgets('좌우 스와이프로 다음 장(창세기 2장)으로 이동한다', (tester) async {
    await tester.pumpWidget(_wrap({}));
    await tester.pumpAndSettle();
    expect(find.text('창세기 1장'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('창세기 2장'), findsOneWidget);
  });

  testWidgets('Aa 버튼으로 읽기 설정 시트가 열린다', (tester) async {
    await tester.pumpWidget(_wrap({}));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.text_fields));
    await tester.pumpAndSettle();

    expect(find.text('글자 크기'), findsOneWidget);
    expect(find.text('세피아'), findsOneWidget);
  });

  testWidgets('절을 탭하면 복사/공유 액션시트가 열린다', (tester) async {
    await tester.pumpWidget(_wrap({}));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('verse-text-0'));
    await tester.pumpAndSettle();

    expect(find.text('복사'), findsOneWidget);
    expect(find.text('공유'), findsOneWidget);
  });

  testWidgets('좁은 화면: 긴 책 이름 제목이 잘리지 않도록 화살표 숨김', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        bibleTextServiceProvider.overrideWithValue(_FakeService()),
        progressProvider.overrideWith(() => _FakeProgress({})),
      ],
      child: const MaterialApp(
        home: ReaderScreen(bookIndex: 52, chapter: 3), // 데살로니가후서
      ),
    ));
    await tester.pumpAndSettle();

    // 화살표 숨김 (스와이프로 이동), 제목은 온전히 표시
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.text('데살로니가후서 3장'), findsOneWidget);
  });

  testWidgets('넓은 화면: 이전/다음 화살표 표시', (tester) async {
    await tester.pumpWidget(_wrap({}));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('아래로 스크롤하면 헤더가 숨고, 위로 올리면 다시 나타난다', (tester) async {
    await tester.pumpWidget(_wrap({}));
    await tester.pumpAndSettle();

    final header = find.byKey(const ValueKey('reader-header'));
    expect(tester.getSize(header).height, greaterThan(0));

    // 아래로 스크롤 (본문 내려읽기) → 헤더 숨김
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.getSize(header).height, 0);

    // 위로 스크롤 → 헤더 복귀
    await tester.drag(find.byType(ListView), const Offset(0, 100));
    await tester.pumpAndSettle();
    expect(tester.getSize(header).height, greaterThan(0));
  });

  testWidgets('제목 탭 → 목차 피커에서 장을 골라 점프한다', (tester) async {
    await tester.pumpWidget(_wrap({}));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();
    expect(find.text('성경 목차'), findsOneWidget);

    // 창세기(기본 펼침)의 장 그리드에서 5장 선택
    final ch5 = find.descendant(
      of: find.byType(GridView),
      matching: find.text('5'),
    );
    await tester.tap(ch5.first);
    await tester.pumpAndSettle();

    expect(find.text('창세기 5장'), findsOneWidget);
  });
}
