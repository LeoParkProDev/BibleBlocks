# BibleBlocks — 성경 읽기 시각화 앱

## Context
성경에 관심은 있지만 읽기 습관이 안 잡힌 초보자를 위한 앱. 성경 66권 1,189장을 체크하면 아이소메트릭 2.5D 성경책이 블록 단위로 채워지며, 앞표지에 금색 십자가가 인레이된 형태로 완성된다. 읽으면 보상이 눈에 보이는 동기부여 앱.

**핵심 차별점**: 체크할수록 3D 성경책이 물질화 — 구멍 메우고 싶은 심리가 읽기 동기부여

---

## 기술 스택
- **Flutter** (Android + iOS + Web)
- **Dart 3.11+**, Riverpod 3.x, go_router, Freezed
- **Firebase** (Auth + Firestore) — 진행도 클라우드 동기화
- **CustomPainter** — 아이소메트릭 2.5D 렌더링 (Rust/WASM 불필요)
- LeoTodos와 동일한 아키텍처 패턴 차용

---

## 앱 구조

### 탭 2개 (StatefulShellRoute)
| 탭 | 이름 | 기능 |
|----|------|------|
| 1 | 🏗️ 내 성경 | 아이소메트릭 3D 성경책 시각화 (진행도 반영) |
| 2 | ☑️ 체크리스트 | 66권 아코디언 리스트 + 장 번호 그리드 체크 |

성경 본문 읽기 기능 **없음** — 순수 진행도 추적 + 시각화

---

## S1. 데이터 모델

### BibleData (정적, 코드에 하드코딩)
```
성경 66권 목록 (이름, 장 수, 구약/신약 구분)
총 1,189장 → 각 장이 블록 1개에 1:1 매핑
```

### ReadingProgress (Firestore: `users/{uid}/progress/{bookIndex}`)
```dart
@freezed
abstract class BookProgress with _$BookProgress {
  const factory BookProgress({
    required int bookIndex,        // 0~65
    required Set<int> chapters,    // 읽은 장 번호들 {1, 3, 5, ...}
    required DateTime updatedAt,
  }) = _BookProgress;
}
```

**Firestore 구조**:
```
users/{uid}/progress/0   → { bookIndex: 0, chapters: [1,2,3,...50], updatedAt: ... }  // 창세기
users/{uid}/progress/1   → { bookIndex: 1, chapters: [1,5,10], updatedAt: ... }       // 출애굽기
```

---

## S2. 탭1 — 아이소메트릭 3D 성경책

### 렌더링 (CustomPainter)
- **블록 구성**: 성경책 형태 (가로 8 × 세로 12 × 두께 2 블록 단위)
  - 앞표지 (y=-1): 가죽 갈색 + 십자가 인레이 (금색)
  - 페이지 (y=0,1): 아이보리색
  - 뒷표지 (y=BD): 가죽 갈색
  - 책등 (x=-1): 진한 갈색
- **1,189장 → 페이지 블록에 순서대로 매핑** (창세기1장=블록0, 계시록22장=블록1188)
- **아이소메트릭 투영**: `(screenX, screenY) = (ox + (x-y)*0.866, oy + (x+y)*0.5 - z)`

### 채워지는 규칙
| 상태 | 렌더링 |
|------|--------|
| 안 읽은 장 | 와이어프레임 (반투명 선) |
| 읽은 장 | 불투명 블록 (해당 타입 색상) |
| **표지/책등** | 해당 위치의 페이지가 채워져야만 같이 물질화 |
| **십자가** | 해당 위치의 페이지가 채워져야만 금색 인레이 등장 |

### 완독 시 연출
- 십자가에서 금빛 글로우 + 빛줄기 + 파티클 애니메이션
- `AnimationController`로 반복 애니메이션

### 인터랙션
- `InteractiveViewer`: 줌/패닝
- 블록 탭 → 해당 책/장 정보 표시 (선택적)

---

## S3. 탭2 — 체크리스트

### 구조 (A+B 하이브리드)
1. **상단**: 전체 진행률 프로그레스바 (`done/1,189 (n%)`)
2. **필터 칩**: 전체 | 구약 | 신약 | 미완료
3. **66권 리스트**: 각 책마다:
   - 아이콘 (구/신 구분, 완료 시 ✓)
   - 책 이름 + `done/total장`
   - 미니 프로그레스바
   - 화살표 (▶/▼)
4. **탭하면 아코디언 펼침**: 장 번호 그리드 (7열)
   - 미완료: 흰 배경 + 보더
   - 완료: 테라코타 배경 + 흰 텍스트
   - 탭하면 토글 (읽음/안읽음)

### Firestore 연동
- 장 체크/해제 → Firestore 즉시 반영
- `StreamProvider`로 실시간 동기화
- 체크 시 탭1 블록도 실시간 업데이트

---

## S4. 디자인 테마

LeoTodos "테라코타 일몰" 변형:

| 역할 | HEX | 용도 |
|------|-----|------|
| 배경 | `#FAF8F5` | Scaffold |
| 카드/서피스 | `#FFFFFF` | 리스트 아이템 |
| 보더 | `#EDE9E3` | 구분선 |
| 텍스트 기본 | `#3D3529` | 제목 |
| 텍스트 보조 | `#A89F91` | 부제목 |
| Primary (테라코타) | `#C47B5A` | 체크 완료, 프로그레스바, 구약 |
| Secondary (블루그레이) | `#7A8E99` | 신약 아이콘 |
| Gold (십자가) | `#D4A843` | 십자가 인레이, 완독 연출 |

3D 뷰 배경: `#0a0a1a` (다크) — 블록이 돋보이도록

---

## S5. 인증

- Firebase Auth (Google Sign-In)
- 비로그인 시 로컬 SharedPreferences에 저장, 로그인 시 Firestore로 마이그레이션
- 설정 탭 없이 탭2 상단에 프로필 아이콘 → 로그인/로그아웃

---

## 프로젝트 구조

```
bible_blocks/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── config/
│   │   └── router.dart                    # go_router (2탭 ShellRoute)
│   ├── data/
│   │   └── bible_data.dart                # 66권 정적 데이터 (이름, 장수, 구약/신약)
│   ├── models/
│   │   └── book_progress.dart             # Freezed 모델
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   └── progress_provider.dart         # StreamProvider + 파생 프로바이더
│   ├── services/
│   │   ├── auth_service.dart
│   │   └── progress_service.dart          # Firestore CRUD
│   ├── screens/
│   │   ├── bible_view/
│   │   │   └── bible_view_screen.dart     # 탭1: 3D 시각화
│   │   └── checklist/
│   │       └── checklist_screen.dart      # 탭2: 체크리스트
│   ├── painters/
│   │   └── isometric_bible_painter.dart   # CustomPainter 핵심 렌더링
│   └── theme/
│       ├── app_colors.dart
│       └── app_theme.dart
├── pubspec.yaml
├── web/
├── android/
└── ios/
```

---

## 구현 순서

### Phase 1: 프로젝트 셋업 + 정적 데이터
1. `flutter create bible_blocks` (별도 프로젝트)
2. pubspec.yaml 의존성 추가
3. `bible_data.dart` — 66권 정적 데이터 작성
4. 테마 파일 (app_colors, app_theme)
5. go_router 2탭 셸 라우트

### Phase 2: 체크리스트 (탭2)
6. `BookProgress` Freezed 모델 + 코드 생성
7. `ProgressService` — 로컬 저장 (SharedPreferences, Firestore 연동은 Phase 4)
8. `progress_provider.dart` — 상태 관리
9. `checklist_screen.dart` — 아코디언 리스트 + 장 그리드 + 필터 + 프로그레스바

### Phase 3: 3D 시각화 (탭1)
10. `isometric_bible_painter.dart` — CustomPainter 핵심 렌더링
    - 아이소메트릭 투영 함수
    - 큐브 그리기 (top/left/right 면)
    - 와이어프레임 큐브
    - 블록 매핑 (1,189장 → 책 구조)
    - 표지/십자가 조건부 물질화
11. `bible_view_screen.dart` — InteractiveViewer + 진행률 오버레이
12. 완독 애니메이션 (글로우 + 파티클)

### Phase 4: Firebase 연동
13. Firebase 프로젝트 생성 + flutterfire configure
14. `auth_service.dart` + `auth_provider.dart`
15. `ProgressService` Firestore 연동 (로컬→클라우드 마이그레이션)
16. StreamProvider로 실시간 동기화

### Phase 5: 마무리
17. 앱 아이콘 + 스플래시
18. flutter analyze + test
19. 빌드 + 배포

---

## 검증

```bash
# 프로젝트 생성 후
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test

# 기능 확인
flutter run -d chrome   # 또는 에뮬레이터
# - 탭2에서 장 체크 → 탭1 블록 반영 확인
# - 건너뛰며 체크 → 구멍 뚫린 패턴 확인
# - 표지/십자가 조건부 물질화 확인
# - 필터 (구약/신약/미완료) 동작 확인
# - 전체 진행률 실시간 업데이트 확인
# - 완독 시 글로우 애니메이션 확인
```
