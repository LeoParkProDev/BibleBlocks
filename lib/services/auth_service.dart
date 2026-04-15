import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/kakao_user_info.dart';

class AuthService {
  static const _cacheKey = 'cached_kakao_user';

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }

  /// 현재 로그인된 사용자 정보 반환. 미로그인 시 null.
  /// 캐시 우선: 로컬 캐시가 있으면 즉시 반환, 백그라운드에서 갱신.
  Future<KakaoUserInfo?> getCurrentUser() async {
    try {
      final token = await TokenManagerProvider.instance.manager.getToken();
      if (token == null) return null;

      // 캐시된 사용자 정보가 있으면 즉시 반환
      final cached = await _getCachedUser();
      if (cached != null) {
        // 백그라운드에서 최신 정보 갱신 (fire-and-forget)
        unawaited(_refreshAndCacheUser());
        return cached;
      }

      // 캐시 없으면 네트워크 요청
      return await _fetchAndCacheUser();
    } catch (_) {
      return null;
    }
  }

  Future<KakaoUserInfo?> _getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_cacheKey);
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return KakaoUserInfo(
        id: map['id'] as int,
        nickname: map['nickname'] as String?,
        profileImageUrl: map['profileImageUrl'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<KakaoUserInfo?> _fetchAndCacheUser() async {
    final user = await UserApi.instance.me();
    final info = KakaoUserInfo(
      id: user.id,
      nickname: user.kakaoAccount?.profile?.nickname,
      profileImageUrl: user.kakaoAccount?.profile?.profileImageUrl,
    );
    await _cacheUser(info);
    return info;
  }

  Future<void> _refreshAndCacheUser() async {
    try {
      await _fetchAndCacheUser();
    } catch (_) {
      // 갱신 실패해도 캐시 유지
    }
  }

  Future<void> _cacheUser(KakaoUserInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode({
      'id': info.id,
      'nickname': info.nickname,
      'profileImageUrl': info.profileImageUrl,
    }));
  }
}
