/// 완독 상태 미리보기용 엔트리포인트 (배포 금지)
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app.dart';
import 'config/kakao_config.dart';
import 'data/bible_data.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/progress_provider.dart';

/// 모든 장을 읽은 상태로 반환하는 Notifier
class _FullProgressNotifier extends ProgressNotifier {
  @override
  Future<Map<int, Set<int>>> build() async {
    final data = <int, Set<int>>{};
    for (final book in BibleData.books) {
      data[book.index] = Set<int>.from(
        List.generate(book.chapters, (i) => i + 1),
      );
    }
    return data;
  }
}

class _AlwaysGuestNotifier extends IsGuestNotifier {
  @override
  Future<bool> build() async => true;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  KakaoSdk.init(
    nativeAppKey: KakaoConfig.nativeAppKey,
    javaScriptAppKey: KakaoConfig.javaScriptAppKey,
  );
  runApp(
    ProviderScope(
      overrides: [
        progressProvider.overrideWith(() => _FullProgressNotifier()),
        isGuestProvider.overrideWith(() => _AlwaysGuestNotifier()),
      ],
      child: const BibleBlocksApp(),
    ),
  );
}
