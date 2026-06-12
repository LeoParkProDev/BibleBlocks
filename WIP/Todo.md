# WIP — 개발자 후원 IAP (확정 설계, 구현 대기)

> 2026-06-13 확정. 후원 계좌 직접 노출은 Google Play 결제 정책 위반 리스크가 있어
> 인앱결제(IAP)로 진행하기로 결정.

## 확정 사항
- 티어 2개: `donation_1000` (₩1,000) / `donation_5000` (₩5,000) — 소모성 상품
- 보상 없음, 결제 성공 시 감사 다이얼로그만 (골드 십자가 톤)

## 앱 구현 — 완료 (2026-06-13, TDD 13개 테스트)
- [x] `in_app_purchase` 플러그인 추가 (pubspec)
- [x] `services/donation_service.dart` — 상품 조회, `buyConsumable`, 구매 스트림 처리·`completePurchase`(소모 처리)
- [x] `providers/donation_provider.dart` — `AsyncNotifierProvider`: 상품 로드 + `donationPhaseProvider`(구매 단계)
- [x] 설정 탭 후원 타일 → `donation_sheet.dart` 바텀시트 (스토어 현지화 가격 표시, 기존 Toss 링크 제거)
- [x] 결제 성공 → 감사 다이얼로그 / 실패 → 스낵바 / 취소 → 무시 (설정 화면 listener)
- [x] 웹은 타일 숨김(`kIsWeb`), 스토어 연결 불가 시 시트에 안내 문구
- [ ] iOS는 추후 App Store Connect에 동일 상품 등록만 하면 동작

## Play Console 수동 단계 (구현 후)
1. [ ] 수익 창출 → 판매자 계정 연결 (정산 계좌 = 에버그린솔루션즈 가능. 단, 법인 수입 회계 처리 필요 — 세무사 확인)
2. [ ] BILLING 권한 포함된 새 AAB 업로드 (플러그인 추가 시 자동 포함) — 업로드돼야 인앱 상품 메뉴 활성화
3. [ ] 인앱 상품 등록·활성화: `donation_1000` ₩1,000 / `donation_5000` ₩5,000
4. [ ] 라이선스 테스터 등록 → 무료 테스트 결제 확인
