import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/verse_annotation.dart';

/// 절 단위 하이라이트·북마크·노트를 영속화한다.
///
/// 진도/스트릭과 동일한 분기:
/// 로그인 → Firestore `users/{uid}.annotations`,
/// 게스트 → SharedPreferences `bible_annotations`.
/// 절이 많아도 "문서 1개에 맵"으로 저장해 쓰기를 1회로 유지한다.
class AnnotationService {
  static const _guestKey = 'bible_annotations';

  final String? userId;

  AnnotationService({this.userId});

  bool get _isLoggedIn => userId != null;

  DocumentReference? get _userDoc => _isLoggedIn
      ? FirebaseFirestore.instance.collection('users').doc(userId)
      : null;

  /// 저장된 모든 주석을 키(`book:chapter:verse`)→[VerseAnnotation] 맵으로 로드.
  Future<Map<String, VerseAnnotation>> loadAll() async {
    final raw = await _loadRaw();
    return _decode(raw);
  }

  Future<Map<String, dynamic>> _loadRaw() async {
    if (_isLoggedIn) {
      final doc = await _userDoc!.get();
      final data = doc.data() as Map<String, dynamic>?;
      return (data?['annotations'] as Map<String, dynamic>?) ?? {};
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>);
  }

  Map<String, VerseAnnotation> _decode(Map<String, dynamic> raw) {
    final result = <String, VerseAnnotation>{};
    for (final entry in raw.entries) {
      result[entry.key] = VerseAnnotation.fromKey(
        entry.key,
        (entry.value as Map).cast<String, dynamic>(),
      );
    }
    return result;
  }

  /// [annotation]을 절 키로 추가/갱신. 내용이 비면(=isEmpty) 해당 절을 삭제.
  /// 갱신된 전체 맵을 반환한다.
  Future<Map<String, VerseAnnotation>> upsert(
    Map<String, VerseAnnotation> current,
    VerseAnnotation annotation,
  ) async {
    final updated = Map<String, VerseAnnotation>.from(current);
    if (annotation.isEmpty) {
      updated.remove(annotation.key);
    } else {
      updated[annotation.key] = annotation;
    }
    await _save(updated);
    return updated;
  }

  /// 특정 절의 모든 주석 삭제.
  Future<Map<String, VerseAnnotation>> remove(
    Map<String, VerseAnnotation> current,
    String key,
  ) async {
    final updated = Map<String, VerseAnnotation>.from(current)..remove(key);
    await _save(updated);
    return updated;
  }

  Future<void> _save(Map<String, VerseAnnotation> data) async {
    final encoded = <String, dynamic>{
      for (final e in data.entries) e.key: e.value.toJson(),
    };
    if (_isLoggedIn) {
      await _userDoc!.set(
        {'annotations': encoded},
        SetOptions(merge: true),
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_guestKey, jsonEncode(encoded));
    }
  }

  /// 게스트 주석을 로그인 계정으로 이전(Firestore에 주석이 없을 때만).
  Future<void> migrateGuestData(String targetUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestKey);
    if (raw == null) return;

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(targetUserId);
    final snap = await userDoc.get();
    final existing =
        (snap.data()?['annotations'] as Map<String, dynamic>?);
    if (existing != null && existing.isNotEmpty) return; // 기존 데이터 보호

    await userDoc.set(
      {'annotations': jsonDecode(raw)},
      SetOptions(merge: true),
    );
  }
}
