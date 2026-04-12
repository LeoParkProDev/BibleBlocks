enum Testament { old, new_ }

class BibleBook {
  final int index;
  final String name;
  final String nameEn;
  final int chapters;
  final Testament testament;

  const BibleBook({
    required this.index,
    required this.name,
    required this.nameEn,
    required this.chapters,
    required this.testament,
  });
}

class BibleData {
  static const int totalChapters = 1189;
  static const int totalBooks = 66;
  static const int oldTestamentBooks = 39;
  static const int newTestamentBooks = 27;

  static const List<BibleBook> books = [
    // 구약 (39권)
    BibleBook(index: 0, name: '창세기', nameEn: 'Genesis', chapters: 50, testament: Testament.old),
    BibleBook(index: 1, name: '출애굽기', nameEn: 'Exodus', chapters: 40, testament: Testament.old),
    BibleBook(index: 2, name: '레위기', nameEn: 'Leviticus', chapters: 27, testament: Testament.old),
    BibleBook(index: 3, name: '민수기', nameEn: 'Numbers', chapters: 36, testament: Testament.old),
    BibleBook(index: 4, name: '신명기', nameEn: 'Deuteronomy', chapters: 34, testament: Testament.old),
    BibleBook(index: 5, name: '여호수아', nameEn: 'Joshua', chapters: 24, testament: Testament.old),
    BibleBook(index: 6, name: '사사기', nameEn: 'Judges', chapters: 21, testament: Testament.old),
    BibleBook(index: 7, name: '룻기', nameEn: 'Ruth', chapters: 4, testament: Testament.old),
    BibleBook(index: 8, name: '사무엘상', nameEn: '1 Samuel', chapters: 31, testament: Testament.old),
    BibleBook(index: 9, name: '사무엘하', nameEn: '2 Samuel', chapters: 24, testament: Testament.old),
    BibleBook(index: 10, name: '열왕기상', nameEn: '1 Kings', chapters: 22, testament: Testament.old),
    BibleBook(index: 11, name: '열왕기하', nameEn: '2 Kings', chapters: 25, testament: Testament.old),
    BibleBook(index: 12, name: '역대상', nameEn: '1 Chronicles', chapters: 29, testament: Testament.old),
    BibleBook(index: 13, name: '역대하', nameEn: '2 Chronicles', chapters: 36, testament: Testament.old),
    BibleBook(index: 14, name: '에스라', nameEn: 'Ezra', chapters: 10, testament: Testament.old),
    BibleBook(index: 15, name: '느헤미야', nameEn: 'Nehemiah', chapters: 13, testament: Testament.old),
    BibleBook(index: 16, name: '에스더', nameEn: 'Esther', chapters: 10, testament: Testament.old),
    BibleBook(index: 17, name: '욥기', nameEn: 'Job', chapters: 42, testament: Testament.old),
    BibleBook(index: 18, name: '시편', nameEn: 'Psalms', chapters: 150, testament: Testament.old),
    BibleBook(index: 19, name: '잠언', nameEn: 'Proverbs', chapters: 31, testament: Testament.old),
    BibleBook(index: 20, name: '전도서', nameEn: 'Ecclesiastes', chapters: 12, testament: Testament.old),
    BibleBook(index: 21, name: '아가', nameEn: 'Song of Solomon', chapters: 8, testament: Testament.old),
    BibleBook(index: 22, name: '이사야', nameEn: 'Isaiah', chapters: 66, testament: Testament.old),
    BibleBook(index: 23, name: '예레미야', nameEn: 'Jeremiah', chapters: 52, testament: Testament.old),
    BibleBook(index: 24, name: '예레미야애가', nameEn: 'Lamentations', chapters: 5, testament: Testament.old),
    BibleBook(index: 25, name: '에스겔', nameEn: 'Ezekiel', chapters: 48, testament: Testament.old),
    BibleBook(index: 26, name: '다니엘', nameEn: 'Daniel', chapters: 12, testament: Testament.old),
    BibleBook(index: 27, name: '호세아', nameEn: 'Hosea', chapters: 14, testament: Testament.old),
    BibleBook(index: 28, name: '요엘', nameEn: 'Joel', chapters: 3, testament: Testament.old),
    BibleBook(index: 29, name: '아모스', nameEn: 'Amos', chapters: 9, testament: Testament.old),
    BibleBook(index: 30, name: '오바댜', nameEn: 'Obadiah', chapters: 1, testament: Testament.old),
    BibleBook(index: 31, name: '요나', nameEn: 'Jonah', chapters: 4, testament: Testament.old),
    BibleBook(index: 32, name: '미가', nameEn: 'Micah', chapters: 7, testament: Testament.old),
    BibleBook(index: 33, name: '나훔', nameEn: 'Nahum', chapters: 3, testament: Testament.old),
    BibleBook(index: 34, name: '하박국', nameEn: 'Habakkuk', chapters: 3, testament: Testament.old),
    BibleBook(index: 35, name: '스바냐', nameEn: 'Zephaniah', chapters: 3, testament: Testament.old),
    BibleBook(index: 36, name: '학개', nameEn: 'Haggai', chapters: 2, testament: Testament.old),
    BibleBook(index: 37, name: '스가랴', nameEn: 'Zechariah', chapters: 14, testament: Testament.old),
    BibleBook(index: 38, name: '말라기', nameEn: 'Malachi', chapters: 4, testament: Testament.old),
    // 신약 (27권)
    BibleBook(index: 39, name: '마태복음', nameEn: 'Matthew', chapters: 28, testament: Testament.new_),
    BibleBook(index: 40, name: '마가복음', nameEn: 'Mark', chapters: 16, testament: Testament.new_),
    BibleBook(index: 41, name: '누가복음', nameEn: 'Luke', chapters: 24, testament: Testament.new_),
    BibleBook(index: 42, name: '요한복음', nameEn: 'John', chapters: 21, testament: Testament.new_),
    BibleBook(index: 43, name: '사도행전', nameEn: 'Acts', chapters: 28, testament: Testament.new_),
    BibleBook(index: 44, name: '로마서', nameEn: 'Romans', chapters: 16, testament: Testament.new_),
    BibleBook(index: 45, name: '고린도전서', nameEn: '1 Corinthians', chapters: 16, testament: Testament.new_),
    BibleBook(index: 46, name: '고린도후서', nameEn: '2 Corinthians', chapters: 13, testament: Testament.new_),
    BibleBook(index: 47, name: '갈라디아서', nameEn: 'Galatians', chapters: 6, testament: Testament.new_),
    BibleBook(index: 48, name: '에베소서', nameEn: 'Ephesians', chapters: 6, testament: Testament.new_),
    BibleBook(index: 49, name: '빌립보서', nameEn: 'Philippians', chapters: 4, testament: Testament.new_),
    BibleBook(index: 50, name: '골로새서', nameEn: 'Colossians', chapters: 4, testament: Testament.new_),
    BibleBook(index: 51, name: '데살로니가전서', nameEn: '1 Thessalonians', chapters: 5, testament: Testament.new_),
    BibleBook(index: 52, name: '데살로니가후서', nameEn: '2 Thessalonians', chapters: 3, testament: Testament.new_),
    BibleBook(index: 53, name: '디모데전서', nameEn: '1 Timothy', chapters: 6, testament: Testament.new_),
    BibleBook(index: 54, name: '디모데후서', nameEn: '2 Timothy', chapters: 4, testament: Testament.new_),
    BibleBook(index: 55, name: '디도서', nameEn: 'Titus', chapters: 3, testament: Testament.new_),
    BibleBook(index: 56, name: '빌레몬서', nameEn: 'Philemon', chapters: 1, testament: Testament.new_),
    BibleBook(index: 57, name: '히브리서', nameEn: 'Hebrews', chapters: 13, testament: Testament.new_),
    BibleBook(index: 58, name: '야고보서', nameEn: 'James', chapters: 5, testament: Testament.new_),
    BibleBook(index: 59, name: '베드로전서', nameEn: '1 Peter', chapters: 5, testament: Testament.new_),
    BibleBook(index: 60, name: '베드로후서', nameEn: '2 Peter', chapters: 3, testament: Testament.new_),
    BibleBook(index: 61, name: '요한1서', nameEn: '1 John', chapters: 5, testament: Testament.new_),
    BibleBook(index: 62, name: '요한2서', nameEn: '2 John', chapters: 1, testament: Testament.new_),
    BibleBook(index: 63, name: '요한3서', nameEn: '3 John', chapters: 1, testament: Testament.new_),
    BibleBook(index: 64, name: '유다서', nameEn: 'Jude', chapters: 1, testament: Testament.new_),
    BibleBook(index: 65, name: '요한계시록', nameEn: 'Revelation', chapters: 22, testament: Testament.new_),
  ];

  /// 특정 책의 시작 장 인덱스 (전체 1189장 중)
  static int chapterOffset(int bookIndex) {
    int offset = 0;
    for (int i = 0; i < bookIndex; i++) {
      offset += books[i].chapters;
    }
    return offset;
  }

  /// 전역 장 인덱스(0~1188)에서 (bookIndex, chapter) 반환
  static (int bookIndex, int chapter) fromGlobalIndex(int globalIndex) {
    int remaining = globalIndex;
    for (final book in books) {
      if (remaining < book.chapters) {
        return (book.index, remaining + 1);
      }
      remaining -= book.chapters;
    }
    return (65, 22); // fallback: 마지막 장
  }
}
