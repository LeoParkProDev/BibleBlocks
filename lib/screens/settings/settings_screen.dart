import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bible_data.dart';
import '../../models/bible_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/model_provider.dart';
import '../../providers/progress_provider.dart';
import '../../services/progress_service.dart';
import '../../services/share_service.dart';
import '../../services/share_service_web.dart'
    if (dart.library.io) '../../services/share_service_stub.dart' as platform;
import '../../theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalRead = ref.watch(totalReadProvider);
    final selectedModel = ref.watch(modelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 진행 현황 카드
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.auto_stories,
                      size: 40,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$totalRead / ${BibleData.totalChapters}장 읽음',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalRead >= BibleData.totalChapters
                          ? '성경 완독을 축하합니다!'
                          : '${BibleData.totalChapters - totalRead}장 남았습니다',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 공유하기 버튼
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: const Icon(Icons.share, color: AppColors.gold),
                  title: const Text(
                    '카카오톡으로 공유하기',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    '3D 성경책과 진행도를 친구에게 공유해보세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () => _shareProgress(context, ref),
                ),
              ),

              const SizedBox(height: 24),

              // 3D 모델 선택
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Text(
                        '3D 모델',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    ...BibleModelType.values.map((type) {
                      final isSelected = type == selectedModel;
                      return ListTile(
                        leading: Icon(
                          type.icon,
                          size: 22,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        title: Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          type.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                            : const Icon(Icons.circle_outlined, color: AppColors.border, size: 20),
                        onTap: () => ref.read(modelProvider.notifier).set(type),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 초기화 버튼
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.red),
                  title: const Text(
                    '진행도 초기화',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text(
                    '모든 읽기 기록을 삭제합니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () => _showResetDialog(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareProgress(BuildContext context, WidgetRef ref) async {
    final progressData = ref.read(progressProvider).value ?? {};
    final user = ref.read(authProvider).value;
    final isGuest = ref.read(isGuestProvider);
    final nickname = isGuest ? '게스트' : (user?.nickname ?? '사용자');

    try {
      final totalRead = ProgressService.totalRead(progressData);
      final percent = (totalRead / BibleData.totalChapters * 100).round();

      if (kIsWeb) {
        // 웹: 카카오톡 공유
        platform.shareViaKakao(
          nickname: nickname,
          percent: percent,
          totalRead: totalRead,
          totalChapters: BibleData.totalChapters,
          imageUrl: 'https://bible-blocks-omega.vercel.app/share_card.png?v=5',
          webUrl: 'https://bible-blocks-omega.vercel.app',
        );
      } else {
        // 모바일: 네이티브 공유 시트
        await ShareService.shareProgress(
          progressData: progressData,
          nickname: nickname,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공유 실패: $e')),
        );
      }
    }
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('진행도 초기화'),
        content: const Text('모든 읽기 기록이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              ref.read(progressProvider.notifier).resetAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('초기화되었습니다')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }
}
