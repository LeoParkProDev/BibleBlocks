# 설계: 개역한글 본문 리더 통합

**날짜:** 2026-06-09
**상태:** 승인됨 (구현 대기)

## 배경 / 목적

BibleBlocks는 현재 1,189장을 체크만 할 수 있고 실제 성경 본문이 없다. 사용자가 **앱 안에서 직접 성경을 읽고**, 다 읽으면 그 자리에서 읽음 체크하는 흐름을 만든다.

번역본은 **개역한글(성경전서 개역한글판, 1961)** 로 확정. 이유: 저작재산권 50년 경과로 **퍼블릭 도메인**이라 라이선스료·계약 없이 합법적으로 번들 가능. (개역개정·새번역·현대인의성경 등은 대한성서공회/생명의말씀사 저작권 보호 중 — 유료 라이선스 필요하므로 이번 범위 제외.)

개역한글 사용 조건: 저작권료 없음. 단 **성명표시권**(출처 "성경전서 개역한글판, 대한성서공회" 표기)과 **동일성유지권**(본문 무단 변경 금지)만 준수.

## 사용자 흐름

```
체크리스트 → 책 펼침 → 장 번호 탭
        ↓
[리더 화면] 개역한글 본문 표시 (예: 창세기 1장)
        ↓ 끝까지 스크롤
하단에 "✓ 이 장 읽음 완료" 버튼 등장 → 탭
        ↓
읽음 처리 + 다음 장으로 자동 이동 (마지막 장이면 완료 상태)

· 장 번호 길게 누르기 = 리더 없이 즉시 읽음 토글 (기존 패턴 유지)
· 이미 읽은 장을 열면: 버튼이 "✓ 읽음 (탭하여 해제)" 상태로 바로 표시
```

## 아키텍처 결정: 접근법 A (책별 분할 JSON 번들 + 지연 로드)

성경 읽기 앱은 오프라인이 사실상 필수(지하철·교회 와이파이·비행기)이고, 개역한글은 퍼블릭 도메인이라 번들이 가장 깔끔한 합법 사용이다. 외부 API 의존(다운타임·레이트리밋·웹 CORS)을 피한다. 추가 서버 비용 0 — 기존 Vercel 정적 호스팅으로 충분.

- 모바일(Android/iOS): 66개 파일이 앱 번들에 포함 → 완전 오프라인
- 웹(Vercel): `rootBundle`이 동일 출처에서 HTTP로 받음 → CORS 없음, **사용자가 연 책만** 다운로드, 브라우저 캐시

## 데이터 구조 & 저장

- `assets/bible/krv/0.json` ~ `65.json` — 책 인덱스별 66개 파일 (기존 `lib/data/bible_data.dart`의 `BibleData.books` index와 일치)
- 각 파일 형식:
  ```json
  {
    "book": 0,
    "chapters": [
      ["태초에 하나님이 천지를 창조하시니라", "땅이 혼돈하고 공허하며 ...", "..."],
      ["..."]
    ]
  }
  ```
  - `chapters[c-1]` = c장, 그 안의 배열 인덱스 `v-1` = v절
- `pubspec.yaml`의 `flutter.assets`에 `assets/bible/krv/` 등록

## 컴포넌트

### `lib/services/bible_text_service.dart` — `BibleTextService`
- 역할: 책 단위 JSON을 lazy load + 메모리 캐시
- 인터페이스:
  - `Future<List<List<String>>> loadBook(int bookIndex)` — 책 전체(장→절) 로드, `Map<int, ...>` 캐시
  - `Future<List<String>> loadChapter(int bookIndex, int chapter)` — 특정 장 절 배열
- 의존: `rootBundle`, `dart:convert`
- 오류: 범위 밖 인덱스/장 → 명확한 예외(`ArgumentError` 또는 `RangeError`), 조용한 실패 금지

### `lib/providers/bible_text_provider.dart`
- `chapterTextProvider` = `FutureProvider.family<List<String>, (int book, int chapter)>` — `BibleTextService.loadChapter` 호출

### `lib/screens/reader/reader_screen.dart` — `ReaderScreen`
- 입력: `bookIndex`, `chapter`
- AppBar: `${book.name} ${chapter}장` + 이전/다음 장 화살표 (책 경계 넘으면 이전/다음 책으로 이동, 첫 책 1장·마지막 책 끝장에서는 비활성)
- 본문: 절 번호 위첨자 + 개역한글 텍스트. `Center > ConstrainedBox(maxWidth: 600)` (프로젝트 반응형 규칙)
- `ScrollController`로 끝 도달 감지 → 하단에 "✓ 이 장 읽음 완료" 버튼 등장
  - 이미 읽은 장이면 버튼이 "✓ 읽음 · 탭하여 해제" 상태로 즉시 표시(스크롤 불필요)
- 버튼 탭 → `progressProvider.notifier.toggleChapter(bookIndex, chapter)` → 다음 장으로 자동 이동(슬라이드 전환). 마지막 장이면 완료 표시 후 체크리스트로 복귀 옵션
- 하단 저작권 표기: **"성경전서 개역한글판 · 대한성서공회"** (성명표시권)

### `lib/screens/checklist/checklist_screen.dart` 변경
- `_buildChapterGrid`의 장 칸:
  - `onTap`: (기존 토글 제거) → `context.push('/reader/$bookIndex/$chapter')`
  - `onLongPress` 추가: `HapticFeedback` + `toggleChapter` (리더 없이 빠른 체크)
- 책 헤더 길게 누르기(전체 토글)는 그대로 유지

### `lib/config/router.dart` 변경
- 3탭 StatefulShellRoute 위 최상위 라우트 `/reader/:book/:chapter` 추가 (탭바 가려지는 전체화면 push)
- 파라미터 파싱·범위 검증

## 데이터 소싱 & 검증 (🔴 가장 중요)

- 공개 저장소(예: `laisiangtho/bible`, `thiagobodruk/bible`)에서 **개역한글(KRV 1961)** 데이터 확보
- **필수 검증: 받은 데이터가 진짜 개역한글(1961, 퍼블릭 도메인)인지 확인.** 개역개정(1998)은 대한성서공회 저작권이라 절대 섞이면 안 됨.
  - 판별: 알려진 개역한글 표현으로 대조 (예: 창 1:1 "태초에 하나님이 천지를 창조하시니라", 개역한글 특유의 고어체 표기)
- 데이터 무결성 자동 검사: 66권 × 각 책 장수 합 = **정확히 1,189장**, `BibleData.books[i].chapters`와 책별 장수 일치, 각 장 절 배열 비어있지 않음
- 변환 스크립트(원본 → `assets/bible/krv/{i}.json`)는 1회용이라도 저장소에 남겨 재현 가능하게 함

## 테스트

- `BibleTextService` 단위 테스트: 책 로드 성공, 캐시 동작(2회 호출 시 1회만 디스크 접근), 범위 밖 인덱스/장 예외
- 데이터 무결성 테스트: 66권 로드 → 총 1,189장, 책별 장수가 `BibleData`와 일치, 빈 절 없음
- `ReaderScreen` 위젯 테스트: 본문 렌더, 끝까지 스크롤 → 버튼 등장 → 탭 → `progressProvider` 반영, 이미 읽은 장은 버튼 즉시 표시
- `flutter analyze` 무경고

## 범위 밖 (YAGNI — 추후)

본문 검색, 다중 번역본, 하이라이트/메모, 글꼴 크기 설정, TTS, 절 단위 공유 — 이번 범위 제외.

## 미해결/구현 중 결정할 세부

- "끝까지 스크롤" 감지 임계값(예: maxScrollExtent - 40px) — 구현 시 체감 조정
- 다음 장 자동 이동 전환 애니메이션 방식(슬라이드/페이드) — 구현 시 결정
- 절 번호 스타일(위첨자 크기/색) — 테라코타 테마에 맞춰 구현 시 조정
