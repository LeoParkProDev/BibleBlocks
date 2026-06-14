# Tier 3 — 글로벌 + 깊이 (진행 중)

> 상태: 🚧 진행 중 (2026-06-15 시작) · 근거: [WorldClass.md](WorldClass.md) §6 · 선행: [Tier2.md](Tier2.md) ✅
> 이번 세션: **#8 i18n 기반 + 영어** 완료(핵심 화면). 나머지(#9~12)는 외부 의존(라이선스·크레덴셜·오디오 자산)이 있어 단계적 진행.

추천 순서: **8 i18n(지금) → 12 애플 로그인(iOS 출시 전제) → 10 다중 번역본 → 9 함께 읽기 → 11 오디오**

---

## 8. i18n 기반 + 영어 출시 🌍 ✅ (기반 완료)
문자열 외부화는 기능이 늘기 전 *지금* 시작하는 게 비용이 가장 싸다(WorldClass §6).

- [x] gen-l10n 설정: `l10n.yaml`(non-synthetic, `output-dir: lib/l10n`), `pubspec` `generate: true` + `flutter_localizations`·`intl`
- [x] ARB: `lib/l10n/app_ko.arb`(템플릿) / `app_en.arb` — nav·로그인·설정·온보딩 문자열
- [x] 로케일 상태: `localeProvider`(SharedPreferences `app_locale`) — **기본 한국어**, `'system'`=시스템 기본
- [x] `MaterialApp.router`에 `localizationsDelegates`·`supportedLocales`·`locale` 연결
- [x] 폴백 헬퍼 `context.l10n` — 델리게이트 없으면 한국어(기존 위젯 테스트 226개 무수정 호환)
- [x] 설정 화면에 **언어 선택**(한국어 / English / 시스템 기본)
- [x] 핵심 화면 영어화: 하단 탭, 로그인, 설정, 온보딩 4화면
- [x] 테스트: `localeProvider`(기본 ko·en 유지·system) + 로케일 렌더/폴백 위젯 테스트
- [ ] 나머지 화면 문자열 외부화: 체크리스트·리더·검색·노트·계획·후원 시트 (점진)
- [ ] 영어 스토어 메타데이터 / 영어권 출시

**완료 기준(기반)**: 설정 → English 선택 시 탭·로그인·설정·온보딩이 영어로 전환, 한국어가 기본.
**검증**: `flutter analyze` 클린(기존 2건 제외) · `flutter test` 232개 통과 · `flutter build web` 성공.

---

## 9. 친구/그룹 함께 읽기 + 시즌 챌린지 👥 ⏭️
- [ ] Firestore 그룹/멤버십/초대 모델 + 보안 규칙
- [ ] 그룹 읽기 계획 공유, 진행 현황(격려형 — 경쟁·창피 금지)
- [ ] 시즌 챌린지(예: 사순절/대림절)
> 규모 큼 + 백엔드 설계 필요. Tier 2 패턴(서비스/프로바이더) 확장.

## 10. 다중 번역본 📖 ⏭️
- [ ] `BibleTextService` 버전 파라미터화(`assets/bible/{version}/`) + 번역본 선택 상태/리더 설정 UI
- [ ] 무료: WEB·BSB(CC0)·KJV 번들 → 유료: 개역개정(대한성서공회 계약), NIV·ESV(API.Bible/ESV API)
> **외부 의존**: 개역개정/NIV/ESV는 라이선스 계약·API 키 필요. 무료본은 텍스트 데이터(JSON) 확보 필요.

## 11. 오디오 성경 + 수면 모드 🎧 ⏭️
- [ ] 오디오 플레이어, 장 자동 체크(완료 시), 수면 타이머
> **외부 의존**: 라이선스된 오디오 자산/스트리밍 소스 필요.

## 12. 접근성 + 구글/애플 로그인 ♿ ⏭️
- [ ] 전역 다크 모드(테마 토큰화 — `AppColors` 정적 상수 → Theme 확장 리팩터), 글자 크기, 시맨틱 라벨
- [ ] 구글/애플 로그인(특히 iOS 심사 시 애플 로그인 사실상 필수)
> **외부 의존**: OAuth 크레덴셜/플랫폼 설정(google-services, Apple Sign-In capability). 다크모드는 자체 가능하나 광범위 리팩터.

---

## 공통 가드레일 (Tier 1·2와 동일)
- 신앙 맥락: 격려 중심, 수치심/죄책감 금지.
- 게스트/로그인 분기·마이그레이션은 기존 서비스 패턴을 따른다.
- 보조 기능 실패가 핵심 읽기/체크를 막지 않도록 try/catch.
- 순수 로직 TDD 우선, 완료 후 `flutter analyze` + `flutter test` + `flutter build web` 검증.
