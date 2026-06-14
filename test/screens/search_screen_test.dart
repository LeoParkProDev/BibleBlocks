import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bible_blocks/providers/bible_text_provider.dart';
import 'package:bible_blocks/services/bible_text_service.dart';
import 'package:bible_blocks/screens/search/search_screen.dart';

class _FakeSearchService extends BibleTextService {
  _FakeSearchService() : super(bundle: rootBundle);

  @override
  Future<List<SearchResult>> search(
    String query, {
    int limit = 300,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(1.0);
    if (query.trim() == '사랑') {
      const text = '하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니';
      final m = BibleTextService.findMatch(text, query)!;
      return [
        SearchResult(
          bookIndex: 42, // 요한복음
          chapter: 3,
          verse: 16,
          text: text,
          matchStart: m.$1,
          matchEnd: m.$2,
        ),
      ];
    }
    return [];
  }
}

Widget _wrap(String? initial) => ProviderScope(
      overrides: [
        bibleTextServiceProvider.overrideWithValue(_FakeSearchService()),
      ],
      child: MaterialApp(home: SearchScreen(initialQuery: initial)),
    );

void main() {
  testWidgets('초기 쿼리로 진입하면 결과가 표시된다', (tester) async {
    await tester.pumpWidget(_wrap('사랑'));
    await tester.pumpAndSettle();

    expect(find.text('검색 결과 1건'), findsOneWidget);
    expect(find.text('요한복음 3:16'), findsOneWidget);
  });

  testWidgets('없는 단어는 결과 없음 안내', (tester) async {
    await tester.pumpWidget(_wrap('블록체인'));
    await tester.pumpAndSettle();

    expect(find.text('검색 결과가 없어요'), findsOneWidget);
  });

  testWidgets('입력 전에는 안내 문구', (tester) async {
    await tester.pumpWidget(_wrap(null));
    await tester.pumpAndSettle();

    expect(find.text('찾고 싶은 단어나 구절을 입력하세요'), findsOneWidget);
  });
}
