/// 한 절에 대한 사용자 표시(하이라이트·북마크·노트)를 한 레코드로 묶는다.
///
/// 절 하나에 하이라이트와 노트가 동시에 붙는 경우가 흔하므로, `type`별로
/// 여러 레코드를 두는 대신 절당 하나의 집합 레코드로 저장한다. 키는
/// `book:chapter:verse`이며 진도(Progress)와 같이 "문서 1개 + 맵" 패턴으로
/// 저장해 쓰기 비용을 1회로 유지한다.
class VerseAnnotation {
  const VerseAnnotation({
    required this.bookIndex,
    required this.chapter,
    required this.verse,
    this.color,
    this.bookmarked = false,
    this.note,
    required this.updatedAt,
  });

  final int bookIndex;
  final int chapter;
  final int verse;

  /// 하이라이트 색(ARGB int). null이면 하이라이트 없음.
  final int? color;
  final bool bookmarked;
  final String? note;
  final DateTime updatedAt;

  String get key => makeKey(bookIndex, chapter, verse);

  static String makeKey(int book, int chapter, int verse) =>
      '$book:$chapter:$verse';

  bool get hasHighlight => color != null;
  bool get hasNote => note != null && note!.trim().isNotEmpty;

  /// 표시할 내용이 하나도 없으면 레코드를 지워야 한다.
  bool get isEmpty => color == null && !bookmarked && !hasNote;

  VerseAnnotation copyWith({
    int? color,
    bool clearColor = false,
    bool? bookmarked,
    String? note,
    bool clearNote = false,
    DateTime? updatedAt,
  }) {
    return VerseAnnotation(
      bookIndex: bookIndex,
      chapter: chapter,
      verse: verse,
      color: clearColor ? null : (color ?? this.color),
      bookmarked: bookmarked ?? this.bookmarked,
      note: clearNote ? null : (note ?? this.note),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 맵 값으로 저장할 컴팩트 JSON(키에 book/chapter/verse가 이미 들어있다).
  Map<String, dynamic> toJson() => {
        if (color != null) 'c': color,
        if (bookmarked) 'b': true,
        if (hasNote) 'n': note,
        't': updatedAt.toIso8601String(),
      };

  factory VerseAnnotation.fromKey(String key, Map<String, dynamic> json) {
    final parts = key.split(':');
    return VerseAnnotation(
      bookIndex: int.parse(parts[0]),
      chapter: int.parse(parts[1]),
      verse: int.parse(parts[2]),
      color: (json['c'] as num?)?.toInt(),
      bookmarked: json['b'] as bool? ?? false,
      note: json['n'] as String?,
      updatedAt: DateTime.tryParse(json['t'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VerseAnnotation &&
      other.bookIndex == bookIndex &&
      other.chapter == chapter &&
      other.verse == verse &&
      other.color == color &&
      other.bookmarked == bookmarked &&
      other.note == note &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(bookIndex, chapter, verse, color, bookmarked, note, updatedAt);
}

/// 하이라이트용 부드러운 색 팔레트(밝은/세피아/어두운 리더 배경 모두에서 가독).
class AnnotationPalette {
  AnnotationPalette._();

  static const List<int> colors = [
    0xFFFFE08A, // 노랑
    0xFFB8E0A0, // 연두
    0xFFA9D4F0, // 하늘
    0xFFF3B6C6, // 분홍
    0xFFE9C9A8, // 베이지
  ];
}
