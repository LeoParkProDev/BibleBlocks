# Tier 2 — 본문 활용 + 바이럴 (TODO)

> 상태: ⏭️ 예정 · 근거: [WorldClass.md](WorldClass.md) §6 · 선행: [Tier1.md](Tier1.md) ✅
> 목표: Tier 1이 "매일 돌아올 이유"를 만들었으니, Tier 2는 **앱 안에서 더 깊이 쓰게 하고(검색·하이라이트·노트) + 무료로 새 유저를 데려온다(구절 이미지 공유) + 첫 가치를 빠르게 보여준다(온보딩)**.

추천 순서: **6 구절 이미지 공유 → 5 하이라이트/노트 → 4 본문 검색 → 7 온보딩**
(바이럴 효과 빠른 것 + 기존 코드 재사용도 높은 것 우선)

---

## 4. 본문 검색 🔍
개역한글 전문이 이미 번들(`assets/bible/krv/*.json`, `BibleTextService`)되어 있으므로 클라이언트 검색 가능.

- [ ] 검색 인덱스/스캔: `BibleTextService`에 `search(query)` 추가 — 전 책 lazy 로드는 느리므로, 최초 1회 전체 로드 후 메모리 인덱스 or 점진 스캔(로딩 표시)
- [ ] 결과 모델: `SearchResult(bookIndex, chapter, verse, text, 하이라이트 범위)`
- [ ] 검색 화면 `lib/screens/search/search_screen.dart` — 입력창 + 결과 리스트(구절 스니펫, 매칭어 강조), 탭 시 `/reader/:book/:chapter`로 이동(해당 절 스크롤)
- [ ] 진입점: 리더 헤더 또는 체크리스트 검색 아이콘 확장(현재 "책 이름" 검색만 있음 → 본문 검색 토글 추가)
- [ ] 한글 검색 UX: 공백/조사 무시 옵션, 부분일치
- [ ] 테스트: `search()` 순수 로직 단위 테스트(존재 구절 매칭, 없는 단어 0건, 대소문자/공백)
- [ ] 성능: 1,189장 스캔 시 프레임 드랍 방지(isolate 또는 청크 + `await Future.delayed`)

**완료 기준**: "사랑" 검색 → 결과 N건, 탭하면 해당 장 리더로 이동.

---

## 5. 하이라이트 · 북마크 · 노트 ✍️
**기존 진도 동기화 패턴(`ProgressService`의 Firestore/SharedPreferences 분기)을 그대로 복제**해 구현 — 가장 자연스러운 확장.

- [ ] 모델: `VerseAnnotation(bookIndex, chapter, verse, type: highlight|bookmark|note, color?, noteText?, updatedAt)`
- [ ] 서비스 `lib/services/annotation_service.dart` — `StreakService`/`PlanService`와 동일 구조(로그인=Firestore `users/{uid}.annotations`, 게스트=SharedPreferences `bible_annotations`)
- [ ] 프로바이더 `annotationProvider` (AsyncNotifier) + 게스트→로그인 마이그레이션을 `auth_provider.dart`에 추가(스트릭·계획과 동일 패턴)
- [ ] 리더 통합: `chapter_view.dart`에서 절 길게 누르면 액션 시트(하이라이트 색 / 북마크 / 노트). 하이라이트된 절은 배경색 렌더
- [ ] 북마크/노트 목록 화면 `lib/screens/notes/notes_screen.dart` (또는 '계획' 탭 옆 진입점) — 탭 시 해당 절로 이동
- [ ] 테스트: 서비스 CRUD + 마이그레이션, 리더 하이라이트 렌더 위젯 테스트
- [ ] Firestore 비용: 절 단위 다량 생성 가능 → 문서 1개에 맵으로 저장(진도와 동일 패턴, 쓰기 1회)

**완료 기준**: 절 길게눌러 하이라이트 → 재진입/타기기에서 유지, 노트 목록에서 검색·이동.

---

## 6. 구절 이미지 공유 📤 (바이럴 — 우선 추천)
**이미 있는 진도 카드 PNG 생성 로직(`share_service.dart`, 1080×1080 렌더)을 재사용**.

- [ ] 구절 카드 렌더러: 진도 카드처럼 `CustomPainter`/위젯→이미지. 배경 테마 2~3종(딥와인/크림/세피아) + 구절 본문 + 출처(`개역한글`) + 앱 워터마크/URL
- [ ] 진입점: 리더에서 절 선택 → "이미지로 공유"(현재는 텍스트 클립보드/네이티브 공유만). 오늘의 말씀(`DailyVerses`)에도 "이미지 공유" 버튼
- [ ] 폰트 크기 자동 맞춤(긴 절 줄바꿈), 긴 구절 말줄임 방지
- [ ] 공유: `share_plus`로 이미지 공유(모바일) / 웹은 다운로드(기존 `share_service_web.dart` 패턴)
- [ ] 워터마크에 앱 스토어 링크/URL → 유입 추적(획득 채널)
- [ ] 테스트: 카드 위젯 골든 테스트(가능 시) 또는 렌더 스모크 테스트

**완료 기준**: 좋아하는 절 → 예쁜 카드 이미지로 카톡 공유 → 받은 사람이 앱 URL 확인 가능.

---

## 7. 온보딩 ≤4화면 🚀
첫 실행에 "첫 가치 순간(3D 책이 반응)"을 빠르게 — 현재 온보딩 전무(로그인 후 바로 체크리스트).

- [ ] 최초 실행 플래그(SharedPreferences `onboarding_done`) + 라우터 redirect 또는 첫 진입 시 표시
- [ ] 화면 ≤4: (1) 목표/의도("통독? 매일 한 장? 주제?") (2) 단기 **읽기 계획 선택**(`ReadingPlans` 재사용) (3) **알림 시간 설정**(`notificationPrefs` 재사용, 웹 스킵) (4) **첫 장 즉시 체크** → 3D 블록 애니메이션 보여주기
- [ ] 스킵 가능 + 진행 점(progress dots) + ≤4화면 엄수
- [ ] 게스트도 온보딩 노출(로그인 전), 완료 후 플래그 저장
- [ ] 테스트: 최초 1회만 노출, 스킵 동작, 완료 후 재노출 안 됨

**완료 기준**: 신규 유저가 4화면 안에 계획 시작 + 알림 설정 + 첫 블록 채우는 경험.

---

## 공통 가드레일 (Tier 1과 동일)
- 신앙 맥락: 격려 중심, 수치심/죄책감 금지.
- 게스트/로그인 분기·마이그레이션은 기존 3개 서비스(`progress`/`streak`/`plan`) 패턴을 그대로 따른다.
- 보조 기능 실패가 핵심 읽기/체크를 막지 않도록 try/catch.
- 각 기능: 순수 로직은 단위 테스트 우선(TDD), 완료 후 `flutter analyze` + `flutter test` + `flutter build web` 검증.

## 그 다음: Tier 3 (글로벌 + 깊이)
i18n+영어 출시 · 친구와 함께 읽기 · 다중 번역본(개역개정 등) · 오디오 성경 · 접근성/구글·애플 로그인. (상세 [WorldClass.md](WorldClass.md) §6)
