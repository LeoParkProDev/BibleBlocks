# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BibleBlocks — 성경 읽기 시각화 앱. 성경 66권 1,189장을 체크하면 아이소메트릭 2.5D 성경책이 블록 단위로 채워지는 동기부여 앱.
Flutter 단일 프로젝트 (Android + iOS + Web). 카카오 로그인 + 게스트 모드 지원. 로그인 유저는 Firebase Firestore (클라우드), 게스트는 SharedPreferences (로컬) 저장.

초기 설계 문서: [Docs/Plan0.md](Docs/Plan0.md)
3D 인터랙션 설계: [Docs/Interaction.md](Docs/Interaction.md)
성경 장수 기준표: [Docs/BibleInfo.md](Docs/BibleInfo.md)
테스트 시나리오: [Docs/TestScenarios.md](Docs/TestScenarios.md) (71개)
기능 로드맵: [Docs/WorldClass.md](Docs/WorldClass.md) §6 — Tier1 ✅(스트릭·읽기계획·알림) · Tier2 ✅(본문검색·하이라이트/노트·구절이미지공유·온보딩) · Tier3 🚧(i18n 등). 상세: [Tier1](Docs/Tier1.md) · [Tier2](Docs/Tier2.md) · [Tier3](Docs/Tier3.md)

## Commands

```bash
flutter pub get                                          # 의존성 설치
dart run build_runner build --delete-conflicting-outputs  # Freezed 코드 생성 (모델 변경 시 필수)
flutter gen-l10n                                         # 번역 코드 생성 (lib/l10n/*.arb 변경 시 필수)
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
- **CRUD**: 서비스 직접 호출, userId 기반 분기(로그인=Firestore, 게스트=SharedPreferences). 동일 패턴 서비스 4종 — `progress`/`streak`/`plan`/`annotation`, 각자 `migrateGuestData()`로 게스트→로그인 이전(Firestore에 기존 데이터 없을 때만)
- **라우팅**: go_router + StatefulShellRoute **4탭** (블록뷰 / 체크리스트 / 계획 / 설정) + 온보딩·로그인 redirect. 풀스크린 라우트: `/reader/:book/:chapter?verse=N`(검색·노트 진입 시 해당 절 강조), `/search`, `/notes`, `/onboarding`

### Data Storage
| 상태 | 저장소 | 동기화 |
|------|--------|--------|
| 로그인 유저 | Firestore `users/{uid}` (progress 필드) | 크로스 디바이스 공유 |
| 게스트 | SharedPreferences (`bible_progress` 키) | 해당 기기만 |

- 게스트 → 로그인 시 `migrateGuestData()`로 로컬 데이터를 Firestore에 복사 (Firestore에 기존 데이터 없을 때만)
- 진도 외 같은 패턴: Firestore `users/{uid}`의 `streak`·`activePlan`·`annotations` 필드 / 게스트 키 `bible_streak`·`bible_active_plan`·`bible_annotations`. (알림·언어 설정은 기기 로컬 전용)

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

## i18n (국제화)

- gen-l10n (non-synthetic): `l10n.yaml`(`output-dir: lib/l10n`), `pubspec`에 `generate: true` + `flutter_localizations`/`intl`. ARB는 `lib/l10n/app_ko.arb`(템플릿)·`app_en.arb`, **생성물(`app_localizations*.dart`)도 커밋**.
- **기본 언어 = 한국어.** `localeProvider`(SharedPreferences `app_locale`): 저장값 없으면 `Locale('ko')`, `'system'`이면 시스템 기본(null). 설정 화면 **최하단**에 언어 선택(한국어/English/시스템 기본).
- ⚠️ **테스트 호환 핵심**: 화면은 문자열을 `context.l10n`(확장, `lib/l10n/l10n.dart`)으로 접근하고, 델리게이트가 없으면 `AppLocalizationsKo()`로 폴백한다. 그래서 자체 `MaterialApp`을 만드는 위젯 테스트가 **무수정으로 한국어 렌더 → 통과**.
- 문자열 추가/외부화 시: **ko ARB 값은 기존 한글 리터럴과 정확히 동일**하게 둘 것(테스트가 `find.text('체크리스트')`처럼 정확 매칭) → `flutter gen-l10n` 재생성.
- 외부화 완료: 하단 탭·로그인·설정·온보딩·노트. 미완(점진): 체크리스트·리더·검색·계획·후원 시트. 상세 로드맵 [Docs/Tier3.md](Docs/Tier3.md) §8.

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

### 실기기(Android) 설치
변경 후 유저 폰(갤럭시 S24 · `SM S921N` · adb id `R3CX30F3DNW` · 패키지 `com.bibleblock.app`)에 설치해 확인.

> ⚠️ `flutter install` 사용 금지 — 재컴파일 없이 **이전에 빌드된 APK를 그대로 설치**해
> 변경이 반영 안 될 수 있다(실제로 "기능이 안 보인다" 혼란을 일으킨 적 있음).
> 반드시 명시적 재빌드 후 `adb install -r`로 설치한다.

```bash
flutter build apk --release   # "✓ Built ...app-release.apk" (Gradle 실제 빌드 ~90s) 확인
# adb는 PATH에 없음 → 절대경로 사용. -r = 데이터(진행도) 유지
~/Library/Android/sdk/platform-tools/adb -s R3CX30F3DNW install -r \
  build/app/outputs/flutter-apk/app-release.apk
```

- 화면 검증(스크린샷/탭): 좌표는 **device px(1080×2340)** 기준 — `screencap` 이미지는 축소 표시되니 화면에서 읽은 좌표를 그대로 쓰지 말 것. 하단 내비 y≈2120 (체크리스트 x≈405, 설정 x≈945).
