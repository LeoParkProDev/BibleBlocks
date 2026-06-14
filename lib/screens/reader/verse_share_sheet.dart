import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/verse_image_service.dart';
import '../../theme/app_colors.dart';

/// 절을 이미지 카드로 공유하기 전, 배경 테마를 고르고 미리보는 시트.
/// 미리보기는 실제 공유에 쓰는 렌더러([VerseImageService.renderVerseCard])로
/// 그려 WYSIWYG를 보장한다.
class VerseShareSheet extends StatefulWidget {
  const VerseShareSheet({
    super.key,
    required this.verseText,
    required this.citation,
  });

  final String verseText;
  final String citation;

  static Future<void> show(
    BuildContext context, {
    required String verseText,
    required String citation,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => VerseShareSheet(
        verseText: verseText,
        citation: citation,
      ),
    );
  }

  @override
  State<VerseShareSheet> createState() => _VerseShareSheetState();
}

class _VerseShareSheetState extends State<VerseShareSheet> {
  VerseCardTheme _theme = VerseCardTheme.deepWine;
  bool _sharing = false;

  Future<Uint8List> _preview(VerseCardTheme theme) {
    return VerseImageService.renderVerseCard(
      verseText: widget.verseText,
      citation: widget.citation,
      theme: theme,
    );
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await VerseImageService.shareVerseCard(
        verseText: widget.verseText,
        citation: widget.citation,
        theme: _theme,
      );
      if (navigator.canPop()) navigator.pop();
    } catch (_) {
      if (mounted) setState(() => _sharing = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('이미지 공유를 사용할 수 없습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '이미지로 공유',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            // 정사각 미리보기
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: FutureBuilder<Uint8List>(
                    future: _preview(_theme),
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done ||
                          !snap.hasData) {
                        return Container(
                          color: AppColors.background,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }
                      return Image.memory(snap.data!, fit: BoxFit.cover);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 테마 선택
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final theme in VerseCardTheme.values) ...[
                  _ThemeChip(
                    label: VerseImageService.themeLabel(theme),
                    selected: theme == _theme,
                    onTap: () => setState(() => _theme = theme),
                  ),
                  if (theme != VerseCardTheme.values.last)
                    const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sharing ? null : _share,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.ios_share, size: 18),
                label: Text(_sharing ? '준비 중…' : '이미지 공유'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
