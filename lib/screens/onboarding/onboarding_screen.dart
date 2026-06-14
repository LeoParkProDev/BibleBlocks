import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/reading_plans.dart';
import '../../l10n/l10n.dart';
import '../../painters/isometric_bible_painter.dart';
import '../../providers/notification_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/progress_provider.dart';
import '../../theme/app_colors.dart';

/// 최초 실행 온보딩(≤4화면): 의도 → 읽기 계획 → 알림(웹 제외) → 첫 블록.
/// 게스트/로그인 이전에 노출되며, 완료/스킵 시 플래그를 저장한다.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _controller = PageController();
  late final AnimationController _fillController;
  int _page = 0;
  String? _intent;
  TimeOfDay _notifTime = const TimeOfDay(hour: 7, minute: 0);
  bool _blockChecked = false;
  bool _finishing = false;

  /// 알림 페이지를 웹에서는 건너뛴다.
  bool get _showNotif => !kIsWeb;
  int get _pageCount => _showNotif ? 4 : 3;

  @override
  void initState() {
    super.initState();
    _fillController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _controller.dispose();
    _fillController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _pageCount - 1) return;
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await ref.read(onboardingProvider.notifier).complete();
    // 라우터 redirect가 로그인/메인으로 이동시킨다.
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _intentPage(),
      _planPage(),
      if (_showNotif) _notificationPage(),
      _firstBlockPage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 상단: 진행 점 + 건너뛰기
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  Row(
                    children: List.generate(_pageCount, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  if (_page < _pageCount - 1)
                    TextButton(
                      onPressed: _finishing ? null : _finish,
                      child: Text(
                        context.l10n.skip,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: pages,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 공통 페이지 골격 ───────────────────────────────────────────
  Widget _pageScaffold({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  // ── 1. 의도 ────────────────────────────────────────────────────
  Widget _intentPage() {
    final t = context.l10n;
    final options = [
      (t.onbIntentReadAll, t.onbIntentReadAllDesc, Icons.menu_book),
      (t.onbIntentDaily, t.onbIntentDailyDesc, Icons.wb_sunny_outlined),
      (t.onbIntentTopic, t.onbIntentTopicDesc, Icons.spa_outlined),
    ];
    return _pageScaffold(
      title: t.onbIntentTitle,
      subtitle: t.onbIntentSubtitle,
      children: [
        for (final (label, desc, icon) in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionCard(
              icon: icon,
              label: label,
              description: desc,
              selected: _intent == label,
              onTap: () {
                setState(() => _intent = label);
                _next();
              },
            ),
          ),
      ],
    );
  }

  // ── 2. 읽기 계획 ───────────────────────────────────────────────
  Widget _planPage() {
    final t = context.l10n;
    return _pageScaffold(
      title: t.onbPlanTitle,
      subtitle: t.onbPlanSubtitle,
      children: [
        for (final plan in ReadingPlans.all)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PlanTile(
              plan: plan,
              onTap: () async {
                await ref.read(activePlanProvider.notifier).start(plan.id);
                _next();
              },
            ),
          ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: _next,
            child: Text(
              context.l10n.onbPlanLater,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  // ── 3. 알림 (모바일) ───────────────────────────────────────────
  Widget _notificationPage() {
    final t = context.l10n;
    return _pageScaffold(
      title: t.onbNotifTitle,
      subtitle: t.onbNotifSubtitle,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_outlined,
                  color: AppColors.gold),
              const SizedBox(width: 12),
              Text(
                _notifTime.format(context),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _notifTime,
                  );
                  if (picked != null) setState(() => _notifTime = picked);
                },
                child: Text(t.onbNotifChangeTime),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () async {
            final notifier = ref.read(notificationPrefsProvider.notifier);
            await notifier.setTime(_notifTime.hour, _notifTime.minute);
            await notifier.enable();
            _next();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(t.onbNotifEnable),
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: _next,
            child: Text(
              t.skip,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  // ── 4. 첫 블록 ─────────────────────────────────────────────────
  Widget _firstBlockPage() {
    final t = context.l10n;
    return _pageScaffold(
      title: _blockChecked ? t.onbFirstTitleDone : t.onbFirstTitle,
      subtitle:
          _blockChecked ? t.onbFirstSubtitleDone : t.onbFirstSubtitle,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 260,
            color: AppColors.darkBg,
            child: AnimatedBuilder(
              animation: _fillController,
              builder: (context, _) {
                return CustomPaint(
                  painter: IsometricBiblePainter(
                    progressData: _blockChecked
                        ? const {
                            0: {1}
                          }
                        : const {},
                    newlyFilledBlocks: _blockChecked ? const {0} : const {},
                    fillAnimation: _fillController.value,
                    introAnimation: 1.0,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (!_blockChecked)
          FilledButton.icon(
            onPressed: () {
              ref.read(progressProvider.notifier).toggleChapter(0, 1);
              setState(() => _blockChecked = true);
              _fillController.forward(from: 0);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.check),
            label: Text(t.onbFirstCheck),
          )
        else
          FilledButton(
            onPressed: _finishing ? null : _finish,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: const Color(0xFF3F2A00),
              minimumSize: const Size.fromHeight(50),
            ),
            child: _finishing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(t.onbStart),
          ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBg : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.onTap});

  final ReadingPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
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
    );
  }
}
