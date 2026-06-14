import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/bible_data.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../screens/bible_view/bible_view_screen.dart';
import '../screens/checklist/checklist_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/notes/notes_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/plans/plans_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/reader/reader_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../theme/app_colors.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Auth + Guest 상태 변화를 GoRouter에 알려주는 Listenable
final _routerListenableProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => notifier.value++);
  ref.listen(isGuestProvider, (_, _) => notifier.value++);
  ref.listen(onboardingProvider, (_, _) => notifier.value++);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = ref.watch(_routerListenableProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/bible',
    refreshListenable: listenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final guestState = ref.read(isGuestProvider);
      final onboardingState = ref.read(onboardingProvider);

      // 로딩 중이면 리다이렉트 없음
      if (authState is AsyncLoading ||
          guestState is AsyncLoading ||
          onboardingState is AsyncLoading) {
        return null;
      }

      final onboardingDone = onboardingState.value ?? false;
      final goingToOnboarding = state.matchedLocation == '/onboarding';

      // 온보딩 미완료면 로그인보다 먼저 온보딩(게스트/로그인 이전 노출)
      if (!onboardingDone) {
        return goingToOnboarding ? null : '/onboarding';
      }

      final isLoggedIn = authState.value != null;
      final isGuest = guestState.value ?? false;
      final goingToLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isGuest) {
        return goingToLogin ? null : '/login';
      }

      // 로그인/게스트 상태에서 로그인·온보딩 경로는 메인으로
      if (goingToLogin || goingToOnboarding) {
        return '/bible';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/notes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotesScreen(),
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            SearchScreen(initialQuery: state.uri.queryParameters['q']),
      ),
      GoRoute(
        path: '/reader/:book/:chapter',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final book = int.tryParse(state.pathParameters['book'] ?? '') ?? 0;
          final chapter =
              int.tryParse(state.pathParameters['chapter'] ?? '') ?? 1;
          final safeBook = book.clamp(0, BibleData.totalBooks - 1);
          final safeChapter =
              chapter.clamp(1, BibleData.books[safeBook].chapters);
          final verse = int.tryParse(state.uri.queryParameters['verse'] ?? '');
          return ReaderScreen(
            bookIndex: safeBook,
            chapter: safeChapter,
            focusVerse: verse,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bible',
                builder: (context, state) => const BibleViewScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/checklist',
                builder: (context, state) => const ChecklistScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plans',
                builder: (context, state) => const PlansScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.view_in_ar),
            label: t.navBlocks,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.checklist),
            label: t.navChecklist,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today),
            label: t.navPlans,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: t.navSettings,
          ),
        ],
      ),
    );
  }
}
