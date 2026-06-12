import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/bible_data.dart';
import '../../providers/bible_text_provider.dart';
import '../../providers/reader_prefs_provider.dart';
import '../../services/bible_text_service.dart';
import '../../theme/app_colors.dart';

/// PageView의 한 페이지 = 한 장의 본문. 스크롤 위치를 유지하고,
/// 끝까지 읽으면 [onReachedEnd]를 한 번 호출한다(짧은 장은 즉시).
/// 절을 탭하면 복사/공유 액션시트가 열린다.
class ChapterView extends ConsumerStatefulWidget {
  const ChapterView({
    super.key,
    required this.bookIndex,
    required this.chapter,
    required this.onReachedEnd,
  });

  final int bookIndex;
  final int chapter;
  final VoidCallback onReachedEnd;

  @override
  ConsumerState<ChapterView> createState() => _ChapterViewState();
}

class _ChapterViewState extends ConsumerState<ChapterView>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();
  bool _reported = false;
  int? _selectedVerse;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_reported &&
        _scroll.hasClients &&
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 40) {
      _report();
    }
  }

  void _report() {
    if (_reported) return;
    _reported = true;
    widget.onReachedEnd();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _showVerseActions(BibleVerse v) async {
    final c = ref.read(readerPrefsProvider).theme.colors;
    final book = BibleData.books[widget.bookIndex];
    final citation = '${book.name} ${widget.chapter}:${v.number}';
    final shareText = '"${v.text}"\n\n— $citation (개역한글)';
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _selectedVerse = v.number);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.menu_book,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    citation,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.copy, color: c.text),
              title: Text('복사', style: TextStyle(color: c.text)),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: shareText));
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('구절을 복사했습니다'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: c.text),
              title: Text('공유', style: TextStyle(color: c.text)),
              onTap: () async {
                Navigator.pop(sheetContext);
                try {
                  await SharePlus.instance.share(ShareParams(text: shareText));
                } catch (_) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('공유를 사용할 수 없습니다')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(() => _selectedVerse = null);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final prefs = ref.watch(readerPrefsProvider);
    final c = prefs.theme.colors;
    final textAsync = ref.watch(
      chapterTextProvider((book: widget.bookIndex, chapter: widget.chapter)),
    );

    return textAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: c.text)),
      error: (e, _) => Center(
        child: Text(
          '본문을 불러오지 못했습니다: $e',
          style: TextStyle(color: c.text),
        ),
      ),
      data: (verses) {
        // 스크롤이 필요 없는 짧은 장이면 끝 도달로 간주
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_reported &&
              _scroll.hasClients &&
              _scroll.position.maxScrollExtent <= 0) {
            _report();
          }
        });
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: verses.length + 1,
              itemBuilder: (context, i) {
                if (i == verses.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 28),
                    child: Text(
                      '성경전서 개역한글판 · 대한성서공회',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: c.secondary.withValues(alpha: 0.8),
                      ),
                    ),
                  );
                }
                final v = verses[i];
                final selected = _selectedVerse == v.number;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showVerseActions(v),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.symmetric(
                        vertical: 2, horizontal: 4),
                    decoration: selected
                        ? BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          )
                        : null,
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: '${v.number} ',
                          style: TextStyle(
                            fontSize: prefs.fontSize * 0.62,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        TextSpan(
                          text: v.text,
                          style: TextStyle(
                            fontSize: prefs.fontSize,
                            height: prefs.lineHeight,
                            color: c.text,
                          ),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
