# Tier 1 인게이지먼트 기능 구현 기록

> **상태: ✅ 완료 — 188개 테스트 통과, main 머지(`c4d2ff9`), 프로덕션 omega 배포 완료(2026-06-14)**
> 작성일: 2026-06-14 · 브랜치: `feat/tier1-engagement`
> 근거 문서: [WorldClass.md](WorldClass.md) (격차 분석)
> 범위: **스트릭 · 읽기 계획 · 오늘의 말씀 알림** — "매일 돌아올 이유"를 만드는 습관 루프 3종.

세 기능 모두 기존 진도 데이터(`Map<int, Set<int>>`, 책→읽은 장)와 3D 블록 시각화에 연결되어, 어떤 경로로 한 장을 읽든 **블록이 채워지고 → 스트릭이 이어지고 → 계획이 진행되는** 단일 루프로 묶인다.

---

## 1. 스트릭 (연속 읽기)

- **규칙**: 하루 1장 이상 읽으면 그날이 "활동일". **하루 빠짐은 봐주되(은혜), 이틀 연속 빠지면 끊김.** 빠진 날은 숫자에 미포함(읽은 날만 카운트). 끊겨도 UI는 "다시 시작해요" — 수치심 언어 금지.
- **데이터**: 활동일 집합(`YYYY-MM-DD`)이 진실의 원천. 로그인=Firestore `users/{uid}.streak.activeDates`, 게스트=SharedPreferences `bible_streak`. 과거 소급 불가(날짜 기록이 없었음) → 출시일부터 시작.
- **연결**: `ProgressNotifier.toggleChapter`/`toggleAllChapters`가 "읽음 추가" 시에만 `recordToday()` 호출. 체크리스트·리더 모두 자동 커버. 게스트→로그인 시 마이그레이션.
- **UI**: 체크리스트 헤더에 🔥 칩 + 탭 시 상세 시트(현재/최장/규칙 안내).
- **파일**: `models/streak_state.dart`, `services/streak_calculator.dart`(순수·TDD 11케이스), `services/streak_service.dart`, `providers/streak_provider.dart`, `widgets/streak_chip.dart`.
- **안전성**: 스트릭은 보조 기능 — 로드/저장 실패가 핵심 진도 체크를 절대 막지 않음(전 경로 try/catch).

## 2. 읽기 계획

- **카탈로그**(내장 5종, 단기 우선 — 완독률 최대): 불안할 때 시편 7일 / 복음서 21일 / 잠언 31일 / 시편 한 달 / 신약 90일. 순차 분할 + 큐레이션 혼합.
- **완료 판정**: 별도 저장 없이 **진도 데이터에서 파생**(`computePlanStatus`, 순수·테스트). 각 날의 장이 모두 읽혔으면 완료, 현재 날 = 가장 이른 미완료. → 진도/스트릭/블록과 항상 일관.
- **저장**: 활성 계획 1개(`{planId, startedAt}`). 로그인=Firestore `activePlan`, 게스트=SharedPreferences.
- **UI**: **4번째 탭 "계획"**. 활성 계획의 "오늘의 읽기" 카드(장별 → 리더, 완료 체크), "오늘 분량 모두 읽음" 버튼(→ `markChaptersRead` 일괄 읽음 + 스트릭 기록), 진행바, 그만두기. 미시작 시 카탈로그 + 안내.
- **파일**: `data/reading_plans.dart`, `services/plan_status.dart`, `models/plan_progress.dart`, `services/plan_service.dart`, `providers/plan_provider.dart`, `screens/plans/plans_screen.dart`. 라우터에 `/plans` 브랜치 + BottomNav 4탭(fixed).

## 3. 오늘의 말씀 알림

- **방식**: OS는 반복 알림 내용을 못 바꾸므로 향후 14일치를 각각 단발 예약(`zonedSchedule`), 앱 실행 때마다 갱신. 큐레이션 절(29개)을 연중 일수로 순환, 본문은 에셋에서 로드.
- **설정**: 설정 화면 카드 — 켜기 토글(가치 우선 권한 프라이머 → 권한 요청) + 시간 선택. 기기 로컬(SharedPreferences). 1일 1회, 격려 톤.
- **플랫폼**: 웹 미지원 → 전 동작 안전 no-op + 카드 숨김. Android 13+ `POST_NOTIFICATIONS` 권한, `inexactAllowWhileIdle`(정확 알람 권한 불필요), 코어 라이브러리 디슈가링(build.gradle.kts).
- **파일**: `data/daily_verses.dart`, `services/notification_service.dart`, `providers/notification_provider.dart`, `screens/settings/notification_settings_card.dart`. `main.dart`에서 시작 시 예약 갱신.
- **의존성 추가**: `flutter_local_notifications ^22`, `timezone`, `flutter_timezone`.

---

## 검증 (2026-06-14)

- ✅ `flutter analyze` — 신규 코드 0 이슈(잔여 2건은 무관한 기존 pilgrim 페인터 경고).
- ✅ `flutter test` — **188개 전체 통과**(신규: 스트릭 11 + 계획/카탈로그 + 오늘의 말씀 단위 테스트).
- ✅ `flutter build web --release` — 정상 컴파일(네이티브 알림 플러그인 추가에도 웹 빌드 영향 없음).
- ⚠️ **미검증**: 실기기 알림 실제 발송, Android 릴리스 빌드(디슈가링 설정은 추가했으나 `flutter build apk` 미실행 — 기기/SDK 환경 필요).

## 향후(Tier 1 후속)

- 스트릭 상세 시트에 주간 달력 히트맵, 마일스톤 블록 영구 점등.
- 계획: 친구와 함께 읽기(진도 공유), 시즌 챌린지.
- 알림: 스트릭 보호 넛지, 인앱 "오늘의 말씀" 카드(`DailyVerses` 재사용).
