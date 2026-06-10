import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bible_blocks/data/bible_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Map<String, dynamic>> loadBook(int i) async {
    final raw = await rootBundle.loadString('assets/bible/krv/$i.json');
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  test('66권이 모두 존재하고 총 1189장', () async {
    var totalChapters = 0;
    for (var i = 0; i < BibleData.totalBooks; i++) {
      final chapters = (await loadBook(i))['chapters'] as List;
      expect(chapters.length, BibleData.books[i].chapters,
          reason: '${BibleData.books[i].name} 장수 불일치');
      totalChapters += chapters.length;
    }
    expect(totalChapters, BibleData.totalChapters); // 1189
  });

  test('빈 장이 없고, 모든 절은 [번호, 본문] 형식이며 본문이 비어있지 않다', () async {
    var totalVerses = 0;
    for (var i = 0; i < BibleData.totalBooks; i++) {
      final chapters = (await loadBook(i))['chapters'] as List;
      for (final ch in chapters) {
        expect((ch as List).isNotEmpty, true,
            reason: '${BibleData.books[i].name} 빈 장');
        for (final v in ch) {
          final pair = v as List;
          expect(pair.length, 2); // [번호, 본문]
          expect(pair[0] is int, true);
          expect((pair[1] as String).trim().isNotEmpty, true);
          totalVerses++;
        }
      }
    }
    // 회귀 방지: getBible 개역성경 총 절수 고정
    expect(totalVerses, 31084);
  });

  test('개역한글 식별: 창 1:2는 개역한글 표현이어야 한다', () async {
    final gen = await loadBook(0);
    final v2 = ((gen['chapters'] as List)[0] as List)[1] as List;
    final text = v2[1] as String;
    expect(v2[0], 2); // 절 번호 = 2
    expect(text.contains('신'), true); // 개역한글 "하나님의 신"
    expect(text.contains('수면에'), true); // 개역한글 "수면에"
    expect(text.contains('하나님의 영'), false); // 개역개정 표현 아님
  });
}
