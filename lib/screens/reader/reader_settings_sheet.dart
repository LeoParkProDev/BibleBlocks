import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/reader_prefs_provider.dart';

/// 리더 읽기 환경(테마·글자 크기·줄 간격) 조절 바텀시트.
class ReaderSettingsSheet extends ConsumerWidget {
  const ReaderSettingsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const ReaderSettingsSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(readerPrefsProvider);
    final notifier = ref.read(readerPrefsProvider.notifier);
    final c = prefs.theme.colors;

    return Container(
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들바
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: c.secondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          _label('글자 크기', c),
          const SizedBox(height: 8),
          Row(
            children: [
              _roundButton(
                icon: Icons.remove,
                color: c,
                onTap: prefs.fontSize > ReaderPrefs.minFont
                    ? notifier.decreaseFont
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Aa  ${prefs.fontSize.round()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                ),
              ),
              _roundButton(
                icon: Icons.add,
                color: c,
                onTap: prefs.fontSize < ReaderPrefs.maxFont
                    ? notifier.increaseFont
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 20),
          _label('줄 간격', c),
          const SizedBox(height: 8),
          Row(
            children: [
              _segment('좁게', 1.5, prefs.lineHeight, c, notifier),
              const SizedBox(width: 8),
              _segment('보통', 1.8, prefs.lineHeight, c, notifier),
              const SizedBox(width: 8),
              _segment('넓게', 2.2, prefs.lineHeight, c, notifier),
            ],
          ),

          const SizedBox(height: 20),
          _label('테마', c),
          const SizedBox(height: 8),
          Row(
            children: ReaderTheme.values.map((t) {
              final selected = t == prefs.theme;
              final tc = t.colors;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => notifier.setTheme(t),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: tc.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFC47B5A)
                              : c.secondary.withValues(alpha: 0.3),
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        t.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: tc.text,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, ReaderThemeColors c) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: c.secondary,
        ),
      );

  Widget _roundButton({
    required IconData icon,
    required ReaderThemeColors color,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 48,
        height: 44,
        decoration: BoxDecoration(
          color: color.secondary.withValues(alpha: enabled ? 0.12 : 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: color.text.withValues(alpha: enabled ? 1 : 0.3),
        ),
      ),
    );
  }

  Widget _segment(
    String label,
    double value,
    double current,
    ReaderThemeColors c,
    ReaderPrefsNotifier notifier,
  ) {
    final selected = (current - value).abs() < 0.01;
    return Expanded(
      child: GestureDetector(
        onTap: () => notifier.setLineHeight(value),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFC47B5A)
                : c.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : c.text,
            ),
          ),
        ),
      ),
    );
  }
}
