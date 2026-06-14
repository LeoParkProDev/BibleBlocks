import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/bible_data.dart';
import '../../models/verse_annotation.dart';
import '../../providers/annotation_provider.dart';
import '../../providers/reader_prefs_provider.dart';
import '../../theme/app_colors.dart';
import 'verse_share_sheet.dart';

/// 절을 탭하면 열리는 통합 액션 시트.
/// 하이라이트 색 / 북마크 / 노트(주석) + 복사 / 텍스트·이미지 공유.
class VerseActionSheet extends ConsumerWidget {
  const VerseActionSheet({
    super.key,
    required this.bookIndex,
    required this.chapter,
    required this.verse,
    required this.verseText,
  });

  final int bookIndex;
  final int chapter;
  final int verse;
  final String verseText;

  static Future<void> show(
    BuildContext context, {
    required int bookIndex,
    required int chapter,
    required int verse,
    required String verseText,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ProviderScope.containerOf(context, listen: false)
          .read(readerPrefsProvider)
          .theme
          .colors
          .background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => VerseActionSheet(
        bookIndex: bookIndex,
        chapter: chapter,
        verse: verse,
        verseText: verseText,
      ),
    );
  }

  String get _citation =>
      '${BibleData.books[bookIndex].name} $chapter:$verse';

  String get _shareText => '"$verseText"\n\n— $_citation (개역한글)';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(readerPrefsProvider).theme.colors;
    final key = VerseAnnotation.makeKey(bookIndex, chapter, verse);
    final annotation = ref.watch(
      annotationProvider.select((s) => s.value?[key]),
    );
    final notifier = ref.read(annotationProvider.notifier);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.menu_book, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _citation,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 하이라이트 색 팔레트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                for (final color in AnnotationPalette.colors) ...[
                  _Swatch(
                    color: Color(color),
                    selected: annotation?.color == color,
                    onTap: () => notifier.setHighlight(
                      bookIndex,
                      chapter,
                      verse,
                      annotation?.color == color ? null : color,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                _EraserSwatch(
                  active: annotation?.hasHighlight ?? false,
                  onTap: () =>
                      notifier.setHighlight(bookIndex, chapter, verse, null),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              (annotation?.bookmarked ?? false)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: (annotation?.bookmarked ?? false)
                  ? AppColors.gold
                  : c.text,
            ),
            title: Text(
              (annotation?.bookmarked ?? false) ? '북마크 해제' : '북마크',
              style: TextStyle(color: c.text),
            ),
            onTap: () => notifier.toggleBookmark(bookIndex, chapter, verse),
          ),
          ListTile(
            leading: Icon(Icons.sticky_note_2_outlined, color: c.text),
            title: Text(
              (annotation?.hasNote ?? false) ? '노트 편집' : '노트 추가',
              style: TextStyle(color: c.text),
            ),
            subtitle: (annotation?.hasNote ?? false)
                ? Text(
                    annotation!.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.secondary,
                      fontSize: 12,
                    ),
                  )
                : null,
            onTap: () => _editNote(context, notifier, annotation?.note),
          ),
          Divider(height: 1, color: c.secondary.withValues(alpha: 0.2)),
          ListTile(
            leading: Icon(Icons.copy, color: c.text),
            title: Text('복사', style: TextStyle(color: c.text)),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              await Clipboard.setData(ClipboardData(text: _shareText));
              if (navigator.canPop()) navigator.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('구절을 복사했습니다'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.image_outlined, color: c.text),
            title: Text('이미지로 공유', style: TextStyle(color: c.text)),
            onTap: () {
              Navigator.of(context).pop();
              VerseShareSheet.show(
                context,
                verseText: verseText,
                citation: _citation,
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.share, color: c.text),
            title: Text('텍스트로 공유', style: TextStyle(color: c.text)),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              try {
                await SharePlus.instance
                    .share(ShareParams(text: _shareText));
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('공유를 사용할 수 없습니다')),
                );
              }
            },
          ),
          const SizedBox(height: 8),
        ],
        ),
      ),
    );
  }

  Future<void> _editNote(
    BuildContext context,
    AnnotationNotifier notifier,
    String? existing,
  ) async {
    final controller = TextEditingController(text: existing ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('노트 · $_citation', style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: '이 절에 대한 생각을 적어보세요',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('저장',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) {
      await notifier.setNote(bookIndex, chapter, verse, result);
    }
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.textPrimary : Colors.black12,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, size: 18, color: Colors.black54)
            : null,
      ),
    );
  }
}

class _EraserSwatch extends StatelessWidget {
  const _EraserSwatch({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Opacity(
        opacity: active ? 1 : 0.4,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12),
          ),
          child: const Icon(Icons.format_color_reset_outlined, size: 18),
        ),
      ),
    );
  }
}
