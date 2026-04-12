import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/services/progress_service.dart';

void main() {
  late ProgressService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = ProgressService();
  });

  // C-01
  test('C-01: 초기 로드 — 저장 데이터 없으면 빈 Map 반환', () async {
    final data = await service.loadAll();
    expect(data, isEmpty);
  });

  // C-02
  test('C-02: 장 체크 (토글 ON)', () async {
    final result = await service.toggleChapter({}, 0, 1);
    expect(result[0], {1});
  });

  // C-03
  test('C-03: 장 체크 해제 (토글 OFF)', () async {
    final after = await service.toggleChapter({0: {1}}, 0, 1);
    expect(after.containsKey(0), false);
  });

  // C-04
  test('C-04: 같은 책 여러 장 체크', () async {
    var data = <int, Set<int>>{};
    data = await service.toggleChapter(data, 0, 1);
    data = await service.toggleChapter(data, 0, 3);
    data = await service.toggleChapter(data, 0, 5);
    expect(data[0], {1, 3, 5});
  });

  // C-05
  test('C-05: 다른 책 동시 체크', () async {
    var data = <int, Set<int>>{};
    data = await service.toggleChapter(data, 0, 1);
    data = await service.toggleChapter(data, 39, 1);
    expect(data[0], {1});
    expect(data[39], {1});
  });

  // C-06
  test('C-06: 마지막 장 해제 시 bookIndex 키 자체 삭제', () async {
    var data = await service.toggleChapter({}, 0, 1);
    expect(data.containsKey(0), true);
    data = await service.toggleChapter(data, 0, 1);
    expect(data.containsKey(0), false);
  });

  // C-07
  test('C-07: 저장 후 재로드 일관성', () async {
    var data = <int, Set<int>>{};
    data = await service.toggleChapter(data, 0, 1);
    data = await service.toggleChapter(data, 0, 5);
    data = await service.toggleChapter(data, 39, 3);

    final reloaded = await service.loadAll();
    expect(reloaded[0], {1, 5});
    expect(reloaded[39], {3});
  });

  // C-08
  test('C-08: totalRead 정확도', () {
    final data = {0: {1, 2, 3}, 39: {1}};
    expect(ProgressService.totalRead(data), 4);
  });

  // C-09
  test('C-09: totalRead 빈 데이터', () {
    expect(ProgressService.totalRead({}), 0);
  });

  // C-10
  test('C-10: isGlobalIndexRead 판별', () {
    // 창세기 1장 = global 0
    final data = {0: {1}};
    expect(ProgressService.isGlobalIndexRead(data, 0), true);
    // 창세기 2장 = global 1
    expect(ProgressService.isGlobalIndexRead(data, 1), false);
  });
}
