import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/bible_data.dart';

class ProgressService {
  static const _storageKey = 'bible_progress';

  /// 모든 책의 읽은 장 데이터 로드. key: bookIndex, value: 읽은 장 Set
  Future<Map<int, Set<int>>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return {};

    final Map<String, dynamic> decoded = jsonDecode(raw);
    final result = <int, Set<int>>{};
    for (final entry in decoded.entries) {
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

  Future<void> _save(Map<int, Set<int>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{};
    for (final entry in data.entries) {
      encoded[entry.key.toString()] = entry.value.toList()..sort();
    }
    await prefs.setString(_storageKey, jsonEncode(encoded));
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
