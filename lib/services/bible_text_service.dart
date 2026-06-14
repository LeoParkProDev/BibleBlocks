import 'dart:convert';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import '../data/bible_data.dart';

/// 한 절: 판본상의 절 번호와 본문.
///
/// 번호를 보존하는 이유: 개역 판본은 일부 절을 병합/생략한다
/// (예: 이사야 30:1-2 병합, 마 18:11 생략). 인덱스+1로 표시하면
/// 그런 장에서 절 번호가 틀어진다.
class BibleVerse {
  const BibleVerse(this.number, this.text);
  final int number;
  final String text;
}

/// 본문 검색 결과 한 건. [matchStart]~[matchEnd]는 [text] 내 매칭 범위.
class SearchResult {
  const SearchResult({
    required this.bookIndex,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.matchStart,
    required this.matchEnd,
  });

  final int bookIndex;
  final int chapter;
  final int verse;
  final String text;
  final int matchStart;
  final int matchEnd;
}

/// 개역한글 본문을 책 단위로 lazy load + 메모리 캐시한다.
class BibleTextService {
  BibleTextService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  final Map<int, List<List<BibleVerse>>> _cache = {};

  /// 책 전체를 [장][절] 형태로 반환.
  Future<List<List<BibleVerse>>> loadBook(int bookIndex) async {
    if (bookIndex < 0 || bookIndex >= BibleData.totalBooks) {
      throw RangeError.range(bookIndex, 0, BibleData.totalBooks - 1, 'bookIndex');
    }
    final cached = _cache[bookIndex];
    if (cached != null) return cached;

    final raw = await _bundle.loadString('assets/bible/krv/$bookIndex.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final chapters = (json['chapters'] as List).map((c) {
      return (c as List).map((v) {
        final pair = v as List;
        return BibleVerse(pair[0] as int, pair[1] as String);
      }).toList();
    }).toList();
    _cache[bookIndex] = chapters;
    return chapters;
  }

  /// 1-기반 장 번호의 절 목록 반환.
  Future<List<BibleVerse>> loadChapter(int bookIndex, int chapter) async {
    final book = await loadBook(bookIndex);
    if (chapter < 1 || chapter > book.length) {
      throw RangeError.range(chapter, 1, book.length, 'chapter');
    }
    return book[chapter - 1];
  }

  /// 한 절 [text]에서 [query] 매칭 범위를 찾는다(부분일치 + 공백 무시).
  ///
  /// 1) 원문 부분일치 우선(범위 정확). 2) 실패 시 공백을 제거한 압축본에서
  /// 다시 찾고, 압축 인덱스를 원문 인덱스로 되돌려 범위를 복원한다.
  /// 매칭 없으면 null.
  static (int start, int end)? findMatch(String text, String query) {
    final raw = query.trim();
    if (raw.isEmpty) return null;

    final direct = text.indexOf(raw);
    if (direct >= 0) return (direct, direct + raw.length);

    final q = raw.replaceAll(RegExp(r'\s+'), '');
    if (q.isEmpty) return null;

    final buf = StringBuffer();
    final map = <int>[]; // 압축 인덱스 → 원문 인덱스
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch.trim().isEmpty) continue; // 공백류 제거
      buf.write(ch);
      map.add(i);
    }
    final ci = buf.toString().indexOf(q);
    if (ci < 0) return null;
    return (map[ci], map[ci + q.length - 1] + 1);
  }

  /// 전 책을 스캔해 [query]에 매칭되는 절을 [limit]건까지 반환.
  ///
  /// 최초 호출은 66개 책을 lazy load하므로(이후 캐시) 느릴 수 있다.
  /// 책 단위로 이벤트 루프에 양보(`Future.delayed(Duration.zero)`)해
  /// UI 프레임 드랍을 막고, [onProgress]로 0.0~1.0 진행률을 알린다.
  Future<List<SearchResult>> search(
    String query, {
    int limit = 300,
    void Function(double progress)? onProgress,
  }) async {
    final results = <SearchResult>[];
    final raw = query.trim();
    if (raw.isEmpty) return results;

    for (var b = 0; b < BibleData.totalBooks; b++) {
      final book = await loadBook(b);
      for (var c = 0; c < book.length; c++) {
        for (final v in book[c]) {
          final m = findMatch(v.text, raw);
          if (m != null) {
            results.add(SearchResult(
              bookIndex: b,
              chapter: c + 1,
              verse: v.number,
              text: v.text,
              matchStart: m.$1,
              matchEnd: m.$2,
            ));
            if (results.length >= limit) {
              onProgress?.call(1.0);
              return results;
            }
          }
        }
      }
      onProgress?.call((b + 1) / BibleData.totalBooks);
      await Future<void>.delayed(Duration.zero); // 프레임 양보
    }
    return results;
  }
}
