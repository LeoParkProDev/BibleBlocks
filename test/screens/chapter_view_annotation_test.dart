import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/models/verse_annotation.dart';
import 'package:bible_blocks/providers/annotation_provider.dart';
import 'package:bible_blocks/providers/bible_text_provider.dart';
import 'package:bible_blocks/services/bible_text_service.dart';
import 'package:bible_blocks/screens/reader/chapter_view.dart';

class _FakeService extends BibleTextService {
  _FakeService() : super(bundle: rootBundle);
  @override
  Future<List<BibleVerse>> loadChapter(int b, int c) async =>
      List.generate(5, (i) => BibleVerse(i + 1, 'verse-text-$i'));
}

class _FakeAnnotation extends AnnotationNotifier {
  _FakeAnnotation(this._data);
  final Map<String, VerseAnnotation> _data;
  @override
  Future<Map<String, VerseAnnotation>> build() async => _data;
}

Widget _wrap(Map<String, VerseAnnotation> annotations) => ProviderScope(
      overrides: [
        bibleTextServiceProvider.overrideWithValue(_FakeService()),
        annotationProvider.overrideWith(() => _FakeAnnotation(annotations)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ChapterView(
            bookIndex: 0,
            chapter: 1,
            onReachedEnd: () {},
          ),
        ),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('하이라이트된 절은 배경색으로 렌더된다', (tester) async {
    const color = 0xFFFFE08A;
    final ann = VerseAnnotation(
      bookIndex: 0,
      chapter: 1,
      verse: 2,
      color: color,
      updatedAt: DateTime(2026, 1, 1),
    );
    await tester.pumpWidget(_wrap({'0:1:2': ann}));
    await tester.pumpAndSettle();

    final expected = const Color(color).withValues(alpha: 0.42);
    final hasHighlightBg = tester.widgetList<Container>(find.byType(Container)).any(
      (ct) {
        final d = ct.decoration;
        return d is BoxDecoration && d.color == expected;
      },
    );
    expect(hasHighlightBg, true);
  });

  testWidgets('북마크된 절은 북마크 아이콘을 본문에 표시한다', (tester) async {
    final ann = VerseAnnotation(
      bookIndex: 0,
      chapter: 1,
      verse: 1,
      bookmarked: true,
      updatedAt: DateTime(2026, 1, 1),
    );
    await tester.pumpWidget(_wrap({'0:1:1': ann}));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('주석이 없으면 하이라이트 배경이 없다', (tester) async {
    await tester.pumpWidget(_wrap({}));
    await tester.pumpAndSettle();

    final anyHighlight = tester.widgetList<Container>(find.byType(Container)).any(
      (ct) {
        final d = ct.decoration;
        if (d is! BoxDecoration || d.color == null) return false;
        // 노란 계열 하이라이트가 없어야 한다
        return d.color == const Color(0xFFFFE08A).withValues(alpha: 0.42);
      },
    );
    expect(anyHighlight, false);
  });
}
