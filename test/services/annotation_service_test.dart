import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_blocks/models/verse_annotation.dart';
import 'package:bible_blocks/services/annotation_service.dart';

VerseAnnotation _ann(
  int b,
  int c,
  int v, {
  int? color,
  bool bookmarked = false,
  String? note,
}) =>
    VerseAnnotation(
      bookIndex: b,
      chapter: c,
      verse: v,
      color: color,
      bookmarked: bookmarked,
      note: note,
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  late AnnotationService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = AnnotationService();
  });

  test('초기 로드 — 저장 데이터 없으면 빈 맵', () async {
    expect(await service.loadAll(), isEmpty);
  });

  test('하이라이트 추가 후 재로드 시 유지', () async {
    final map = await service.upsert({}, _ann(18, 23, 1, color: 0xFFFFE08A));
    expect(map['18:23:1']!.color, 0xFFFFE08A);

    final reloaded = await service.loadAll();
    expect(reloaded['18:23:1']!.color, 0xFFFFE08A);
    expect(reloaded['18:23:1']!.hasHighlight, true);
  });

  test('북마크와 노트가 같은 절에 공존', () async {
    var map = await service.upsert({}, _ann(0, 1, 1, bookmarked: true));
    map = await service.upsert(
      map,
      map['0:1:1']!.copyWith(note: '창조의 시작'),
    );
    final reloaded = await service.loadAll();
    expect(reloaded['0:1:1']!.bookmarked, true);
    expect(reloaded['0:1:1']!.note, '창조의 시작');
  });

  test('내용이 모두 비면(upsert isEmpty) 해당 절 삭제', () async {
    var map = await service.upsert({}, _ann(0, 1, 1, color: 0xFFB8E0A0));
    expect(map.containsKey('0:1:1'), true);

    map = await service.upsert(map, _ann(0, 1, 1)); // color/bookmark/note 없음
    expect(map.containsKey('0:1:1'), false);

    final reloaded = await service.loadAll();
    expect(reloaded.containsKey('0:1:1'), false);
  });

  test('remove로 특정 절 주석 삭제', () async {
    var map = await service.upsert({}, _ann(1, 2, 3, note: '메모'));
    map = await service.upsert(map, _ann(4, 5, 6, bookmarked: true));
    map = await service.remove(map, '1:2:3');

    final reloaded = await service.loadAll();
    expect(reloaded.containsKey('1:2:3'), false);
    expect(reloaded.containsKey('4:5:6'), true);
  });

  test('여러 절 저장/재로드 일관성', () async {
    var map = <String, VerseAnnotation>{};
    map = await service.upsert(map, _ann(0, 1, 1, color: 0xFFFFE08A));
    map = await service.upsert(map, _ann(0, 1, 2, bookmarked: true));
    map = await service.upsert(map, _ann(18, 23, 1, note: '여호와는 나의 목자'));

    final reloaded = await service.loadAll();
    expect(reloaded.length, 3);
    expect(reloaded['18:23:1']!.note, '여호와는 나의 목자');
  });

  test('게스트 데이터 없으면 마이그레이션은 무해한 no-op', () async {
    await service.migrateGuestData('user-123'); // 예외 없이 통과
    expect(await service.loadAll(), isEmpty);
  });
}
