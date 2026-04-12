# BibleBlocks 필수 테스트 시나리오 (50개)

> 각 시나리오는 `[카테고리-번호]` 형식으로 관리.
> 상태: `[x]` 전체 50개 구현 완료 (2026-04-13)
>
> **테스트 파일 매핑**:
> - A: `test/data/bible_data_test.dart`
> - B: `test/models/book_progress_test.dart`
> - C: `test/services/progress_service_test.dart`
> - D: `test/providers/progress_provider_test.dart`
> - E: `test/screens/checklist_screen_test.dart`
> - F: `test/screens/checklist_progress_test.dart`
> - G: `test/screens/bible_view_screen_test.dart`
> - H: `test/painters/isometric_bible_painter_test.dart`
> - I: `test/navigation_test.dart`
> - J: `test/edge_cases_test.dart`

---

## A. BibleData — 정적 데이터 무결성 (7개)

### A-01. 성경 66권 등록 확인
- **검증**: `BibleData.books.length == 66`
- **유형**: Unit

### A-02. 구약 39권 확인
- **검증**: `books.where(t == old).length == 39`
- **유형**: Unit

### A-03. 신약 27권 확인
- **검증**: `books.where(t == new_).length == 27`
- **유형**: Unit

### A-04. 전체 장 수 합계 1,189 확인
- **검증**: `books.map(b => b.chapters).sum == 1189 == BibleData.totalChapters`
- **유형**: Unit

### A-05. bookIndex 연속성 (0~65, 중복 없음)
- **검증**: `books[i].index == i` for all i
- **유형**: Unit

### A-06. chapterOffset — 첫 책은 0, 두 번째는 50 (창세기 50장)
- **검증**: `chapterOffset(0) == 0`, `chapterOffset(1) == 50`, `chapterOffset(65) == 1189 - 22`
- **유형**: Unit

### A-07. fromGlobalIndex 왕복 변환 (전체 1189장)
- **검증**: 모든 globalIndex 0~1188에 대해 `chapterOffset(bookIndex) + chapter - 1 == globalIndex`
- **유형**: Unit

---

## B. BookProgress 모델 (3개)

### B-01. Freezed 생성 — 기본 팩토리 정상 동작
- **검증**: `BookProgress(bookIndex: 0, updatedAt: now)` 생성, `chapters` 기본값 빈 Set
- **유형**: Unit

### B-02. JSON 직렬화 왕복
- **검증**: `BookProgress.fromJson(bp.toJson()) == bp`
- **유형**: Unit

### B-03. copyWith로 chapters 업데이트
- **검증**: `bp.copyWith(chapters: {1,2,3}).chapters == {1,2,3}`
- **유형**: Unit

---

## C. ProgressService — 로컬 저장소 (10개)

### C-01. 초기 로드 — 저장 데이터 없으면 빈 Map 반환
- **검증**: `loadAll()` → `{}`
- **유형**: Unit

### C-02. 장 체크 (토글 ON)
- **검증**: 빈 상태에서 `toggleChapter({}, 0, 1)` → `{0: {1}}`
- **유형**: Unit

### C-03. 장 체크 해제 (토글 OFF)
- **검증**: `{0: {1}}` 상태에서 `toggleChapter(data, 0, 1)` → `{}`
- **유형**: Unit

### C-04. 같은 책 여러 장 체크
- **검증**: 창세기 1,3,5장 순서대로 토글 → `{0: {1,3,5}}`
- **유형**: Unit

### C-05. 다른 책 동시 체크
- **검증**: 창세기 1장 + 마태복음 1장 → `{0: {1}, 39: {1}}`
- **유형**: Unit

### C-06. 마지막 장 해제 시 bookIndex 키 자체 삭제
- **검증**: `{0: {1}}`에서 1장 해제 → key `0` 자체가 Map에서 사라짐
- **유형**: Unit

### C-07. 저장 후 재로드 일관성
- **검증**: 토글 후 `loadAll()` 결과가 토글 반환값과 동일
- **유형**: Integration

### C-08. totalRead 정확도
- **검증**: `{0: {1,2,3}, 39: {1}}` → `totalRead == 4`
- **유형**: Unit

### C-09. totalRead 빈 데이터
- **검증**: `totalRead({}) == 0`
- **유형**: Unit

### C-10. isGlobalIndexRead — 읽은 장/안 읽은 장 판별
- **검증**: 창세기 1장(global=0) 읽음 → true, 창세기 2장(global=1) 안읽음 → false
- **유형**: Unit

---

## D. Providers — 상태 관리 (5개)

### D-01. progressProvider 초기 상태 AsyncLoading → AsyncData
- **검증**: 로딩 후 `AsyncValue.data({})` 상태
- **유형**: Unit (ProviderContainer)

### D-02. toggleChapter 호출 후 state 즉시 반영
- **검증**: `notifier.toggleChapter(0, 1)` → state에 `{0: {1}}` 반영
- **유형**: Unit (ProviderContainer)

### D-03. totalReadProvider 파생값 정확
- **검증**: 3장 체크 후 `totalReadProvider == 3`
- **유형**: Unit (ProviderContainer)

### D-04. overallProgressProvider 비율 계산
- **검증**: 0장 → `0.0`, 1189장 → `1.0`
- **유형**: Unit (ProviderContainer)

### D-05. 다중 토글 후 상태 일관성
- **검증**: 같은 장 ON→OFF→ON 반복 후 최종 상태 정확
- **유형**: Unit (ProviderContainer)

---

## E. 체크리스트 화면 — UI 렌더링 (10개)

### E-01. 화면 로드 시 "체크리스트" AppBar 타이틀 표시
- **검증**: `find.text('체크리스트')` 존재
- **유형**: Widget

### E-02. 초기 상태 진행률 "0 / 1,189장" + "0.0%" 표시
- **검증**: `find.text('0 / 1189장')`, `find.text('0.0%')`
- **유형**: Widget

### E-03. 필터 칩 4개 렌더링 (전체, 구약, 신약, 미완료)
- **검증**: 4개 텍스트 모두 존재
- **유형**: Widget

### E-04. 기본 필터 "전체" 선택 상태 — 66권 모두 표시
- **검증**: 리스트 아이템 수 66개
- **유형**: Widget

### E-05. "구약" 필터 → 39권만 표시
- **검증**: 필터 탭 후 리스트 아이템 수 39개
- **유형**: Widget

### E-06. "신약" 필터 → 27권만 표시
- **검증**: 필터 탭 후 리스트 아이템 수 27개
- **유형**: Widget

### E-07. 책 항목 탭 → 아코디언 펼침 (장 그리드 표시)
- **검증**: 창세기 탭 → 1~50 숫자 그리드 렌더링
- **유형**: Widget

### E-08. 이미 펼쳐진 책 다시 탭 → 접힘
- **검증**: 창세기 탭 → 그리드 표시 → 다시 탭 → 그리드 사라짐
- **유형**: Widget

### E-09. 장 번호 탭 → 체크 토글 (색상 변경)
- **검증**: "1" 탭 → 테라코타 배경 + 흰 텍스트
- **유형**: Widget

### E-10. 책 완독 시 아이콘 체크마크(✓)로 변경
- **검증**: 오바댜(1장) 완독 → 해당 행 아이콘이 `Icons.check`
- **유형**: Widget

---

## F. 체크리스트 화면 — 진행률 연동 (5개)

### F-01. 장 체크 시 상단 진행률 숫자 즉시 업데이트
- **검증**: 1장 체크 → "1 / 1189장" 표시
- **유형**: Widget

### F-02. 장 체크 시 퍼센트 즉시 업데이트
- **검증**: 1장 체크 → "0.1%" 표시
- **유형**: Widget

### F-03. 장 체크 시 해당 책 미니 프로그레스바 업데이트
- **검증**: 창세기 1장 체크 → 프로그레스바 value `1/50`
- **유형**: Widget

### F-04. "미완료" 필터 — 완독 책 제외
- **검증**: 오바댜 1장 완독 후 "미완료" 필터 → 오바댜 미표시 (65권)
- **유형**: Widget

### F-05. 장 그리드 7열 레이아웃 확인
- **검증**: `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7)`
- **유형**: Widget

---

## G. 3D 시각화 화면 — UI 렌더링 (4개)

### G-01. 화면 로드 시 다크 배경 (#0a0a1a) 적용
- **검증**: Scaffold `backgroundColor == AppColors.darkBg`
- **유형**: Widget

### G-02. 상단 "내 성경" 타이틀 + 진행률 뱃지 표시
- **검증**: "내 성경" 텍스트 + "0 / 1189" 텍스트 존재
- **유형**: Widget

### G-03. 하단 "핀치로 확대 · 드래그로 이동" 힌트 표시
- **검증**: 해당 텍스트 존재
- **유형**: Widget

### G-04. InteractiveViewer 존재 (줌/패닝 가능)
- **검증**: `find.byType(InteractiveViewer)` 존재
- **유형**: Widget

---

## H. IsometricBiblePainter — 렌더링 로직 (6개)

### H-01. 아이소메트릭 투영 함수 정확도
- **검증**: `_project(0,0,0,origin) == origin`, `_project(1,0,0,origin).dx > origin.dx`
- **유형**: Unit

### H-02. 전체 페이지 블록 수 = 192 (8×12×2)
- **검증**: `totalPageBlocks == 192`
- **유형**: Unit

### H-03. 십자가 위치 판별 (세로 바: x=3,4 / z=2~9)
- **검증**: `_isCrossPosition(3, 5) == true`, `_isCrossPosition(0, 0) == false`
- **유형**: Unit

### H-04. 십자가 위치 판별 (가로 바: z=5,6 / x=1~6)
- **검증**: `_isCrossPosition(1, 5) == true`, `_isCrossPosition(7, 5) == false`
- **유형**: Unit

### H-05. 빈 데이터 → shouldRepaint false (같은 데이터)
- **검증**: 동일한 `progressData` + `glowAnimation` → `shouldRepaint == false`
- **유형**: Unit

### H-06. 데이터 변경 시 shouldRepaint true
- **검증**: `progressData` 변경 → `shouldRepaint == true`
- **유형**: Unit

---

## I. 탭간 연동 / 내비게이션 (5개)

### I-01. 앱 시작 시 탭1 (내 성경) 표시
- **검증**: 초기 경로 `/bible`, BibleViewScreen 렌더링
- **유형**: Widget / Integration

### I-02. 탭2 (체크리스트) 전환
- **검증**: BottomNavigationBar 탭2 탭 → ChecklistScreen 렌더링
- **유형**: Widget

### I-03. 탭1↔탭2 전환 시 상태 유지 (StatefulShellRoute)
- **검증**: 탭2에서 장 체크 → 탭1 전환 → 탭2 복귀 → 체크 상태 유지
- **유형**: Widget / Integration

### I-04. 탭2에서 장 체크 → 탭1 진행률 뱃지 즉시 반영
- **검증**: 탭2에서 5장 체크 → 탭1 전환 → "5 / 1189" 표시
- **유형**: Integration

### I-05. BottomNavigationBar 아이템 2개 확인
- **검증**: "내 성경" + "체크리스트" 라벨 존재
- **유형**: Widget

---

## J. 엣지 케이스 / 경계값 (5개)

### J-01. 1장짜리 책 (오바댜/빌레몬/요한2서/요한3서/유다서) 완독 토글
- **검증**: 1장 체크 → 완독, 해제 → 미완독. 정상 토글
- **유형**: Unit + Widget

### J-02. 최대 장 수 책 (시편 150장) 전체 체크/해제
- **검증**: 150장 전부 체크 후 totalRead 150 증가, 전부 해제 시 원복
- **유형**: Unit

### J-03. 전체 1,189장 완독 시 완독 플래그
- **검증**: `_isComplete == true`, `overallProgressProvider == 1.0`
- **유형**: Unit + Integration

### J-04. 전역 인덱스 경계값: 0 (창세기 1장), 1188 (계시록 22장)
- **검증**: `fromGlobalIndex(0) == (0, 1)`, `fromGlobalIndex(1188) == (65, 22)`
- **유형**: Unit

### J-05. 범위 초과 전역 인덱스 → fallback (65, 22)
- **검증**: `fromGlobalIndex(1189) == (65, 22)`, `fromGlobalIndex(9999) == (65, 22)`
- **유형**: Unit

---

## 요약

| 카테고리 | 개수 | 유형 |
|---------|------|------|
| A. BibleData (정적 데이터) | 7 | Unit |
| B. BookProgress (모델) | 3 | Unit |
| C. ProgressService (저장소) | 10 | Unit / Integration |
| D. Providers (상태 관리) | 5 | Unit |
| E. 체크리스트 UI 렌더링 | 10 | Widget |
| F. 체크리스트 진행률 연동 | 5 | Widget |
| G. 3D 시각화 화면 UI | 4 | Widget |
| H. IsometricBiblePainter | 6 | Unit |
| I. 탭간 연동 / 내비게이션 | 5 | Widget / Integration |
| J. 엣지 케이스 / 경계값 | 5 | Unit / Integration |
| **합계** | **50** | |
