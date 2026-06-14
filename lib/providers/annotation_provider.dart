import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/verse_annotation.dart';
import '../services/annotation_service.dart';
import 'auth_provider.dart';

final annotationServiceProvider = Provider<AnnotationService>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.value?.id.toString();
  return AnnotationService(userId: userId);
});

/// 키(`book:chapter:verse`)→[VerseAnnotation] 전체 맵.
final annotationProvider =
    AsyncNotifierProvider<AnnotationNotifier, Map<String, VerseAnnotation>>(
  AnnotationNotifier.new,
);

/// 주석은 보조 기능이다 — 로드/저장 실패가 핵심 읽기/체크를 막지 않도록
/// 모든 경로에서 예외를 흡수한다.
class AnnotationNotifier
    extends AsyncNotifier<Map<String, VerseAnnotation>> {
  @override
  Future<Map<String, VerseAnnotation>> build() async {
    final service = ref.watch(annotationServiceProvider);
    try {
      return await service.loadAll();
    } catch (_) {
      return {};
    }
  }

  Map<String, VerseAnnotation> get _current => state.value ?? {};

  VerseAnnotation _base(int book, int chapter, int verse) {
    return _current[VerseAnnotation.makeKey(book, chapter, verse)] ??
        VerseAnnotation(
          bookIndex: book,
          chapter: chapter,
          verse: verse,
          updatedAt: DateTime.now(),
        );
  }

  Future<void> _apply(VerseAnnotation next) async {
    final service = ref.read(annotationServiceProvider);
    try {
      final updated = await service.upsert(_current, next);
      state = AsyncValue.data(updated);
    } catch (_) {
      // 무시 — 주석 저장 실패는 사용자 경험을 막지 않는다.
    }
  }

  /// 하이라이트 색 설정. [color]가 null이면 하이라이트 제거.
  Future<void> setHighlight(int book, int chapter, int verse, int? color) {
    final base = _base(book, chapter, verse);
    final next = color == null
        ? base.copyWith(clearColor: true, updatedAt: DateTime.now())
        : base.copyWith(color: color, updatedAt: DateTime.now());
    return _apply(next);
  }

  Future<void> toggleBookmark(int book, int chapter, int verse) {
    final base = _base(book, chapter, verse);
    return _apply(
      base.copyWith(bookmarked: !base.bookmarked, updatedAt: DateTime.now()),
    );
  }

  /// 노트 저장. 빈 문자열이면 노트 제거.
  Future<void> setNote(int book, int chapter, int verse, String note) {
    final base = _base(book, chapter, verse);
    final trimmed = note.trim();
    final next = trimmed.isEmpty
        ? base.copyWith(clearNote: true, updatedAt: DateTime.now())
        : base.copyWith(note: trimmed, updatedAt: DateTime.now());
    return _apply(next);
  }

  /// 절의 모든 주석 제거.
  Future<void> clearVerse(int book, int chapter, int verse) async {
    final service = ref.read(annotationServiceProvider);
    try {
      final updated = await service.remove(
        _current,
        VerseAnnotation.makeKey(book, chapter, verse),
      );
      state = AsyncValue.data(updated);
    } catch (_) {
      // 무시
    }
  }
}
