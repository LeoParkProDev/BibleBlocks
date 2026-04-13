import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/kakao_user_info.dart';
import '../services/auth_service.dart';
import 'progress_provider.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authProvider =
    AsyncNotifierProvider<AuthNotifier, KakaoUserInfo?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<KakaoUserInfo?> {
  @override
  Future<KakaoUserInfo?> build() async {
    final service = ref.read(authServiceProvider);
    return service.getCurrentUser();
  }

  Future<void> login() async {
    final service = ref.read(authServiceProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await service.login();

      // 게스트 데이터 마이그레이션
      final progressService = ref.read(progressServiceProvider);
      await progressService.migrateGuestData(user.id.toString());

      // 게스트 모드 해제
      ref.read(isGuestProvider.notifier).set(false);

      return user;
    });
  }

  Future<void> logout() async {
    final service = ref.read(authServiceProvider);
    await service.logout();
    state = const AsyncValue.data(null);
  }
}

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).value != null;
});

final isGuestProvider =
    NotifierProvider<IsGuestNotifier, bool>(IsGuestNotifier.new);

class IsGuestNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}
