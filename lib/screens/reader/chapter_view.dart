import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/verse_annotation.dart';
import '../../providers/annotation_provider.dart';
import '../../providers/bible_text_provider.dart';
import '../../providers/reader_prefs_provider.dart';
import '../../services/bible_text_service.dart';
import '../../theme/app_colors.dart';
import 'verse_action_sheet.dart';

/// PageView의 한 페이지 = 한 장의 본문. 스크롤 위치를 유지하고,
/// 끝까지 읽으면 [onReachedEnd]를 한 번 호출한다(짧은 장은 즉시).
/// 절을 탭하면 하이라이트·북마크·노트·공유 액션시트가 열린다.
/// [focusVerse]가 주어지면(검색/노트에서 진입) 해당 절로 스크롤하고 잠깐 강조한다.
class ChapterView extends ConsumerStatefulWidget {
  const ChapterView({
    super.key,
    required this.bookIndex,
    required this.chapter,
    required this.onReachedEnd,
    this.focusVerse,
  });

  final int bookIndex;
  final int chapter;
  final VoidCallback onReachedEnd;
  final int? focusVerse;

  @override
  ConsumerState<ChapterView> createState() => _ChapterViewState();
}

class _ChapterViewState extends ConsumerState<ChapterView>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();
  final _focusKey = GlobalKey();
  bool _reported = false;
  bool _focusHandled = false;
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

  /// 검색/노트 진입 시 해당 절로 이동 + 잠깐 강조.
  void _maybeFocusVerse(int verseCount) {
    if (widget.focusVerse == null || _focusHandled || !_scroll.hasClients) {
      return;
    }
    _focusHandled = true;
    // 절 높이가 가변이라 정확한 오프셋을 알 수 없으므로, 대략 점프 후
    // 실제로 빌드된 위젯을 ensureVisible로 정밀 보정한다.
    final estimate = (widget.focusVerse! - 1) * 64.0;
    _scroll.jumpTo(estimate.clamp(0.0, _scroll.position.maxScrollExtent));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _focusKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.25,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      setState(() => _selectedVerse = widget.focusVerse);
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted && _selectedVerse == widget.focusVerse) {
          setState(() => _selectedVerse = null);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final prefs = ref.watch(readerPrefsProvider);
    final c = prefs.theme.colors;
    final textAsync = ref.watch(
      chapterTextProvider((book: widget.bookIndex, chapter: widget.chapter)),
    );
    // 이 장의 주석만 절 번호로 추려둔다.
    final annotations = ref.watch(
      annotationProvider.select((s) => _chapterAnnotations(s.value)),
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // 스크롤이 필요 없는 짧은 장이면 끝 도달로 간주
          if (!_reported &&
              _scroll.hasClients &&
              _scroll.position.maxScrollExtent <= 0) {
            _report();
          }
          _maybeFocusVerse(verses.length);
        });
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              cacheExtent: 1200,
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
                final annotation = annotations[v.number];
                final selected = _selectedVerse == v.number;
                final isFocus = widget.focusVerse == v.number;

                Color? bg;
                if (selected) {
                  bg = AppColors.primary.withValues(alpha: 0.14);
                } else if (annotation?.color != null) {
                  bg = Color(annotation!.color!).withValues(alpha: 0.42);
                }

                return GestureDetector(
                  key: isFocus ? _focusKey : null,
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showVerseActions(v),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    decoration: bg != null
                        ? BoxDecoration(
                            color: bg,
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
                        if (annotation?.bookmarked ?? false)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.bookmark,
                                size: prefs.fontSize * 0.7,
                                color: AppColors.gold,
                              ),
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

  /// 전체 주석 맵에서 현재 (book, chapter)에 해당하는 것만 절 번호→주석으로.
  Map<int, VerseAnnotation> _chapterAnnotations(
    Map<String, VerseAnnotation>? all,
  ) {
    if (all == null) return const {};
    final result = <int, VerseAnnotation>{};
    for (final a in all.values) {
      if (a.bookIndex == widget.bookIndex && a.chapter == widget.chapter) {
        result[a.verse] = a;
      }
    }
    return result;
  }

  Future<void> _showVerseActions(BibleVerse v) async {
    setState(() => _selectedVerse = v.number);
    await VerseActionSheet.show(
      context,
      bookIndex: widget.bookIndex,
      chapter: widget.chapter,
      verse: v.number,
      verseText: v.text,
    );
    if (mounted) setState(() => _selectedVerse = null);
  }
}
