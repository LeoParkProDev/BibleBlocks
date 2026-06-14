# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BibleBlocks — 성경 읽기 시각화 앱. 성경 66권 1,189장을 체크하면 아이소메트릭 2.5D 성경책이 블록 단위로 채워지는 동기부여 앱.
Flutter 단일 프로젝트 (Android + iOS + Web). 카카오 로그인 + 게스트 모드 지원. 로그인 유저는 Firebase Firestore (클라우드), 게스트는 SharedPreferences (로컬) 저장.

초기 설계 문서: [Docs/Plan0.md](Docs/Plan0.md)
3D 인터랙션 설계: [Docs/Interaction.md](Docs/Interaction.md)
성경 장수 기준표: [Docs/BibleInfo.md](Docs/BibleInfo.md)
테스트 시나리오: [Docs/TestScenarios.md](Docs/TestScenarios.md) (71개)

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
screens/ → providers/ → services/progress_service.dart → Firestore (로그인) / SharedPreferences (게스트)
```

- **상태관리**: Riverpod `AsyncNotifierProvider` 기반
- **인증**: 카카오 로그인 (`kakao_flutter_sdk_user`) + 게스트 모드, `AuthProvider` → `routerProvider` redirect
- **CRUD**: `ProgressService` 직접 호출 (userId 기반 분기 — 로그인 시 Firestore, 게스트 시 로컬)
- **라우팅**: go_router + StatefulShellRoute 3탭 (블록뷰 / 체크리스트 / 설정) + 로그인 redirect

### Data Storage
| 상태 | 저장소 | 동기화 |
|------|--------|--------|
| 로그인 유저 | Firestore `users/{uid}` (progress 필드) | 크로스 디바이스 공유 |
| 게스트 | SharedPreferences (`bible_progress` 키) | 해당 기기만 |

- 게스트 → 로그인 시 `migrateGuestData()`로 로컬 데이터를 Firestore에 복사 (Firestore에 기존 데이터 없을 때만)

### 3D 시각화
- `CustomPainter` 기반 아이소메트릭 렌더링
- 1,189장 → 책 형태 블록에 순서 매핑
- 읽은 장 = 불투명 블록, 안 읽은 장 = 와이어프레임
- 블록 인터랙션: 호버 하이라이트, 툴팁, 스프링 바운스, 커서 근접 부유 ([상세](Docs/Interaction.md))
- 히트테스트: `BlockHitTest` (block_hit_test.dart) — `Path.contains()` 기반, `Listener` + `TransformationController.toScene()`

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

## Deployment

### Vercel (현재 사용 중)
- URL: `https://bible-blocks-omega.vercel.app`
- Vercel 프로젝트명: `bible-blocks`
- **Vercel 스코프: `Leo's projects` (`leos-projects-032d5cbd`)** ← `Evergreen` 팀 아님! 링크 시 반드시 이 스코프 지정
- GitHub: `LeoParkProDev/BibleBlocks`

> ⚠️ 배포 전 `.vercel/project.json`이 없으면 `vercel link --yes`를 그냥 쓰지 말 것 —
> 기본 스코프(Evergreen)에 동명의 새 프로젝트를 잘못 생성한다.
> 반드시 `vercel link --yes --scope leos-projects-032d5cbd --project bible-blocks`로 링크.

### 배포 명령
```bash
flutter build web --release
vercel build --prod --yes
vercel deploy --prebuilt --prod --yes
```

### 주의사항
- `vercel --prod` 단독 사용 금지 — 반드시 `vercel build` → `vercel deploy --prebuilt` 순서
- `vercel.json`: SPA fallback rewrite 설정됨
