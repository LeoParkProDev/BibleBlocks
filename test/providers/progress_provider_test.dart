import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/providers/progress_provider.dart';
import 'package:bible_blocks/data/bible_data.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // D-01
  test('D-01: progressProvider 초기 상태 AsyncLoading → AsyncData', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 초기에는 로딩
    final initial = container.read(progressProvider);
    expect(initial is AsyncLoading, true);

    // 로딩 완료 대기
    await container.read(progressProvider.future);
    final loaded = container.read(progressProvider);
    expect(loaded.value, isEmpty);
  });

  // D-02
  test('D-02: toggleChapter 호출 후 state 즉시 반영', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(progressProvider.future);
    await container.read(progressProvider.notifier).toggleChapter(0, 1);

    final data = container.read(progressProvider).value!;
    expect(data[0], {1});
  });

  // D-03
  test('D-03: totalReadProvider 파생값 정확', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(progressProvider.future);
    await container.read(progressProvider.notifier).toggleChapter(0, 1);
    await container.read(progressProvider.notifier).toggleChapter(0, 2);
    await container.read(progressProvider.notifier).toggleChapter(39, 1);

    expect(container.read(totalReadProvider), 3);
  });

  // D-04
  test('D-04: overallProgressProvider 비율 계산', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(progressProvider.future);

    // 0장 → 0.0
    expect(container.read(overallProgressProvider), 0.0);

    // 1장 체크
    await container.read(progressProvider.notifier).toggleChapter(0, 1);
    expect(
      container.read(overallProgressProvider),
      closeTo(1 / BibleData.totalChapters, 0.0001),
    );
  });

  // D-05
  test('D-05: 다중 토글 후 상태 일관성 (ON→OFF→ON)', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(progressProvider.future);
    final notifier = container.read(progressProvider.notifier);

    await notifier.toggleChapter(0, 1); // ON
    expect(container.read(progressProvider).value![0], {1});

    await notifier.toggleChapter(0, 1); // OFF
    expect(container.read(progressProvider).value!.containsKey(0), false);

    await notifier.toggleChapter(0, 1); // ON again
    expect(container.read(progressProvider).value![0], {1});
  });
}
