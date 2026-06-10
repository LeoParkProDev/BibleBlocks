import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bible_text_service.dart';

final bibleTextServiceProvider =
    Provider<BibleTextService>((ref) => BibleTextService());

/// (book, chapter) → 절 목록 (번호+본문)
final chapterTextProvider =
    FutureProvider.family<List<BibleVerse>, ({int book, int chapter})>(
        (ref, key) {
  return ref.watch(bibleTextServiceProvider).loadChapter(key.book, key.chapter);
});
