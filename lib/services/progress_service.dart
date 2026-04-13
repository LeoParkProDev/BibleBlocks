import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bible_data.dart';

class ProgressService {
  static const _guestKey = 'bible_progress';

  final String? userId;

  ProgressService({this.userId});

  bool get _isLoggedIn => userId != null;

  String get _localStorageKey =>
      _isLoggedIn ? 'bible_progress_$userId' : _guestKey;

  DocumentReference? get _userDoc => _isLoggedIn
      ? FirebaseFirestore.instance.collection('users').doc(userId)
      : null;

  /// 모든 책의 읽은 장 데이터 로드. key: bookIndex, value: 읽은 장 Set
  Future<Map<int, Set<int>>> loadAll() async {
    if (_isLoggedIn) {
      return _loadFromFirestore();
    }
    return _loadFromLocal();
  }

  Future<Map<int, Set<int>>> _loadFromFirestore() async {
    final doc = await _userDoc!.get();
    if (!doc.exists) return {};

    final data = doc.data() as Map<String, dynamic>?;
    final progress = data?['progress'] as Map<String, dynamic>?;
    if (progress == null) return {};

    return _decodeProgress(progress);
  }

  Future<Map<int, Set<int>>> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localStorageKey);
    if (raw == null) return {};

    final Map<String, dynamic> decoded = jsonDecode(raw);
    return _decodeProgress(decoded);
  }

  Map<int, Set<int>> _decodeProgress(Map<String, dynamic> raw) {
    final result = <int, Set<int>>{};
    for (final entry in raw.entries) {
      final bookIndex = int.parse(entry.key);
      final chapters = (entry.value as List).cast<int>().toSet();
      result[bookIndex] = chapters;
    }
    return result;
  }

  /// 장 토글 (읽음/안읽음). 변경된 전체 상태 반환
  Future<Map<int, Set<int>>> toggleChapter(
    Map<int, Set<int>> current,
    int bookIndex,
    int chapter,
  ) async {
    final updated = Map<int, Set<int>>.from(current);
    final chapters = Set<int>.from(updated[bookIndex] ?? {});

    if (chapters.contains(chapter)) {
      chapters.remove(chapter);
    } else {
      chapters.add(chapter);
    }

    if (chapters.isEmpty) {
      updated.remove(bookIndex);
    } else {
      updated[bookIndex] = chapters;
    }

    await _save(updated);
    return updated;
  }

  /// 책 전체 장 토글. 완독 → 전체 해제, 미완독 → 전체 읽음
  Future<Map<int, Set<int>>> toggleAllChapters(
    Map<int, Set<int>> current,
    int bookIndex,
    int totalChapters,
  ) async {
    final updated = Map<int, Set<int>>.from(current);
    final readChapters = updated[bookIndex] ?? {};

    if (readChapters.length == totalChapters) {
      updated.remove(bookIndex);
    } else {
      updated[bookIndex] = Set<int>.from(
        List.generate(totalChapters, (i) => i + 1),
      );
    }

    await _save(updated);
    return updated;
  }

  /// 게스트 데이터를 유저 키로 마이그레이션.
  /// 게스트 로컬 데이터가 있고 Firestore에 데이터가 없을 때만 복사.
  Future<void> migrateGuestData(String targetUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final guestRaw = prefs.getString(_guestKey);
    if (guestRaw == null) return;

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId);
    final snapshot = await userDoc.get();
    if (snapshot.exists) return;

    final Map<String, dynamic> decoded = jsonDecode(guestRaw);
    await userDoc.set({
      'progress': decoded,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _save(Map<int, Set<int>> data) async {
    final encoded = _encodeProgress(data);

    if (_isLoggedIn) {
      await _userDoc!.set({
        'progress': encoded,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localStorageKey, jsonEncode(encoded));
    }
  }

  Map<String, dynamic> _encodeProgress(Map<int, Set<int>> data) {
    final encoded = <String, dynamic>{};
    for (final entry in data.entries) {
      encoded[entry.key.toString()] = entry.value.toList()..sort();
    }
    return encoded;
  }

  /// 전체 초기화
  Future<void> resetAll() async {
    if (_isLoggedIn) {
      await _userDoc!.delete();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localStorageKey);
    }
  }

  /// 전체 읽은 장 수 계산
  static int totalRead(Map<int, Set<int>> data) {
    int count = 0;
    for (final chapters in data.values) {
      count += chapters.length;
    }
    return count;
  }

  /// 특정 전역 인덱스(0~1188)가 읽혔는지 확인
  static bool isGlobalIndexRead(Map<int, Set<int>> data, int globalIndex) {
    final (bookIndex, chapter) = BibleData.fromGlobalIndex(globalIndex);
    return data[bookIndex]?.contains(chapter) ?? false;
  }
}
