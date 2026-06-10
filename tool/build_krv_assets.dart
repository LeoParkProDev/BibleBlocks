// 사용법: dart run tool/build_krv_assets.dart
// tool/getbible_korean.json(getBible v2 "Korean" = 개역성경/개역한글)을
// 책별 assets/bible/krv/{i}.json 으로 변환한다.
//
// 출력 형식: { "book": i, "chapters": [ [ [verseNum, "본문"], ... ], ... ] }
//   - 절 번호를 명시적으로 보존한다(이사야 30:2, 마 18:11 등 판본상 생략/병합된 절이
//     있어 인덱스+1 방식은 번호가 틀어지기 때문).
import 'dart:convert';
import 'dart:io';
import 'package:bible_blocks/data/bible_data.dart';

void main() {
  final src = jsonDecode(File('tool/getbible_korean.json').readAsStringSync())
      as Map<String, dynamic>;
  final books = src['books'] as List;
  if (books.length != BibleData.totalBooks) {
    throw StateError('책 수 ${books.length} != ${BibleData.totalBooks}');
  }

  final outDir = Directory('assets/bible/krv')..createSync(recursive: true);
  var totalVerses = 0;
  for (var i = 0; i < books.length; i++) {
    final chaptersRaw = (books[i] as Map)['chapters'] as List;
    if (chaptersRaw.length != BibleData.books[i].chapters) {
      throw StateError(
          '${BibleData.books[i].name}: ${chaptersRaw.length} != ${BibleData.books[i].chapters}');
    }
    final chapters = chaptersRaw.map((ch) {
      final verses = (ch as Map)['verses'] as List;
      if (verses.isEmpty) {
        throw StateError('${BibleData.books[i].name} 빈 장 발견');
      }
      return verses.map((v) {
        final m = v as Map;
        final num = m['verse'] as int;
        final text = (m['text'] as String).trim();
        if (text.isEmpty) {
          throw StateError('${BibleData.books[i].name} 빈 절($num) 발견');
        }
        totalVerses++;
        return [num, text];
      }).toList();
    }).toList();
    File('${outDir.path}/$i.json')
        .writeAsStringSync(jsonEncode({'book': i, 'chapters': chapters}));
  }
  stdout.writeln('변환 완료: ${books.length}권, 총 $totalVerses절');
}
