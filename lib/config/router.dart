import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/bible_view/bible_view_screen.dart';
import '../screens/checklist/checklist_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/settings/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Auth + Guest 상태 변화를 GoRouter에 알려주는 Listenable
final _routerListenableProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier(0);
  ref.listen(authProvider, (_, __) => notifier.value++);
  ref.listen(isGuestProvider, (_, __) => notifier.value++);
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

      // 로딩 중이면 리다이렉트 없음
      if (authState is AsyncLoading || guestState is AsyncLoading) {
        return null;
      }

      final isLoggedIn = authState.value != null;
      final isGuest = guestState.value ?? false;
      final goingToLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isGuest) {
        return goingToLogin ? null : '/login';
      }

      if (goingToLogin) {
        return '/bible';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories),
            label: '내 성경',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: '체크리스트',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
