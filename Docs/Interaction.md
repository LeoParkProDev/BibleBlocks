# Tab1 아이소메트릭 3D 뷰 인터랙션 설계

## 개요

Tab1의 아이소메트릭 3D 성경 뷰에 개별 블록 인터랙션을 추가하여 "살아있는" UX를 제공한다.

## 구현된 기능

### 1. 호버/탭 하이라이트
- 블록에 커서를 올리면 3면에 white 0.15 오버레이 + gold 윤곽선 1.5px
- 데스크톱: 마우스 호버 시 실시간 반응
- 모바일: 탭 시 하이라이트 표시

### 2. 툴팁
- 호버/탭된 블록 위에 해당 블록의 성경 정보 표시
- 형식: "창세기 1-6장 (4/6 읽음)"
- 단일 책 / 복수 책 경계 자동 처리
- 검정 반투명 배경, gold 테두리, 흰 텍스트 11px
- 모바일: 탭 시 표시 → 2초 후 자동 해제

### 3. 블록 눌림 + 스프링 바운스
- 탭 시 블록이 z축으로 눌렸다가 탄성 복귀
- 600ms 감쇠 스프링 애니메이션
- 수식: `-0.3 * sin(t * π * 2.5) * (1-t)²`

### 4. 커서 근접 부유
- 커서 반경 60px 내 블록들이 미세하게 떠오름
- Quadratic falloff, 최대 0.15 블록 단위
- 데스크톱 전용 (마우스 추적)

## 아키텍처

### 신규 파일
- **`lib/painters/block_hit_test.dart`** — 히트테스트, 좌표변환, 툴팁 텍스트 생성

### 수정 파일
- **`lib/painters/isometric_bible_painter.dart`** — 하이라이트/부유/바운스 렌더링
- **`lib/screens/bible_view/bible_view_screen.dart`** — 제스처 처리, 상태관리, 툴팁 UI

### 핵심 설계 결정

| 결정 | 이유 |
|------|------|
| `Path.contains()` 히트테스트 | 각 블록의 3면(top/left/right)을 정확히 검사 |
| `TransformationController.toScene()` | 줌/팬 상태의 좌표 변환 자동 처리 |
| `Listener` 사용 (GestureDetector 아님) | InteractiveViewer와 제스처 충돌 방지 |
| pointerDown/Up 거리 < 10px = 탭 | 팬과 탭을 확실히 구분 |
| Stack 내 Positioned 툴팁 | Overlay 대비 단순, IgnorePointer로 이벤트 투과 |
| 최대 z-offset 0.15 블록 | painter's algorithm 재정렬 불필요 |

### 데이터 흐름

```
PointerEvent → Listener
  → toScene() 좌표변환
  → BlockHitTest.hitTest() 블록 판정
  → setState() → CustomPainter 재그리기
                → 툴팁 위젯 갱신
```

### BlockCoord 타입

```dart
typedef BlockCoord = ({int x, int y, int z});
```

페이지 블록의 3D 좌표. x: 0~7 (가로), y: 0~1 (깊이), z: 0~11 (세로).

### 히트테스트 순회 순서

Front-to-back: `y 0→1, z 0→11, x 7→0` — 시각적으로 앞에 있는 블록이 우선.

## 예정 기능

### 5. 좌우 회전 (버튼 기반)
- 하단 좌/우 버튼 (◀ ▶)으로 책을 Y축 회전
- 누르고 있으면 연속 회전 (초당 ~45°), 놓으면 즉시 멈춤 (관성 없음)
- **투영 수학 교체 (접근법 3)**:
  - `project()` 함수가 `rotationAngle` 파라미터를 받아 진짜 3D 투영 계산
  - 수식: Y축 회전 행렬 적용 후 아이소메트릭 투영
    ```
    rotatedX = x * cos(angle) - y * sin(angle)
    rotatedY = x * sin(angle) + y * cos(angle)
    screenX = origin.dx + (rotatedX - rotatedY) * cos30 * blockSize
    screenY = origin.dy + (rotatedX + rotatedY) * sin30 * blockSize - z * blockSize
    ```
  - Painter's algorithm: 회전각에 따라 그리기 순서 동적 정렬 (4분면별 축 방향 전환)
  - 히트테스트: `BlockHitTest.project()`도 동일한 angle 적용, `Path.contains()` 로직 유지
- UI: `GestureDetector.onLongPressStart` → `AnimationController`로 부드러운 회전

### 6. 블록 채워지는 애니메이션
- 체크리스트에서 읽음 처리 후 3D 뷰 탭으로 돌아왔을 때 연출
- `_previousProgressData`를 저장, diff로 새로 채워진 블록 감지
- 변경된 블록: 와이어프레임 → 불투명 블록, 페이드인 + 위에서 떨어지는 연출
- 블록당 약 400ms, 순차적으로 50ms 딜레이 (쌓이는 느낌)

### 7. 인트로 애니메이션
- 앱 최초 진입 시 (3D 뷰 빌드 시점)
- 읽은 블록들이 아래→위, 뒤→앞 순서로 하나씩 나타남
- 블록당 z-offset 위에서 → 제자리로 + opacity 0→1
- 전체 약 1.5초, 최초 1회만 (플래그로 제어)

## 엣지 케이스

- **탭 vs 팬 구분**: pointerDown/Up 거리 10px 임계값
- **줌 상태 히트테스트**: `toScene()`이 줌/팬 변환 자동 처리
- **z-offset 겹침**: 최대 0.15 블록으로 미미하므로 정렬 불필요
- **모바일 hover 없음**: 탭 시 툴팁 + 2초 타이머로 해결
- **툴팁 화면 넘침**: FractionalTranslation으로 중앙 정렬, Stack clipBehavior: none
- **회전 중 히트테스트**: 동일한 angle로 투영하므로 정확도 유지
- **회전 중 팬/줌**: 회전 버튼과 InteractiveViewer 제스처는 독립적이므로 충돌 없음
- **인트로 중 인터랙션**: 인트로 애니메이션 완료 전에는 호버/탭 무시

## 검증

```bash
flutter analyze   # 정적 분석 통과
flutter test      # 기존 61개 테스트 통과
```

수동 테스트:
1. 데스크톱: 블록 위 마우스 이동 → 하이라이트 + 툴팁 표시
2. 블록 클릭 → 바운스 애니메이션 + 툴팁
3. 마우스 이동 시 주변 블록 부유 효과
4. 핀치줌/드래그 중 인터랙션 정상 동작
5. 모바일: 탭 시 하이라이트 + 툴팁 2초 후 소멸
6. 회전 버튼 누르고 있기 → 부드러운 좌/우 회전, 놓으면 멈춤
7. 회전된 상태에서 블록 탭 → 정확한 히트테스트 + 툴팁
8. 체크리스트에서 읽음 처리 후 3D 뷰 복귀 → 블록 채워지는 애니메이션
9. 앱 최초 진입 → 인트로 애니메이션 후 인터랙션 활성화
