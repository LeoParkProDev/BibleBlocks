import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../models/kakao_user_info.dart';

class AuthService {
  /// 카카오 로그인.
  /// Web → 카카오계정 로그인, Mobile → 카카오톡 우선 → fallback 카카오계정.
  Future<KakaoUserInfo> login() async {
    if (kIsWeb) {
      await UserApi.instance.loginWithKakaoAccount();
    } else {
      if (await isKakaoTalkInstalled()) {
        try {
          await UserApi.instance.loginWithKakaoTalk();
        } catch (_) {
          await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        await UserApi.instance.loginWithKakaoAccount();
      }
    }
    final user = await getCurrentUser();
    if (user == null) throw Exception('로그인 후 사용자 정보를 가져올 수 없습니다');
    return user;
  }

  /// 로그아웃
  Future<void> logout() async {
    await UserApi.instance.logout();
  }

  /// 현재 로그인된 사용자 정보 반환. 미로그인 시 null.
  Future<KakaoUserInfo?> getCurrentUser() async {
    try {
      final token = await TokenManagerProvider.instance.manager.getToken();
      if (token == null) return null;

      final user = await UserApi.instance.me();
      return KakaoUserInfo(
        id: user.id,
        nickname: user.kakaoAccount?.profile?.nickname,
        profileImageUrl: user.kakaoAccount?.profile?.profileImageUrl,
      );
    } catch (_) {
      return null;
    }
  }
}
