import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'config/kakao_config.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  KakaoSdk.init(
    nativeAppKey: KakaoConfig.nativeAppKey,
    javaScriptAppKey: KakaoConfig.javaScriptAppKey,
  );
  runApp(const ProviderScope(child: BibleBlocksApp()));

  // 알림: 켜져 있으면 향후 '오늘의 말씀' 예약을 갱신(앱 실행을 막지 않음).
  unawaited(_refreshDailyVerseSchedule());
}

Future<void> _refreshDailyVerseSchedule() async {
  if (!NotificationService.instance.isSupported) return;
  try {
    await NotificationService.instance.init();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(NotificationService.prefEnabled) ?? false) {
      await NotificationService.instance.scheduleDailyVerses(
        hour: prefs.getInt(NotificationService.prefHour) ?? 7,
        minute: prefs.getInt(NotificationService.prefMinute) ?? 0,
      );
    }
  } catch (_) {
    // 알림 초기화 실패는 앱 실행에 영향을 주지 않는다.
  }
}
