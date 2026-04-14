# BibleBlocks 3D 모델 카탈로그

> 앱 내 설정에서 3D 시각화 모델을 전환할 수 있습니다.
> 모든 모델은 1,189장(66권)을 복셀 블록에 매핑합니다.

## 1. 성경책 (Book) — 기본값

| 항목 | 값 |
|------|-----|
| ID | `book` |
| 복셀 구조 | 8×12×2 = 192 블록 |
| 매핑 | 1,189장을 192블록에 균등 분배 |
| 특수 요소 | 앞표지 십자가 패턴, 책등 |
| 완독 연출 | 금빛 글로우 반복 |

## 2. 노아의 방주 (Noah's Ark)

| 항목 | 값 |
|------|-----|
| ID | `noahsArk` |
| 복셀 구조 | hull(15길이, tapered) + 3 decks + cabin + roof ≈ 300 블록 |
| 매핑 | 1,189장을 구조 블록에 균등 분배 (물/비둘기/무지개 제외) |
| 특수 요소 | 물결 애니메이션, 비둘기+감람가지, 무지개, 출렁임 |
| 완독 연출 | 무지개 표시 + 금빛 글로우 |
| 참고 | 창세기 6-9장 |

## 3. 솔로몬 성전 (Solomon's Temple)

| 항목 | 값 |
|------|-----|
| ID | `solomonsTemple` |
| 복셀 구조 | courtyard + ulam + hekal + dvir + pillars ≈ 350 블록 |
| 매핑 | 1,189장을 구조 블록에 균등 분배 (바닥/장식 제외) |
| 특수 요소 | 야긴/보아스 기둥, 지성소 금빛 글로우, 빛줄기, 그룹 |
| 완독 연출 | 지성소 방사 글로우 + 파티클 |
| 참고 | 왕상 6-7장 |

## 모델 추가 가이드

1. `lib/painters/{model}_painter.dart` — CustomPainter (기존 인터페이스 준수)
2. `lib/painters/{model}_hit_test.dart` — 히트테스트 (BlockHitTest 패턴)
3. `lib/models/bible_model.dart`의 `BibleModelType` enum에 추가
4. `lib/screens/bible_view/bible_view_screen.dart`의 switch문에 분기 추가
