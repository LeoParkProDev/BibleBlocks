import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/plan_progress.dart';

/// 진행 중인 읽기 계획(한 번에 하나)을 영속화한다.
/// 로그인 → Firestore `users/{uid}.activePlan`, 게스트 → SharedPreferences.
class PlanService {
  static const _guestKey = 'bible_active_plan';

  final String? userId;

  PlanService({this.userId});

  bool get _isLoggedIn => userId != null;

  DocumentReference? get _userDoc => _isLoggedIn
      ? FirebaseFirestore.instance.collection('users').doc(userId)
      : null;

  Future<PlanProgress?> load() async {
    if (_isLoggedIn) {
      final doc = await _userDoc!.get();
      final data = doc.data() as Map<String, dynamic>?;
      final plan = data?['activePlan'] as Map<String, dynamic>?;
      if (plan == null) return null;
      return PlanProgress.fromJson(plan);
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestKey);
    if (raw == null) return null;
    return PlanProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<PlanProgress> start(String planId, {DateTime? now}) async {
    final progress =
        PlanProgress(planId: planId, startedAt: now ?? DateTime.now());
    if (_isLoggedIn) {
      await _userDoc!
          .set({'activePlan': progress.toJson()}, SetOptions(merge: true));
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_guestKey, jsonEncode(progress.toJson()));
    }
    return progress;
  }

  Future<void> clear() async {
    if (_isLoggedIn) {
      await _userDoc!
          .set({'activePlan': FieldValue.delete()}, SetOptions(merge: true));
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_guestKey);
    }
  }

  /// 게스트 계획을 로그인 계정으로 이전(Firestore에 없을 때만).
  Future<void> migrateGuestData(String targetUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestKey);
    if (raw == null) return;

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(targetUserId);
    final snap = await userDoc.get();
    final data = snap.data();
    if (data?['activePlan'] != null) return;

    await userDoc.set(
      {'activePlan': jsonDecode(raw)},
      SetOptions(merge: true),
    );
  }
}
