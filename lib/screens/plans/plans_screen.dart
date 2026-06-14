import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/reading_plans.dart';
import '../../providers/plan_provider.dart';
import '../../providers/progress_provider.dart';
import '../../services/plan_status.dart';
import '../../theme/app_colors.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePlan = ref.watch(activePlanDefinitionProvider);
    final status = ref.watch(activePlanStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('읽기 계획')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              if (activePlan != null && status != null) ...[
                _ActivePlanCard(plan: activePlan, status: status),
                const SizedBox(height: 24),
                const Text(
                  '다른 계획 둘러보기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
              ] else ...[
                const _PlansIntro(),
                const SizedBox(height: 8),
              ],
              for (final plan in ReadingPlans.all)
                if (plan.id != activePlan?.id)
                  _PlanCatalogTile(plan: plan, hasActivePlan: activePlan != null),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlansIntro extends StatelessWidget {
  const _PlansIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '오늘부터 한 걸음',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '짧은 계획부터 시작해 보세요. 하루 분량을 읽으면 3D 책의 블록이 채워지고 연속 기록도 이어집니다.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ActivePlanCard extends ConsumerWidget {
  const _ActivePlanCard({required this.plan, required this.status});

  final ReadingPlan plan;
  final PlanStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = status.currentDay;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${status.completedDays} / ${status.totalDays}일 완료',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _menuButton(context, ref),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: status.progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
          const SizedBox(height: 16),
          if (day == null)
            _finishedView()
          else
            _todayView(context, ref, day),
        ],
      ),
    );
  }

  Widget _finishedView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.emoji_events, size: 40, color: AppColors.gold),
          SizedBox(height: 8),
          Text(
            '계획을 완주했어요! 🎉',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayView(BuildContext context, WidgetRef ref, ReadingPlanDay day) {
    final progress = ref.watch(progressProvider).value ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day ${day.day} · 오늘의 읽기',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 8),
        for (final ref0 in day.chapters)
          _chapterRow(context, ref0, progress),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              ref.read(progressProvider.notifier).markChaptersRead(
                    day.chapters.map((c) => (c.book, c.chapter)).toList(),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('오늘 분량을 읽음 처리했어요 🔥'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: const Color(0xFF3F1220),
              minimumSize: const Size.fromHeight(46),
            ),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('오늘 분량 모두 읽음'),
          ),
        ),
      ],
    );
  }

  Widget _chapterRow(
    BuildContext context,
    ChapterRef ref0,
    Map<int, Set<int>> progress,
  ) {
    final isRead = progress[ref0.book]?.contains(ref0.chapter) ?? false;
    return InkWell(
      onTap: () => context.push('/reader/${ref0.book}/${ref0.chapter}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              isRead ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: isRead ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ref0.label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  decoration: isRead ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
      tooltip: '계획 옵션',
      onPressed: () async {
        final stop = await showModalBottomSheet<bool>(
          context: context,
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.stop_circle_outlined,
                      color: AppColors.textSecondary),
                  title: const Text('이 계획 그만두기'),
                  subtitle: const Text('읽은 기록은 그대로 남습니다'),
                  onTap: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ),
        );
        if (stop == true) {
          await ref.read(activePlanProvider.notifier).stop();
        }
      },
    );
  }
}

class _PlanCatalogTile extends ConsumerWidget {
  const _PlanCatalogTile({required this.plan, required this.hasActivePlan});

  final ReadingPlan plan;
  final bool hasActivePlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _confirmStart(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plan.subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${plan.durationDays}일 · ${plan.totalChapters}장',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmStart(BuildContext context, WidgetRef ref) async {
    if (hasActivePlan) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('계획 변경'),
          content: Text('진행 중인 계획을 멈추고 "${plan.title}"을(를) 시작할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('취소',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('시작',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }
    await ref.read(activePlanProvider.notifier).start(plan.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${plan.title}" 시작! 오늘 분량부터 읽어보세요.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
