// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookProgress {

 int get bookIndex; Set<int> get chapters; DateTime get updatedAt;
/// Create a copy of BookProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookProgressCopyWith<BookProgress> get copyWith => _$BookProgressCopyWithImpl<BookProgress>(this as BookProgress, _$identity);

  /// Serializes this BookProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookProgress&&(identical(other.bookIndex, bookIndex) || other.bookIndex == bookIndex)&&const DeepCollectionEquality().equals(other.chapters, chapters)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bookIndex,const DeepCollectionEquality().hash(chapters),updatedAt);

@override
String toString() {
  return 'BookProgress(bookIndex: $bookIndex, chapters: $chapters, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $BookProgressCopyWith<$Res>  {
  factory $BookProgressCopyWith(BookProgress value, $Res Function(BookProgress) _then) = _$BookProgressCopyWithImpl;
@useResult
$Res call({
 int bookIndex, Set<int> chapters, DateTime updatedAt
});




}
/// @nodoc
class _$BookProgressCopyWithImpl<$Res>
    implements $BookProgressCopyWith<$Res> {
  _$BookProgressCopyWithImpl(this._self, this._then);

  final BookProgress _self;
  final $Res Function(BookProgress) _then;

/// Create a copy of BookProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bookIndex = null,Object? chapters = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
bookIndex: null == bookIndex ? _self.bookIndex : bookIndex // ignore: cast_nullable_to_non_nullable
as int,chapters: null == chapters ? _self.chapters : chapters // ignore: cast_nullable_to_non_nullable
as Set<int>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BookProgress].
extension BookProgressPatterns on BookProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookProgress value)  $default,){
final _that = this;
switch (_that) {
case _BookProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookProgress value)?  $default,){
final _that = this;
switch (_that) {
case _BookProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int bookIndex,  Set<int> chapters,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookProgress() when $default != null:
return $default(_that.bookIndex,_that.chapters,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int bookIndex,  Set<int> chapters,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _BookProgress():
return $default(_that.bookIndex,_that.chapters,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int bookIndex,  Set<int> chapters,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _BookProgress() when $default != null:
return $default(_that.bookIndex,_that.chapters,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookProgress implements BookProgress {
  const _BookProgress({required this.bookIndex, final  Set<int> chapters = const {}, required this.updatedAt}): _chapters = chapters;
  factory _BookProgress.fromJson(Map<String, dynamic> json) => _$BookProgressFromJson(json);

@override final  int bookIndex;
 final  Set<int> _chapters;
@override@JsonKey() Set<int> get chapters {
  if (_chapters is EqualUnmodifiableSetView) return _chapters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_chapters);
}

@override final  DateTime updatedAt;

/// Create a copy of BookProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookProgressCopyWith<_BookProgress> get copyWith => __$BookProgressCopyWithImpl<_BookProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookProgress&&(identical(other.bookIndex, bookIndex) || other.bookIndex == bookIndex)&&const DeepCollectionEquality().equals(other._chapters, _chapters)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bookIndex,const DeepCollectionEquality().hash(_chapters),updatedAt);

@override
String toString() {
  return 'BookProgress(bookIndex: $bookIndex, chapters: $chapters, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$BookProgressCopyWith<$Res> implements $BookProgressCopyWith<$Res> {
  factory _$BookProgressCopyWith(_BookProgress value, $Res Function(_BookProgress) _then) = __$BookProgressCopyWithImpl;
@override @useResult
$Res call({
 int bookIndex, Set<int> chapters, DateTime updatedAt
});




}
/// @nodoc
class __$BookProgressCopyWithImpl<$Res>
    implements _$BookProgressCopyWith<$Res> {
  __$BookProgressCopyWithImpl(this._self, this._then);

  final _BookProgress _self;
  final $Res Function(_BookProgress) _then;

/// Create a copy of BookProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bookIndex = null,Object? chapters = null,Object? updatedAt = null,}) {
  return _then(_BookProgress(
bookIndex: null == bookIndex ? _self.bookIndex : bookIndex // ignore: cast_nullable_to_non_nullable
as int,chapters: null == chapters ? _self._chapters : chapters // ignore: cast_nullable_to_non_nullable
as Set<int>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
