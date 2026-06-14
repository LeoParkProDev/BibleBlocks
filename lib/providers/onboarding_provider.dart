import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 최초 실행 온보딩 완료 여부(기기 로컬). 게스트/로그인과 무관하게 기기 1회.
final onboardingProvider =
    AsyncNotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

class OnboardingNotifier extends AsyncNotifier<bool> {
  static const _key = 'onboarding_done';

  @override
  Future<bool> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 온보딩 완료 처리. 실패해도 앱 진입을 막지 않도록 상태는 갱신한다.
  Future<void> complete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {
      // 무시 — 플래그 저장 실패해도 진행
    }
    state = const AsyncValue.data(true);
  }
}
