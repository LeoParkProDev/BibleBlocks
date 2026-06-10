# 개역한글 본문 리더 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 체크리스트에서 장을 탭하면 개역한글 본문 리더가 열리고, 끝까지 읽으면 그 자리에서 읽음 체크되는 흐름을 만든다.

**Architecture:** 개역한글(퍼블릭 도메인) 전문을 책별 JSON 66개로 `assets/bible/krv/`에 번들(접근법 A) → 모바일 오프라인, 웹은 연 책만 다운로드. `BibleTextService`가 lazy load + 캐시, `chapterTextProvider`(Riverpod)로 노출, `ReaderScreen`이 렌더. 리더는 go_router 루트 최상위 라우트.

**Tech Stack:** Flutter, Riverpod 3.x (AsyncNotifier/FutureProvider.family), go_router(StatefulShellRoute), rootBundle 에셋, Dart 변환 스크립트.

**데이터 소스(확정):** `https://raw.githubusercontent.com/thiagobodruk/bible/master/json/ko_ko.json`
- 구조: `[{"abbrev":"gn","chapters":[["1절","2절",...], ...]}, ... 66권]`
- 검증됨: 창 1:2 = "하나님의 신(神)은 수면에 운행하시니라" → **개역한글**(개역개정은 "영…수면 위에")
- 잔여 표기: 선두 BOM(`﻿`), 일부 절 끝 " !" 강조, 한자 병기 `(神)` — 변환 시 BOM·앞뒤 공백만 제거, 본문은 동일성유지권 위해 그대로 보존

---

### Task 1: 개역한글 데이터 → 책별 JSON 에셋 (검증 우선)

**Files:**
- Test: `test/data/krv_integrity_test.dart`
- Create: `tool/build_krv_assets.dart`
- Create(생성물): `assets/bible/krv/0.json` … `assets/bible/krv/65.json`
- Modify: `pubspec.yaml` (flutter.assets)

- [ ] **Step 1: 무결성 테스트 작성 (실패 예정)**

`test/data/krv_integrity_test.dart`:
```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bible_blocks/data/bible_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Map<String, dynamic>> loadBook(int i) async {
    final raw = await rootBundle.loadString('assets/bible/krv/$i.json');
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  test('66권이 모두 존재하고 총 1189장', () async {
    var total = 0;
    for (var i = 0; i < BibleData.totalBooks; i++) {
      final book = await loadBook(i);
      final chapters = book['chapters'] as List;
      expect(chapters.length, BibleData.books[i].chapters,
          reason: '${BibleData.books[i].name} 장수 불일치');
      total += chapters.length;
    }
    expect(total, BibleData.totalChapters); // 1189
  });

  test('빈 장/빈 절이 없다', () async {
    for (var i = 0; i < BibleData.totalBooks; i++) {
      final chapters = (await loadBook(i))['chapters'] as List;
      for (final ch in chapters) {
        expect((ch as List).isNotEmpty, true);
        for (final v in ch) {
          expect((v as String).trim().isNotEmpty, true);
        }
      }
    }
  });

  test('개역한글 식별: 창 1:2는 개역한글 표현이어야 한다', () async {
    final gen = await loadBook(0);
    final v2 = ((gen['chapters'] as List)[0] as List)[1] as String;
    expect(v2.contains('신'), true);       // 개역한글 "하나님의 신"
    expect(v2.contains('수면에'), true);    // 개역한글 "수면에"
    expect(v2.contains('하나님의 영'), false); // 개역개정 표현 아님
  });
}
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

Run: `flutter test test/data/krv_integrity_test.dart`
Expected: FAIL — `Unable to load asset: assets/bible/krv/0.json`

- [ ] **Step 3: 원본 데이터 내려받기**

Run:
```bash
mkdir -p tool assets/bible/krv
curl -sL "https://raw.githubusercontent.com/thiagobodruk/bible/master/json/ko_ko.json" -o tool/ko_ko_source.json
test -s tool/ko_ko_source.json && echo "downloaded $(wc -c < tool/ko_ko_source.json) bytes"
```
Expected: 수 MB 다운로드. (실패 시 대체 소스: `laisiangtho/bible`의 KRV)

- [ ] **Step 4: 변환 스크립트 작성**

`tool/build_krv_assets.dart`:
```dart
// 사용법: dart run tool/build_krv_assets.dart
// tool/ko_ko_source.json(개역한글, thiagobodruk 형식)을 책별 assets/bible/krv/{i}.json으로 변환.
import 'dart:convert';
import 'dart:io';
import 'package:bible_blocks/data/bible_data.dart';

void main() {
  final srcFile = File('tool/ko_ko_source.json');
  var text = srcFile.readAsStringSync();
  if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
    text = text.substring(1); // BOM 제거
  }
  final books = jsonDecode(text) as List;
  if (books.length != BibleData.totalBooks) {
    throw StateError('책 수 ${books.length} != ${BibleData.totalBooks}');
  }

  final outDir = Directory('assets/bible/krv')..createSync(recursive: true);
  for (var i = 0; i < books.length; i++) {
    final chaptersRaw = (books[i] as Map)['chapters'] as List;
    if (chaptersRaw.length != BibleData.books[i].chapters) {
      throw StateError(
          '${BibleData.books[i].name}: ${chaptersRaw.length} != ${BibleData.books[i].chapters}');
    }
    final chapters = chaptersRaw
        .map((ch) => (ch as List).map((v) => (v as String).trim()).toList())
        .toList();
    final out = {'book': i, 'chapters': chapters};
    File('${outDir.path}/$i.json')
        .writeAsStringSync(jsonEncode(out));
  }
  stdout.writeln('변환 완료: ${books.length}권');
}
```

- [ ] **Step 5: 변환 실행**

Run: `dart run tool/build_krv_assets.dart`
Expected: `변환 완료: 66권`, `assets/bible/krv/0.json`~`65.json` 생성. 장수 불일치 시 StateError로 중단(데이터 정렬 문제 조기 발견).

- [ ] **Step 6: pubspec.yaml에 에셋 등록**

`pubspec.yaml`의 `flutter:` 섹션 `assets:` 하위에 추가:
```yaml
    - assets/bible/krv/
```
(기존 assets 항목이 없으면 `uses-material-design: true` 아래에 `assets:` 키부터 추가)

- [ ] **Step 7: 무결성 테스트 재실행 → 통과**

Run: `flutter test test/data/krv_integrity_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 8: 커밋**

```bash
git add tool/build_krv_assets.dart assets/bible/krv/ pubspec.yaml test/data/krv_integrity_test.dart
git commit -m "feat: 개역한글 본문 데이터 번들 + 무결성 테스트"
```
(주의: `tool/ko_ko_source.json`은 커밋하지 않음 — 변환 산출물만)

---

### Task 2: BibleTextService (lazy load + 캐시)

**Files:**
- Test: `test/services/bible_text_service_test.dart`
- Create: `lib/services/bible_text_service.dart`

- [ ] **Step 1: 테스트 작성 (실패 예정)**

`test/services/bible_text_service_test.dart`:
```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bible_blocks/services/bible_text_service.dart';

/// loadString 호출 횟수를 세는 가짜 번들
class _CountingBundle extends CachingAssetBundle {
  int loadCount = 0;
  @override
  Future<ByteData> load(String key) async {
    loadCount++;
    final json = jsonEncode({
      'book': 0,
      'chapters': [
        ['창 1:1 본문', '창 1:2 본문'],
        ['창 2:1 본문'],
      ],
    });
    final bytes = utf8.encode(json);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

void main() {
  test('loadChapter는 해당 장의 절 배열을 반환', () async {
    final svc = BibleTextService(bundle: _CountingBundle());
    final ch1 = await svc.loadChapter(0, 1);
    expect(ch1, ['창 1:1 본문', '창 1:2 본문']);
  });

  test('같은 책 재요청 시 디스크는 1회만 읽는다 (캐시)', () async {
    final bundle = _CountingBundle();
    final svc = BibleTextService(bundle: bundle);
    await svc.loadChapter(0, 1);
    await svc.loadChapter(0, 2);
    expect(bundle.loadCount, 1);
  });

  test('범위 밖 장은 RangeError', () async {
    final svc = BibleTextService(bundle: _CountingBundle());
    expect(() => svc.loadChapter(0, 99), throwsRangeError);
  });
}
```

- [ ] **Step 2: 실행 → 실패 확인**

Run: `flutter test test/services/bible_text_service_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../bible_text_service.dart'`

- [ ] **Step 3: 서비스 구현**

`lib/services/bible_text_service.dart`:
```dart
import 'dart:convert';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import '../data/bible_data.dart';

/// 개역한글 본문을 책 단위로 lazy load + 메모리 캐시한다.
class BibleTextService {
  BibleTextService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  final Map<int, List<List<String>>> _cache = {};

  /// 책 전체를 [장][절] 형태로 반환.
  Future<List<List<String>>> loadBook(int bookIndex) async {
    if (bookIndex < 0 || bookIndex >= BibleData.totalBooks) {
      throw RangeError.range(bookIndex, 0, BibleData.totalBooks - 1, 'bookIndex');
    }
    final cached = _cache[bookIndex];
    if (cached != null) return cached;
    final raw = await _bundle.loadString('assets/bible/krv/$bookIndex.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final chapters = (json['chapters'] as List)
        .map((c) => (c as List).map((v) => v as String).toList())
        .toList();
    _cache[bookIndex] = chapters;
    return chapters;
  }

  /// 1-기반 장 번호의 절 배열 반환.
  Future<List<String>> loadChapter(int bookIndex, int chapter) async {
    final book = await loadBook(bookIndex);
    if (chapter < 1 || chapter > book.length) {
      throw RangeError.range(chapter, 1, book.length, 'chapter');
    }
    return book[chapter - 1];
  }
}
```

- [ ] **Step 4: 실행 → 통과**

Run: `flutter test test/services/bible_text_service_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: 커밋**

```bash
git add lib/services/bible_text_service.dart test/services/bible_text_service_test.dart
git commit -m "feat: BibleTextService 책별 본문 로더 + 캐시"
```

---

### Task 3: chapterTextProvider

**Files:**
- Create: `lib/providers/bible_text_provider.dart`
- Test: `test/providers/bible_text_provider_test.dart`

- [ ] **Step 1: 테스트 작성 (실패 예정)**

`test/providers/bible_text_provider_test.dart`:
```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bible_blocks/services/bible_text_service.dart';
import 'package:bible_blocks/providers/bible_text_provider.dart';

class _FakeService extends BibleTextService {
  _FakeService() : super(bundle: rootBundle);
  @override
  Future<List<String>> loadChapter(int b, int c) async => ['절1', '절2'];
}

void main() {
  test('chapterTextProvider는 서비스의 절 배열을 반환', () async {
    final container = ProviderContainer(overrides: [
      bibleTextServiceProvider.overrideWithValue(_FakeService()),
    ]);
    addTearDown(container.dispose);
    final verses =
        await container.read(chapterTextProvider((book: 0, chapter: 1)).future);
    expect(verses, ['절1', '절2']);
  });
}
```

- [ ] **Step 2: 실행 → 실패 확인**

Run: `flutter test test/providers/bible_text_provider_test.dart`
Expected: FAIL — provider 파일 없음

- [ ] **Step 3: 프로바이더 구현**

`lib/providers/bible_text_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bible_text_service.dart';

final bibleTextServiceProvider =
    Provider<BibleTextService>((ref) => BibleTextService());

/// (book, chapter) → 절 배열
final chapterTextProvider =
    FutureProvider.family<List<String>, ({int book, int chapter})>((ref, key) {
  return ref.watch(bibleTextServiceProvider).loadChapter(key.book, key.chapter);
});
```

- [ ] **Step 4: 실행 → 통과**

Run: `flutter test test/providers/bible_text_provider_test.dart`
Expected: PASS

- [ ] **Step 5: 커밋**

```bash
git add lib/providers/bible_text_provider.dart test/providers/bible_text_provider_test.dart
git commit -m "feat: chapterTextProvider 추가"
```

---

### Task 4: ReaderScreen (본문 + 스크롤 끝 읽음 버튼 + 장 이동)

**Files:**
- Create: `lib/screens/reader/reader_screen.dart`
- Test: `test/screens/reader_screen_test.dart`

- [ ] **Step 1: 위젯 테스트 작성 (실패 예정)**

`test/screens/reader_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bible_blocks/services/bible_text_service.dart';
import 'package:bible_blocks/providers/bible_text_provider.dart';
import 'package:bible_blocks/providers/progress_provider.dart';
import 'package:bible_blocks/screens/reader/reader_screen.dart';

class _FakeService extends BibleTextService {
  _FakeService() : super(bundle: rootBundle);
  @override
  Future<List<String>> loadChapter(int b, int c) async =>
      List.generate(40, (i) => '${i + 1}절 본문 텍스트');
}

// 읽음 상태를 제어 가능한 가짜 progress notifier
class _FakeProgress extends ProgressNotifier {
  _FakeProgress(this._data);
  final Map<int, Set<int>> _data;
  @override
  Future<Map<int, Set<int>>> build() async => _data;
  @override
  Future<void> toggleChapter(int b, int c) async {
    final set = _data.putIfAbsent(b, () => {});
    set.contains(c) ? set.remove(c) : set.add(c);
    state = AsyncValue.data({..._data});
  }
}

Widget _wrap(Map<int, Set<int>> initial) => ProviderScope(
      overrides: [
        bibleTextServiceProvider.overrideWithValue(_FakeService()),
        progressProvider.overrideWith(() => _FakeProgress(initial)),
      ],
      child: const MaterialApp(home: ReaderScreen(bookIndex: 0, chapter: 1)),
    );

void main() {
  testWidgets('본문 절이 렌더된다', (tester) async {
    await tester.pumpWidget(_wrap({}));
    await tester.pumpAndSettle();
    expect(find.textContaining('1절 본문 텍스트'), findsOneWidget);
  });

  testWidgets('처음엔 읽음 버튼이 없고, 끝까지 스크롤하면 등장', (tester) async {
    await tester.pumpWidget(_wrap({}));
    await tester.pumpAndSettle();
    expect(find.text('✓ 이 장 읽음 완료'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('✓ 이 장 읽음 완료'), findsOneWidget);
  });

  testWidgets('이미 읽은 장은 버튼이 즉시 표시', (tester) async {
    await tester.pumpWidget(_wrap({0: {1}}));
    await tester.pumpAndSettle();
    expect(find.textContaining('읽음'), findsWidgets);
  });
}
```

- [ ] **Step 2: 실행 → 실패 확인**

Run: `flutter test test/screens/reader_screen_test.dart`
Expected: FAIL — reader_screen.dart 없음

- [ ] **Step 3: ReaderScreen 구현**

`lib/screens/reader/reader_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/bible_data.dart';
import '../../providers/bible_text_provider.dart';
import '../../providers/progress_provider.dart';
import '../../theme/app_colors.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.bookIndex, required this.chapter});
  final int bookIndex;
  final int chapter;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _scroll = ScrollController();
  bool _reachedEnd = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_reachedEnd &&
        _scroll.hasClients &&
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 40) {
      setState(() => _reachedEnd = true);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  (int, int)? _adjacent(int delta) {
    var b = widget.bookIndex, c = widget.chapter + delta;
    if (c < 1) {
      if (b == 0) return null;
      b -= 1;
      c = BibleData.books[b].chapters;
    } else if (c > BibleData.books[b].chapters) {
      if (b >= BibleData.totalBooks - 1) return null;
      b += 1;
      c = 1;
    }
    return (b, c);
  }

  void _go(int delta) {
    final next = _adjacent(delta);
    if (next != null) {
      context.pushReplacement('/reader/${next.$1}/${next.$2}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = BibleData.books[widget.bookIndex];
    final textAsync = ref.watch(
        chapterTextProvider((book: widget.bookIndex, chapter: widget.chapter)));
    final isRead = (ref.watch(progressProvider).value ?? const {})[widget.bookIndex]
            ?.contains(widget.chapter) ??
        false;
    final showButton = _reachedEnd || isRead;

    return Scaffold(
      appBar: AppBar(
        title: Text('${book.name} ${widget.chapter}장'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _adjacent(-1) == null ? null : () => _go(-1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _adjacent(1) == null ? null : () => _go(1),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: textAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('본문을 불러오지 못했습니다: $e')),
            data: (verses) => ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: verses.length + 1,
              itemBuilder: (context, i) {
                if (i == verses.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      '성경전서 개역한글판 · 대한성서공회',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(
                      text: '${i + 1} ',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: verses[i],
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.7,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ])),
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: showButton
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton(
                  onPressed: () {
                    ref
                        .read(progressProvider.notifier)
                        .toggleChapter(widget.bookIndex, widget.chapter);
                    if (!isRead) _go(1); // 새로 읽음 처리 시 다음 장으로
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isRead ? AppColors.textSecondary : AppColors.primary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(isRead ? '✓ 읽음 · 탭하여 해제' : '✓ 이 장 읽음 완료'),
                ),
              ),
            )
          : null,
    );
  }
}
```

- [ ] **Step 4: 실행 → 통과**

Run: `flutter test test/screens/reader_screen_test.dart`
Expected: PASS (3 tests). (스크롤 임계값/`pumpAndSettle` 타이밍 미세조정 필요할 수 있음)

- [ ] **Step 5: 커밋**

```bash
git add lib/screens/reader/ test/screens/reader_screen_test.dart
git commit -m "feat: ReaderScreen 본문 리더 + 스크롤 끝 읽음 버튼 + 장 이동"
```

---

### Task 5: 라우터에 /reader 라우트 추가

**Files:**
- Modify: `lib/config/router.dart`

- [ ] **Step 1: import 추가**

`lib/config/router.dart` 상단 import 블록에 추가:
```dart
import '../screens/reader/reader_screen.dart';
```

- [ ] **Step 2: 최상위 라우트 추가**

`routes: [` 배열에서 `/login` GoRoute 다음(StatefulShellRoute 앞)에 추가:
```dart
      GoRoute(
        path: '/reader/:book/:chapter',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final book = int.tryParse(state.pathParameters['book'] ?? '') ?? 0;
          final chapter =
              int.tryParse(state.pathParameters['chapter'] ?? '') ?? 1;
          final safeBook = book.clamp(0, BibleData.totalBooks - 1);
          final safeChapter =
              chapter.clamp(1, BibleData.books[safeBook].chapters);
          return ReaderScreen(bookIndex: safeBook, chapter: safeChapter);
        },
      ),
```

- [ ] **Step 3: BibleData import 추가 (없으면)**

`lib/config/router.dart` 상단에 추가:
```dart
import '../data/bible_data.dart';
```

- [ ] **Step 4: 분석 통과 확인**

Run: `flutter analyze lib/config/router.dart`
Expected: No issues

- [ ] **Step 5: 커밋**

```bash
git add lib/config/router.dart
git commit -m "feat: /reader/:book/:chapter 라우트 추가"
```

---

### Task 6: 체크리스트 연동 (탭=리더, 길게=빠른 토글)

**Files:**
- Modify: `lib/screens/checklist/checklist_screen.dart` (`_buildChapterGrid`, line ~439-483)

- [ ] **Step 1: import 추가**

`lib/screens/checklist/checklist_screen.dart` 상단에 추가:
```dart
import 'package:go_router/go_router.dart';
```

- [ ] **Step 2: 장 칸 제스처 변경**

`_buildChapterGrid`의 `GestureDetector` 부분을 아래로 교체 (`onTap`을 리더 push로, `onLongPress` 추가):
```dart
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            context.push('/reader/${book.index}/$chapter');
          },
          onLongPress: () {
            HapticFeedback.selectionClick();
            ref
                .read(progressProvider.notifier)
                .toggleChapter(book.index, chapter);
          },
          child: AnimatedContainer(
```
(`HapticFeedback`는 이미 `package:flutter/services.dart` import 됨 — 확인)

- [ ] **Step 3: 분석 통과**

Run: `flutter analyze lib/screens/checklist/checklist_screen.dart`
Expected: No issues

- [ ] **Step 4: 수동 동작 확인 (선택)**

Run: `flutter run -d chrome` → 체크리스트 → 책 펼치고 장 탭 → 리더 열림 / 장 길게 누르면 즉시 체크 토글

- [ ] **Step 5: 커밋**

```bash
git add lib/screens/checklist/checklist_screen.dart
git commit -m "feat: 체크리스트 장 탭→리더 열기, 길게 누르기→빠른 읽음 토글"
```

---

### Task 7: 전체 검증

- [ ] **Step 1: 전체 테스트**

Run: `flutter test`
Expected: 전체 PASS

- [ ] **Step 2: 정적 분석**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 3: 최종 커밋 (필요 시)**

```bash
git add -A
git commit -m "test: 개역한글 리더 전체 검증 통과"
```

---

## 자체 검토

**스펙 커버리지:**
- 사용자 흐름(탭→리더→스크롤 끝 버튼→읽음+다음장) → Task 4, 6 ✓
- 길게 누르기 빠른 토글 → Task 6 ✓
- 접근법 A 책별 번들 + lazy load → Task 1, 2 ✓
- 데이터 검증(개역한글 식별, 1189장) → Task 1 ✓
- 저작권 표기(성명표시권) → Task 4 리더 푸터 ✓
- 라우팅 /reader → Task 5 ✓
- 테스트(서비스/무결성/리더) → Task 1,2,3,4,7 ✓
- 범위 밖(검색·다중역본 등) 제외 유지 ✓

**Placeholder 스캔:** 없음. 모든 코드 스텝에 실제 코드 포함.

**타입 일관성:** `BibleTextService({bundle})`, `loadChapter(int,int)`, `chapterTextProvider(({int book,int chapter}))`, `progressProvider.notifier.toggleChapter(int,int)`, `data[bookIndex]?.contains(chapter)` — Task 간 시그니처 일치 확인됨.
