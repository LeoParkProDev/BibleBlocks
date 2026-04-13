// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kakao_user_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KakaoUserInfo {

 int get id; String? get nickname; String? get profileImageUrl;
/// Create a copy of KakaoUserInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KakaoUserInfoCopyWith<KakaoUserInfo> get copyWith => _$KakaoUserInfoCopyWithImpl<KakaoUserInfo>(this as KakaoUserInfo, _$identity);

  /// Serializes this KakaoUserInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KakaoUserInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nickname,profileImageUrl);

@override
String toString() {
  return 'KakaoUserInfo(id: $id, nickname: $nickname, profileImageUrl: $profileImageUrl)';
}


}

/// @nodoc
abstract mixin class $KakaoUserInfoCopyWith<$Res>  {
  factory $KakaoUserInfoCopyWith(KakaoUserInfo value, $Res Function(KakaoUserInfo) _then) = _$KakaoUserInfoCopyWithImpl;
@useResult
$Res call({
 int id, String? nickname, String? profileImageUrl
});




}
/// @nodoc
class _$KakaoUserInfoCopyWithImpl<$Res>
    implements $KakaoUserInfoCopyWith<$Res> {
  _$KakaoUserInfoCopyWithImpl(this._self, this._then);

  final KakaoUserInfo _self;
  final $Res Function(KakaoUserInfo) _then;

/// Create a copy of KakaoUserInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nickname = freezed,Object? profileImageUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nickname: freezed == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String?,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [KakaoUserInfo].
extension KakaoUserInfoPatterns on KakaoUserInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KakaoUserInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KakaoUserInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KakaoUserInfo value)  $default,){
final _that = this;
switch (_that) {
case _KakaoUserInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KakaoUserInfo value)?  $default,){
final _that = this;
switch (_that) {
case _KakaoUserInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? nickname,  String? profileImageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KakaoUserInfo() when $default != null:
return $default(_that.id,_that.nickname,_that.profileImageUrl);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? nickname,  String? profileImageUrl)  $default,) {final _that = this;
switch (_that) {
case _KakaoUserInfo():
return $default(_that.id,_that.nickname,_that.profileImageUrl);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? nickname,  String? profileImageUrl)?  $default,) {final _that = this;
switch (_that) {
case _KakaoUserInfo() when $default != null:
return $default(_that.id,_that.nickname,_that.profileImageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KakaoUserInfo implements KakaoUserInfo {
  const _KakaoUserInfo({required this.id, this.nickname, this.profileImageUrl});
  factory _KakaoUserInfo.fromJson(Map<String, dynamic> json) => _$KakaoUserInfoFromJson(json);

@override final  int id;
@override final  String? nickname;
@override final  String? profileImageUrl;

/// Create a copy of KakaoUserInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KakaoUserInfoCopyWith<_KakaoUserInfo> get copyWith => __$KakaoUserInfoCopyWithImpl<_KakaoUserInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KakaoUserInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KakaoUserInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nickname,profileImageUrl);

@override
String toString() {
  return 'KakaoUserInfo(id: $id, nickname: $nickname, profileImageUrl: $profileImageUrl)';
}


}

/// @nodoc
abstract mixin class _$KakaoUserInfoCopyWith<$Res> implements $KakaoUserInfoCopyWith<$Res> {
  factory _$KakaoUserInfoCopyWith(_KakaoUserInfo value, $Res Function(_KakaoUserInfo) _then) = __$KakaoUserInfoCopyWithImpl;
@override @useResult
$Res call({
 int id, String? nickname, String? profileImageUrl
});




}
/// @nodoc
class __$KakaoUserInfoCopyWithImpl<$Res>
    implements _$KakaoUserInfoCopyWith<$Res> {
  __$KakaoUserInfoCopyWithImpl(this._self, this._then);

  final _KakaoUserInfo _self;
  final $Res Function(_KakaoUserInfo) _then;

/// Create a copy of KakaoUserInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nickname = freezed,Object? profileImageUrl = freezed,}) {
  return _then(_KakaoUserInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nickname: freezed == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String?,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
