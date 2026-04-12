// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookProgress _$BookProgressFromJson(Map<String, dynamic> json) =>
    _BookProgress(
      bookIndex: (json['bookIndex'] as num).toInt(),
      chapters:
          (json['chapters'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toSet() ??
          const {},
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$BookProgressToJson(_BookProgress instance) =>
    <String, dynamic>{
      'bookIndex': instance.bookIndex,
      'chapters': instance.chapters.toList(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
