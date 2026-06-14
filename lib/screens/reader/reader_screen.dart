import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/bible_data.dart';
import '../../providers/last_position_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/reader_prefs_provider.dart';
import '../../theme/app_colors.dart';
import 'book_chapter_picker.dart';
import 'chapter_view.dart';
import 'reader_settings_sheet.dart';

/// 개역한글 본문 리더. 좌우 스와이프로 장 이동(유버전식),
/// 스크롤을 내리면 헤더가 숨고(몰입), 끝까지 읽으면 '읽음 완료' 버튼이 등장한다.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.bookIndex,
    required this.chapter,
    this.focusVerse,
  });

  final int bookIndex;
  final int chapter;

  /// 검색/노트에서 진입 시 강조·스크롤할 절(1-based). 없으면 일반 진입.
  final int? focusVerse;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  late final int _initialIndex;
  final Set<int> _reachedEnds = {};
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex =
        BibleData.chapterOffset(widget.bookIndex) + (widget.chapter - 1);
    _initialIndex = _currentIndex;
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) => _savePosition());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _savePosition() {
    if (!mounted) return;
    final (b, ch) = BibleData.fromGlobalIndex(_currentIndex);
    ref.read(lastPositionProvider.notifier).set(b, ch);
  }

  void _goToPage(int index) {
    if (index < 0 || index >= BibleData.totalChapters) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openPicker() async {
    final (curBook, _) = BibleData.fromGlobalIndex(_currentIndex);
    final result =
        await BookChapterPicker.show(context, currentBook: curBook);
    if (result == null || !mounted) return;
    final index = BibleData.chapterOffset(result.$1) + (result.$2 - 1);
    _pageController.jumpToPage(index);
    setState(() => _currentIndex = index);
    _savePosition();
  }

  /// 헤더용 컴팩트 아이콘 버튼 (기본 48px → 40px, 좁은 화면 공간 확보)
  Widget _headerIcon({
    required String tooltip,
    required Widget icon,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      icon: icon,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
    );
  }

  void _onUserScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return;
    if (n.direction == ScrollDirection.reverse && _chromeVisible) {
      setState(() => _chromeVisible = false);
    } else if (n.direction == ScrollDirection.forward && !_chromeVisible) {
      setState(() => _chromeVisible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(readerPrefsProvider);
    final c = prefs.theme.colors;
    final (curBook, curChapter) = BibleData.fromGlobalIndex(_currentIndex);
    final book = BibleData.books[curBook];
    final isRead = (ref.watch(progressProvider).value ??
                const <int, Set<int>>{})[curBook]
            ?.contains(curChapter) ??
        false;
    final showButton =
        (_reachedEnds.contains(_currentIndex) || isRead) && _chromeVisible;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // 몰입형 헤더: 아래로 스크롤하면 숨고 위로 올리면 나타난다
            AnimatedContainer(
              key: const ValueKey('reader-header'),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: _chromeVisible ? kToolbarHeight : 0,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(color: c.background),
              child: OverflowBox(
                minHeight: kToolbarHeight,
                maxHeight: kToolbarHeight,
                alignment: Alignment.bottomCenter,
                child: Builder(builder: (context) {
                  // 좁은 화면(모바일)에서는 제목이 잘리지 않도록
                  // 화살표를 숨긴다 — 장 이동은 스와이프로 가능.
                  final compact = MediaQuery.sizeOf(context).width < 400;
                  return Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        _headerIcon(
                          tooltip: '뒤로',
                          icon: Icon(Icons.arrow_back, color: c.text),
                          onPressed: () => Navigator.of(context).maybePop(),
                        )
                      else
                        const SizedBox(width: 8),
                      Flexible(
                        child: InkWell(
                          onTap: _openPicker,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    '${book.name} $curChapter장',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: c.text,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.expand_more,
                                    size: 18, color: c.text),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      _headerIcon(
                        tooltip: '본문 검색',
                        icon: Icon(Icons.search, color: c.text),
                        onPressed: () => context.push('/search'),
                      ),
                      _headerIcon(
                        tooltip: '읽기 설정',
                        icon: Icon(Icons.text_fields, color: c.text),
                        onPressed: () => ReaderSettingsSheet.show(context),
                      ),
                      if (!compact) ...[
                        _headerIcon(
                          tooltip: '이전 장',
                          icon: Icon(
                            Icons.chevron_left,
                            color: _currentIndex > 0
                                ? c.text
                                : c.secondary.withValues(alpha: 0.4),
                          ),
                          onPressed: _currentIndex > 0
                              ? () => _goToPage(_currentIndex - 1)
                              : null,
                        ),
                        _headerIcon(
                          tooltip: '다음 장',
                          icon: Icon(
                            Icons.chevron_right,
                            color: _currentIndex < BibleData.totalChapters - 1
                                ? c.text
                                : c.secondary.withValues(alpha: 0.4),
                          ),
                          onPressed:
                              _currentIndex < BibleData.totalChapters - 1
                                  ? () => _goToPage(_currentIndex + 1)
                                  : null,
                        ),
                      ],
                    ],
                  );
                }),
              ),
            ),
            Expanded(
              child: NotificationListener<UserScrollNotification>(
                onNotification: (n) {
                  _onUserScroll(n);
                  return false;
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: BibleData.totalChapters,
                  onPageChanged: (i) {
                    setState(() => _currentIndex = i);
                    _savePosition();
                  },
                  itemBuilder: (context, i) {
                    final (b, ch) = BibleData.fromGlobalIndex(i);
                    return ChapterView(
                      key: ValueKey(i),
                      bookIndex: b,
                      chapter: ch,
                      focusVerse: i == _initialIndex ? widget.focusVerse : null,
                      onReachedEnd: () {
                        if (mounted) {
                          setState(() {
                            _reachedEnds.add(i);
                            _chromeVisible = true;
                          });
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showButton
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton(
                  onPressed: () {
                    ref
                        .read(progressProvider.notifier)
                        .toggleChapter(curBook, curChapter);
                    if (!isRead) _goToPage(_currentIndex + 1);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isRead ? AppColors.textSecondary : AppColors.primary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(isRead ? '✓ 읽음 · 탭하여 해제' : '✓ 이 장 읽음 완료'),
                ),
              ),
            )
          : null,
    );
  }
}
