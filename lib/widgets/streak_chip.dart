import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/streak_state.dart';
import '../providers/streak_provider.dart';
import '../theme/app_colors.dart';

/// 헤더에 놓이는 연속 읽기(스트릭) 칩. 탭하면 상세 시트가 열린다.
class StreakChip extends ConsumerWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider).value ?? const StreakState();
    final active = streak.isActiveToday;
    final hasStreak = streak.current > 0;

    return GestureDetector(
      onTap: () => StreakSheet.show(context, streak),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.goldLight : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.gold : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasStreak
                  ? Icons.local_fire_department
                  : Icons.local_fire_department_outlined,
              size: 18,
              color: hasStreak ? AppColors.gold : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              hasStreak ? '${streak.current}일' : '오늘 시작',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    hasStreak ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 스트릭 상세 바텀시트.
class StreakSheet {
  static void show(BuildContext context, StreakState streak) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StreakSheetBody(streak: streak),
    );
  }
}

class _StreakSheetBody extends StatelessWidget {
  const _StreakSheetBody({required this.streak});

  final StreakState streak;

  String get _message {
    if (streak.current == 0) {
      return '오늘 한 장으로 다시 시작해요.';
    }
    if (streak.isActiveToday) {
      return '오늘도 읽었어요! ${streak.current}일째 이어가는 중이에요.';
    }
    return '어제까지 ${streak.current}일 — 오늘 한 장이면 이어집니다.';
  }

  @override
  Widget build(BuildContext context) {
    final lit = streak.current > 0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              lit
                  ? Icons.local_fire_department
                  : Icons.local_fire_department_outlined,
              size: 56,
              color: lit ? AppColors.gold : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              '${streak.current}일 연속',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('현재', '${streak.current}일'),
                  Container(width: 1, height: 32, color: AppColors.border),
                  _stat('최장', '${streak.longest}일'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.favorite_outline,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '하루는 쉬어도 이어집니다. 이틀 연속 쉬면 다시 시작해요.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
