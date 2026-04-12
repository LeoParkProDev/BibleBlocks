# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BibleBlocks — 성경 읽기 시각화 앱. 성경 66권 1,189장을 체크하면 아이소메트릭 2.5D 성경책이 블록 단위로 채워지는 동기부여 앱.
Flutter 단일 프로젝트 (Android + iOS + Web), Firebase 실시간 동기화.

초기 설계 문서: [Docs/Plan0.md](Docs/Plan0.md)

## Commands

```bash
flutter pub get                                          # 의존성 설치
dart run build_runner build --delete-conflicting-outputs  # Freezed 코드 생성 (모델 변경 시 필수)
flutter analyze                                          # 정적 분석
flutter test                                             # 전체 테스트
flutter run -d chrome                                    # 웹 실행
flutter run -d emulator                                  # 안드로이드 실행
```

## Architecture

### Layer Structure
```
screens/ → providers/ → services/progress_service.dart → SharedPreferences (로컬) / Firestore (클라우드)
                       → services/auth_service.dart
```

- **상태관리**: Riverpod StateNotifierProvider 기반, 로컬 저장 우선
- **CRUD**: `ProgressService` 직접 호출
- **라우팅**: go_router + StatefulShellRoute 2탭 (내 성경 / 체크리스트)

### Data Structure
```
users/{uid}/progress/{bookIndex}  # BookProgress (읽은 장 번호 Set)
```

### 3D 시각화
- `CustomPainter` 기반 아이소메트릭 렌더링
- 1,189장 → 책 형태 블록에 순서 매핑
- 읽은 장 = 불투명 블록, 안 읽은 장 = 와이어프레임

## Coding Conventions

- **Freezed 모델**: `abstract class`로 선언 (Dart 3.11+ 필수)
- **AsyncValue**: `.value`로 접근 (Riverpod 3.x — `.valueOrNull` 제거됨)
- **반응형 레이아웃**: 모든 화면 `Center > ConstrainedBox(maxWidth: 600)`

## Design Theme: "테라코타 일몰" 변형

| 역할 | HEX | 용도 |
|------|-----|------|
| 배경 | `#FAF8F5` | Scaffold |
| Primary (테라코타) | `#C47B5A` | 체크 완료, 프로그레스바 |
| Secondary (블루그레이) | `#7A8E99` | 신약 |
| Gold | `#D4A843` | 십자가, 완독 연출 |
| 3D 배경 | `#0a0a1a` | 다크 — 블록이 돋보이도록 |

색상: `lib/theme/app_colors.dart`, 테마: `lib/theme/app_theme.dart`
