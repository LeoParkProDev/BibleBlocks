import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 스트릭의 진실의 원천인 "활동일(읽은 날) 집합"을 영속화한다.
///
/// 진도(ProgressService)와 동일한 분기:
/// 로그인 → Firestore `users/{uid}.streak.activeDates`,
/// 게스트 → SharedPreferences `bible_streak`.
/// 날짜는 로컬 기준 `YYYY-MM-DD` 문자열로 저장한다.
class StreakService {
  static const _guestKey = 'bible_streak';

  final String? userId;

  StreakService({this.userId});

  bool get _isLoggedIn => userId != null;

  DocumentReference? get _userDoc => _isLoggedIn
      ? FirebaseFirestore.instance.collection('users').doc(userId)
      : null;

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime parseKey(String s) {
    final p = s.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  /// 저장된 모든 활동일 로드.
  Future<Set<DateTime>> loadActiveDates() async {
    final keys = await _loadKeys();
    return keys.map(parseKey).toSet();
  }

  Future<List<String>> _loadKeys() async {
    if (_isLoggedIn) {
      final doc = await _userDoc!.get();
      final data = doc.data() as Map<String, dynamic>?;
      final streak = data?['streak'] as Map<String, dynamic>?;
      return (streak?['activeDates'] as List?)?.cast<String>() ?? [];
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  /// [when]을 활동일로 기록하고 갱신된 활동일 집합을 반환.
  /// 이미 기록된 날이면 저장 없이 그대로 반환.
  Future<Set<DateTime>> recordActivity(DateTime when) async {
    final keys = await _loadKeys();
    final key = dateKey(when);
    if (keys.contains(key)) return keys.map(parseKey).toSet();

    final updated = [...keys, key]..sort();
    await _saveKeys(updated);
    return updated.map(parseKey).toSet();
  }

  Future<void> _saveKeys(List<String> keys) async {
    if (_isLoggedIn) {
      await _userDoc!.set(
        {
          'streak': {'activeDates': keys},
        },
        SetOptions(merge: true),
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_guestKey, jsonEncode(keys));
    }
  }

  /// 게스트 스트릭을 로그인 계정으로 이전. Firestore에 스트릭이 없을 때만.
  Future<void> migrateGuestData(String targetUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestKey);
    if (raw == null) return;

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(targetUserId);
    final snap = await userDoc.get();
    final data = snap.data();
    final existing = (data?['streak'] as Map<String, dynamic>?)?['activeDates'];
    if (existing != null) return; // 기존 데이터 보호

    final keys = (jsonDecode(raw) as List).cast<String>();
    await userDoc.set(
      {
        'streak': {'activeDates': keys},
      },
      SetOptions(merge: true),
    );
  }
}
