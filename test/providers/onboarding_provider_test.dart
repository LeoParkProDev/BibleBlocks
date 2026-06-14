import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/providers/onboarding_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('플래그 없으면 온보딩 미완료(false) — 최초 노출', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(onboardingProvider.future), false);
  });

  test('complete() 후 true + 새 실행에서도 재노출 안 됨', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(onboardingProvider.future);
    await container.read(onboardingProvider.notifier).complete();
    expect(container.read(onboardingProvider).value, true);

    // 앱 재실행 시뮬레이션 — 같은 SharedPreferences에서 다시 로드
    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    expect(await container2.read(onboardingProvider.future), true);
  });

  test('이미 완료 플래그가 있으면 처음부터 true', () async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(onboardingProvider.future), true);
  });
}
