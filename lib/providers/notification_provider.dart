import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

/// '오늘의 말씀' 알림 설정(기기 로컬 — 알림 자체가 기기 단위라 게스트/로그인 무관).
class NotificationPrefs {
  final bool enabled;
  final int hour;
  final int minute;

  const NotificationPrefs({
    this.enabled = false,
    this.hour = 7,
    this.minute = 0,
  });

  NotificationPrefs copyWith({bool? enabled, int? hour, int? minute}) =>
      NotificationPrefs(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

final notificationPrefsProvider =
    AsyncNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
  NotificationPrefsNotifier.new,
);

class NotificationPrefsNotifier extends AsyncNotifier<NotificationPrefs> {
  @override
  Future<NotificationPrefs> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return NotificationPrefs(
        enabled: prefs.getBool(NotificationService.prefEnabled) ?? false,
        hour: prefs.getInt(NotificationService.prefHour) ?? 7,
        minute: prefs.getInt(NotificationService.prefMinute) ?? 0,
      );
    } catch (_) {
      return const NotificationPrefs();
    }
  }

  Future<void> _persist(NotificationPrefs p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationService.prefEnabled, p.enabled);
    await prefs.setInt(NotificationService.prefHour, p.hour);
    await prefs.setInt(NotificationService.prefMinute, p.minute);
  }

  /// 알림 켜기 시도. 권한이 거부되면 false(켜지지 않음).
  Future<bool> enable() async {
    final granted = await NotificationService.instance.requestPermission();
    if (!granted) return false;
    final next = (state.value ?? const NotificationPrefs()).copyWith(
      enabled: true,
    );
    await _persist(next);
    await NotificationService.instance.scheduleDailyVerses(
      hour: next.hour,
      minute: next.minute,
    );
    state = AsyncValue.data(next);
    return true;
  }

  Future<void> disable() async {
    final next = (state.value ?? const NotificationPrefs()).copyWith(
      enabled: false,
    );
    await _persist(next);
    await NotificationService.instance.cancelAll();
    state = AsyncValue.data(next);
  }

  Future<void> setTime(int hour, int minute) async {
    final next = (state.value ?? const NotificationPrefs()).copyWith(
      hour: hour,
      minute: minute,
    );
    await _persist(next);
    if (next.enabled) {
      await NotificationService.instance.scheduleDailyVerses(
        hour: hour,
        minute: minute,
      );
    }
    state = AsyncValue.data(next);
  }
}
