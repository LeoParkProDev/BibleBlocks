import 'package:freezed_annotation/freezed_annotation.dart';

part 'book_progress.freezed.dart';
part 'book_progress.g.dart';

@freezed
abstract class BookProgress with _$BookProgress {
  const factory BookProgress({
    required int bookIndex,
    @Default({}) Set<int> chapters,
    required DateTime updatedAt,
  }) = _BookProgress;

  factory BookProgress.fromJson(Map<String, dynamic> json) =>
      _$BookProgressFromJson(json);
}
