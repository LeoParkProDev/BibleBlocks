import 'package:freezed_annotation/freezed_annotation.dart';

part 'kakao_user_info.freezed.dart';
part 'kakao_user_info.g.dart';

@freezed
abstract class KakaoUserInfo with _$KakaoUserInfo {
  const factory KakaoUserInfo({
    required int id,
    String? nickname,
    String? profileImageUrl,
  }) = _KakaoUserInfo;

  factory KakaoUserInfo.fromJson(Map<String, dynamic> json) =>
      _$KakaoUserInfoFromJson(json);
}
