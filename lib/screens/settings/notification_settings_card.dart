import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notification_provider.dart';
import '../../theme/app_colors.dart';

/// 설정 화면의 '오늘의 말씀 알림' 카드. 웹에서는 미지원이라 숨긴다.
class NotificationSettingsCard extends ConsumerWidget {
  const NotificationSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) return const SizedBox.shrink();

    final prefs =
        ref.watch(notificationPrefsProvider).value ?? const NotificationPrefs();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: prefs.enabled,
            secondary: const Icon(Icons.notifications_active,
                color: AppColors.gold),
            title: const Text(
              '오늘의 말씀 알림',
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            subtitle: const Text(
              '매일 정한 시간에 말씀 한 구절을 받아보세요',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            onChanged: (v) => _onToggle(context, ref, v),
          ),
          if (prefs.enabled)
            ListTile(
              leading: const SizedBox(width: 24),
              title: const Text(
                '알림 시간',
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
              trailing: Text(
                prefs.timeLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              onTap: () => _pickTime(context, ref, prefs),
            ),
        ],
      ),
    );
  }

  Future<void> _onToggle(BuildContext context, WidgetRef ref, bool value) async {
    final notifier = ref.read(notificationPrefsProvider.notifier);
    if (!value) {
      await notifier.disable();
      return;
    }

    // 권한 요청 전 가치 우선 프라이머.
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('오늘의 말씀 받기'),
        content: const Text(
          '매일 아침(또는 원하는 시간) 말씀 한 구절을 알림으로 보내드립니다.\n'
          '계속하려면 알림을 허용해 주세요.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('나중에',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('좋아요',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (proceed != true) return;

    final granted = await notifier.enable();
    if (!granted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알림 권한이 필요합니다. 기기 설정에서 알림을 허용해 주세요.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    NotificationPrefs prefs,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: prefs.hour, minute: prefs.minute),
    );
    if (picked != null) {
      await ref
          .read(notificationPrefsProvider.notifier)
          .setTime(picked.hour, picked.minute);
    }
  }
}
