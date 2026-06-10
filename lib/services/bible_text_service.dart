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
}
