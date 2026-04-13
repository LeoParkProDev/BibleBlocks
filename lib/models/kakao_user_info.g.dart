// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kakao_user_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KakaoUserInfo _$KakaoUserInfoFromJson(Map<String, dynamic> json) =>
    _KakaoUserInfo(
      id: (json['id'] as num).toInt(),
      nickname: json['nickname'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
    );

Map<String, dynamic> _$KakaoUserInfoToJson(_KakaoUserInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'profileImageUrl': instance.profileImageUrl,
    };
