import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bible_data.dart';
import '../../providers/reader_prefs_provider.dart';

/// 책 → 장을 골라 바로 이동하는 피커(유버전식 빠른 점프).
/// 선택 시 (bookIndex, chapter)를 반환한다.
class BookChapterPicker extends ConsumerStatefulWidget {
  const BookChapterPicker({super.key, required this.currentBook});

  final int currentBook;

  static Future<(int, int)?> show(
    BuildContext context, {
    required int currentBook,
  }) {
    return showModalBottomSheet<(int, int)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookChapterPicker(currentBook: currentBook),
    );
  }

  @override
  ConsumerState<BookChapterPicker> createState() => _BookChapterPickerState();
}

class _BookChapterPickerState extends ConsumerState<BookChapterPicker> {
  late int _expandedBook;

  @override
  void initState() {
    super.initState();
    _expandedBook = widget.currentBook;
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(readerPrefsProvider).theme.colors;

    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Container(
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.secondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Text(
                    '성경 목차',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: c.secondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: BibleData.totalBooks,
                itemBuilder: (context, i) {
                  final book = BibleData.books[i];
                  final expanded = _expandedBook == i;
                  return Column(
                    children: [
                      ListTile(
                        dense: true,
                        title: Text(
                          book.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                expanded ? FontWeight.w700 : FontWeight.w500,
                            color: c.text,
                          ),
                        ),
                        trailing: Text(
                          '${book.chapters}장',
                          style: TextStyle(fontSize: 12, color: c.secondary),
                        ),
                        onTap: () => setState(
                            () => _expandedBook = expanded ? -1 : i),
                      ),
                      if (expanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: _chapterGrid(book, c),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chapterGrid(BibleBook book, ReaderThemeColors c) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: book.chapters,
      itemBuilder: (context, i) {
        final chapter = i + 1;
        return GestureDetector(
          onTap: () => Navigator.pop(context, (book.index, chapter)),
          child: Container(
            decoration: BoxDecoration(
              color: c.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$chapter',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
          ),
        );
      },
    );
  }
}
