import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kBook = 'last_book';
const _kChapter = 'last_chapter';

/// 마지막으로 읽던 (책, 장). 리더를 열 때마다 갱신되고 기기에 저장된다.
final lastPositionProvider =
    NotifierProvider<LastPositionNotifier, ({int book, int chapter})?>(
        LastPositionNotifier.new);

class LastPositionNotifier extends Notifier<({int book, int chapter})?> {
  @override
  ({int book, int chapter})? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final book = p.getInt(_kBook);
      final chapter = p.getInt(_kChapter);
      if (book != null && chapter != null) {
        state = (book: book, chapter: chapter);
      }
    } catch (_) {
      // 저장값 없으면 null 유지
    }
  }

  Future<void> set(int book, int chapter) async {
    state = (book: book, chapter: chapter);
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kBook, book);
    await p.setInt(_kChapter, chapter);
  }
}
