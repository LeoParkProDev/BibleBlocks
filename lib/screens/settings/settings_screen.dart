import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bible_data.dart';
import '../../l10n/l10n.dart';
import '../../models/bible_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/model_provider.dart';
import '../../providers/progress_provider.dart';
import '../../services/donation_service.dart';
import '../../services/progress_service.dart';
import '../../services/share_service.dart';
import '../../services/share_service_web.dart'
    if (dart.library.io) '../../services/share_service_stub.dart' as platform;
import '../../theme/app_colors.dart';
import 'donation_sheet.dart';
import 'notification_settings_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalRead = ref.watch(totalReadProvider);
    final selectedModel = ref.watch(modelProvider);
    final t = context.l10n;
    _listenDonationPhase(context, ref);

    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
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
                  title: Text(
                    t.settingsShareTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    t.settingsShareSubtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () => _shareProgress(context, ref),
                ),
              ),

              const SizedBox(height: 24),

              // 오늘의 말씀 알림
              const NotificationSettingsCard(),

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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Text(
                        t.settingsModelTitle,
                        style: const TextStyle(
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
                  title: Text(
                    t.settingsResetTitle,
                    style: const TextStyle(color: Colors.red),
                  ),
                  subtitle: Text(
                    t.settingsResetSubtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () => _showResetDialog(context, ref),
                ),
              ),

              const SizedBox(height: 12),

              // 개발자 후원하기 (IAP — 웹은 스토어 결제가 없어 숨김)
              if (!kIsWeb) ...[
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.favorite, color: AppColors.gold),
                    title: Text(
                      t.settingsDonateTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      t.settingsDonateSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onTap: () => _openDonationSheet(context),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 성경 본문 출처 (개역한글 성명표시권 준수)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: const Icon(Icons.menu_book,
                      color: AppColors.textSecondary),
                  title: Text(
                    t.settingsSourceTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    '성경전서 개역한글판 · 대한성서공회 (1961)\n저작권이 만료된 퍼블릭 도메인 본문을 사용합니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 언어 선택 (최하단)
              _languageCard(context, ref, t),
            ],
          ),
        ),
      ),
    );
  }

  /// 언어 선택 카드 — 한국어 / English / 시스템 기본.
  Widget _languageCard(BuildContext context, WidgetRef ref, AppLocalizations t) {
    final current = ref.watch(localeProvider).value;
    final selected = current?.languageCode; // null = 시스템 기본

    Widget tile(String label, String? code) {
      final isSelected = selected == code;
      return ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
            : const Icon(Icons.circle_outlined,
                color: AppColors.border, size: 20),
        onTap: () => ref
            .read(localeProvider.notifier)
            .setLocale(code == null ? null : Locale(code)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.language, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  t.settingsLanguage,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(44, 2, 16, 4),
            child: Text(
              t.settingsLanguageSubtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          tile(t.languageKorean, 'ko'),
          tile(t.languageEnglish, 'en'),
          tile(t.languageSystem, null),
        ],
      ),
    );
  }

  Future<void> _shareProgress(BuildContext context, WidgetRef ref) async {
    final progressData = ref.read(progressProvider).value ?? {};
    final user = ref.read(authProvider).value;
    final isGuest = ref.read(isGuestProvider).value ?? false;
    final nickname = isGuest ? '게스트' : (user?.nickname ?? '사용자');

    final totalRead = ProgressService.totalRead(progressData);
    final percent = (totalRead / BibleData.totalChapters * 100).round();

    try {
      if (kIsWeb) {
        platform.shareViaKakao(
          nickname: nickname,
          percent: percent,
          totalRead: totalRead,
          totalChapters: BibleData.totalChapters,
          imageUrl: 'https://bible-blocks-omega.vercel.app/share_card.png?v=5',
          webUrl: 'https://bible-blocks-omega.vercel.app',
        );
      } else {
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

  /// 구매 단계 변화 감지 — 성공 시 감사 다이얼로그, 실패 시 스낵바.
  void _listenDonationPhase(BuildContext context, WidgetRef ref) {
    ref.listen<DonationPhase>(donationPhaseProvider, (previous, next) {
      final notifier = ref.read(donationPhaseProvider.notifier);
      switch (next) {
        case DonationPhase.success:
          notifier.reset();
          _showThanksDialog(context);
        case DonationPhase.error:
          notifier.reset();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('결제를 완료하지 못했습니다')),
          );
        case DonationPhase.canceled:
          notifier.reset();
        case DonationPhase.idle:
        case DonationPhase.pending:
          break;
      }
    });
  }

  void _openDonationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const DonationSheet(),
    );
  }

  void _showThanksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.favorite, color: AppColors.gold),
            SizedBox(width: 8),
            Expanded(child: Text('후원 감사합니다!', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: const Text('보내주신 소중한 마음이\n더 나은 BibleBlocks를 만드는 데 쓰입니다 🙏'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
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
