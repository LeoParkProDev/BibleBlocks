import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/daily_verses.dart';
import 'bible_text_service.dart';

/// '오늘의 말씀' 로컬 알림을 관리한다.
///
/// OS는 매일 반복 알림의 '내용'을 바꿀 수 없으므로, 향후 며칠치를 각각
/// 단발 예약(zonedSchedule)으로 등록하고 앱 실행 때마다 다시 채운다.
/// 웹은 로컬 알림을 지원하지 않으므로 모든 동작이 안전한 no-op이다.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final BibleTextService _textService = BibleTextService();
  bool _initialized = false;

  static const _channelId = 'daily_verse';
  static const _channelName = '오늘의 말씀';
  static const _channelDesc = '매일 정한 시간에 오늘의 말씀을 보내드립니다';

  /// SharedPreferences 키(설정 화면 / 앱 시작 코드와 공유).
  static const prefEnabled = 'notif_enabled';
  static const prefHour = 'notif_hour';
  static const prefMinute = 'notif_minute';

  /// 로컬 알림이 지원되는 플랫폼인지(웹 미지원).
  bool get isSupported => !kIsWeb;

  Future<void> init() async {
    if (!isSupported || _initialized) return;
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // 타임존 식별 실패 시 기본(UTC)으로라도 진행.
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  /// 알림 권한 요청. 허용되면 true.
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (_) {}
    return true;
  }

  /// 향후 [days]일치 '오늘의 말씀'을 매일 [hour]:[minute]에 예약.
  Future<void> scheduleDailyVerses({
    required int hour,
    required int minute,
    int days = 14,
  }) async {
    if (!isSupported) return;
    await init();
    try {
      await _plugin.cancelAll();
      final now = tz.TZDateTime.now(tz.local);
      for (var i = 0; i < days; i++) {
        final base = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
        final scheduled = base.add(Duration(days: i));
        if (scheduled.isBefore(now)) continue; // 오늘 시간이 지났으면 건너뜀
        final body = await _verseBody(DailyVerses.forDate(scheduled));
        await _plugin.zonedSchedule(
          id: i,
          title: '오늘의 말씀',
          body: body,
          scheduledDate: scheduled,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDesc,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              styleInformation: BigTextStyleInformation(body),
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (_) {
      // 예약 실패는 사용자 경험을 막지 않는다.
    }
  }

  Future<void> cancelAll() async {
    if (!isSupported) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  Future<String> _verseBody(DailyVerseRef ref) async {
    try {
      final verses = await _textService.loadChapter(ref.book, ref.chapter);
      final match = verses.firstWhere(
        (v) => v.number == ref.verse,
        orElse: () => verses.first,
      );
      return '${ref.label}\n${match.text}';
    } catch (_) {
      return ref.label;
    }
  }
}
