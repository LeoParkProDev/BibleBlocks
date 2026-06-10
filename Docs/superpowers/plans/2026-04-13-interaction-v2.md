# Interaction V2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 아이소메트릭 3D 뷰에 Y축 회전(버튼), 블록 채워지는 애니메이션, 인트로 애니메이션을 추가한다.

**Architecture:** `project()` 함수에 rotationAngle 파라미터를 추가하여 투영 수학을 교체하고, painter's algorithm 정렬을 동적으로 변경한다. 애니메이션은 기존 AnimationController 패턴을 따른다.

**Tech Stack:** Flutter CustomPainter, dart:math, AnimationController, Riverpod

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/painters/isometric_bible_painter.dart` | Modify | rotationAngle 파라미터, 동적 정렬, 인트로/채움 애니메이션 렌더링 |
| `lib/painters/block_hit_test.dart` | Modify | project()에 angle 추가, hitTest에 angle 전달 |
| `lib/screens/bible_view/bible_view_screen.dart` | Modify | 회전 버튼 UI, 회전/인트로/채움 AnimationController, 진행 diff 감지 |
| `test/painters/rotation_test.dart` | Create | 투영 수학 + 정렬 순서 테스트 |
| `test/painters/block_hit_test_test.dart` | Create | 회전 상태 히트테스트 검증 |

---

### Task 1: 투영 함수에 rotationAngle 추가

**Files:**
- Modify: `lib/painters/block_hit_test.dart`
- Create: `test/painters/rotation_test.dart`

- [ ] **Step 1: 회전 투영 테스트 작성**

```dart
// test/painters/rotation_test.dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:bible_blocks/painters/block_hit_test.dart';

void main() {
  group('Rotated projection', () {
    final origin = const Offset(200, 200);

    test('angle=0 matches original isometric projection', () {
      final p = BlockHitTest.project(1, 0, 0, origin, 0);
      // Original: origin.dx + (1-0)*0.866*14 = 200+12.124
      expect(p.dx, closeTo(212.12, 0.1));
      // origin.dy + (1+0)*0.5*14 - 0*14 = 207
      expect(p.dy, closeTo(207.0, 0.1));
    });

    test('angle=pi/2 swaps x and y axes', () {
      // At 90 degrees, x=1,y=0 rotates to x=0,y=1
      final p0 = BlockHitTest.project(1, 0, 0, origin, 0);
      final p90 = BlockHitTest.project(1, 0, 0, origin, pi / 2);
      // Rotated: rotatedX=cos(90)*1 - sin(90)*0 = 0
      //          rotatedY=sin(90)*1 + cos(90)*0 = 1
      // screenX = origin.dx + (0 - 1)*cos30*14 = 200 - 12.12
      expect(p90.dx, closeTo(200 - 12.12, 0.1));
    });

    test('angle=pi produces mirrored view', () {
      final p0 = BlockHitTest.project(1, 0, 0, origin, 0);
      final pPi = BlockHitTest.project(1, 0, 0, origin, pi);
      // At 180deg: rotatedX = -1, rotatedY = 0
      // screenX = origin.dx + (-1 - 0)*cos30*14 = 200 - 12.12
      expect(pPi.dx, closeTo(200 - 12.12, 0.1));
    });

    test('z component is unaffected by Y-axis rotation', () {
      final p0 = BlockHitTest.project(0, 0, 5, origin, 0);
      final p45 = BlockHitTest.project(0, 0, 5, origin, pi / 4);
      // z only affects screenY: -z*blockSize, same regardless of angle
      expect(p0.dy - 200, closeTo(p45.dy - 200, 0.01));
    });
  });
}
```

- [ ] **Step 2: 테스트 실행, 실패 확인**

Run: `flutter test test/painters/rotation_test.dart`
Expected: FAIL — `project()` 시그니처에 angle 파라미터 없음

- [ ] **Step 3: BlockHitTest.project()에 angle 파라미터 추가**

`lib/painters/block_hit_test.dart`에서 `project` 수정:

```dart
static Offset project(double x, double y, double z, Offset origin, [double angle = 0]) {
  final cosA = cos(angle);
  final sinA = sin(angle);
  final rotatedX = x * cosA - y * sinA;
  final rotatedY = x * sinA + y * cosA;
  return Offset(
    origin.dx + (rotatedX - rotatedY) * _cos30 * blockSize,
    origin.dy + (rotatedX + rotatedY) * _sin30 * blockSize - z * blockSize,
  );
}
```

`dart:math` import 추가 (cos, sin, pi).

Face path 메서드들(`topFacePath`, `leftFacePath`, `rightFacePath`)에도 `[double angle = 0]` 추가하고 내부 `project` 호출에 angle 전달.

`hitTest`에도 `[double angle = 0]` 추가, face path 호출에 angle 전달.

`blockTopCenter`에도 `[double angle = 0]` 추가.

- [ ] **Step 4: 테스트 실행, 통과 확인**

Run: `flutter test test/painters/rotation_test.dart`
Expected: PASS

- [ ] **Step 5: 커밋**

```bash
git add lib/painters/block_hit_test.dart test/painters/rotation_test.dart
git commit -m "feat: add rotationAngle to isometric projection"
```

---

### Task 2: Painter에 회전 적용 + 동적 정렬

**Files:**
- Modify: `lib/painters/isometric_bible_painter.dart`

- [ ] **Step 1: IsometricBiblePainter에 rotationAngle 추가**

`IsometricBiblePainter` 클래스에 필드 추가:

```dart
final double rotationAngle;
```

생성자에 추가:

```dart
this.rotationAngle = 0.0,
```

`project()` 메서드를 angle 기반으로 교체:

```dart
Offset project(double x, double y, double z, Offset origin) {
  final cosA = cos(rotationAngle);
  final sinA = sin(rotationAngle);
  final rotatedX = x * cosA - y * sinA;
  final rotatedY = x * sinA + y * cosA;
  return Offset(
    origin.dx + (rotatedX - rotatedY) * _cos30 * blockSize,
    origin.dy + (rotatedX + rotatedY) * _sin30 * blockSize - z * blockSize,
  );
}
```

`shouldRepaint`에 조건 추가:

```dart
oldDelegate.rotationAngle != rotationAngle
```

- [ ] **Step 2: Painter's algorithm 동적 정렬**

`_drawPageBlocks` 메서드에서 루프 순서를 회전각에 따라 변경:

```dart
void _drawPageBlocks(Canvas canvas, Offset origin) {
  // 회전각에 따른 정렬 방향 결정
  final normAngle = rotationAngle % (2 * pi);
  final yStart = (normAngle > pi / 2 && normAngle < 3 * pi / 2)
      ? 0 : bookDepth - 1;
  final yEnd = yStart == 0 ? bookDepth : -1;
  final yStep = yStart == 0 ? 1 : -1;

  final xStart = (normAngle > pi && normAngle < 2 * pi) ? 0 : bookWidth - 1;
  final xEnd = xStart == 0 ? bookWidth : -1;
  final xStep = xStart == 0 ? 1 : -1;

  for (int y = yStart; y != yEnd; y += yStep) {
    for (int z = bookHeight - 1; z >= 0; z--) {
      for (int x = xStart; x != xEnd; x += xStep) {
        // ... 기존 블록 렌더링 로직 그대로
      }
    }
  }
}
```

커버와 스파인도 동일하게 정렬 방향 적용. `_drawBackCover`, `_drawFrontCover`, `_drawSpine` 각각에서 회전각에 따라 그리기 순서 결정. 앞/뒤 커버는 normAngle에 따라 그리기 순서를 바꿔야 함:

```dart
@override
void paint(Canvas canvas, Size size) {
  final origin = Offset(size.width / 2, size.height * 0.65);
  if (isComplete && glowAnimation > 0) _drawCompletionGlow(canvas, size, origin);

  final normAngle = rotationAngle % (2 * pi);
  final frontFirst = normAngle > pi / 2 && normAngle < 3 * pi / 2;

  if (frontFirst) {
    _drawFrontCover(canvas, origin);
    _drawPageBlocks(canvas, origin);
    _drawBackCover(canvas, origin);
  } else {
    _drawBackCover(canvas, origin);
    _drawPageBlocks(canvas, origin);
    _drawFrontCover(canvas, origin);
  }
  _drawSpine(canvas, origin);

  if (isComplete && glowAnimation > 0) _drawParticles(canvas, size, origin);
}
```

- [ ] **Step 3: flutter analyze 통과 확인**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 4: 기존 테스트 통과 확인**

Run: `flutter test`
Expected: All tests pass (angle=0 기본값이므로 기존 동작 유지)

- [ ] **Step 5: 커밋**

```bash
git add lib/painters/isometric_bible_painter.dart
git commit -m "feat: add rotation support to isometric painter"
```

---

### Task 3: 회전 버튼 UI + AnimationController

**Files:**
- Modify: `lib/screens/bible_view/bible_view_screen.dart`

- [ ] **Step 1: 회전 상태 및 컨트롤러 추가**

`_BibleViewScreenState`에 추가:

```dart
late AnimationController _rotationController;
double _rotationAngle = 0.0;
int _rotationDirection = 0; // -1: left, 0: stop, 1: right
```

`initState`에 추가:

```dart
_rotationController = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 1), // 틱 용도, duration 무관
)..addListener(() {
  setState(() {
    _rotationAngle += _rotationDirection * 0.02; // ~45°/sec at 60fps
  });
});
```

`dispose`에 추가:

```dart
_rotationController.dispose();
```

회전 시작/멈춤 메서드:

```dart
void _startRotation(int direction) {
  _rotationDirection = direction;
  _rotationController.repeat();
}

void _stopRotation() {
  _rotationDirection = 0;
  _rotationController.stop();
}
```

- [ ] **Step 2: 회전 버튼 위젯 추가**

`build()` 메서드의 Stack children에 하단 회전 버튼 추가 (기존 힌트 텍스트 위치 교체):

```dart
// 하단 회전 버튼
Positioned(
  bottom: 16,
  left: 0,
  right: 0,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      GestureDetector(
        onLongPressStart: (_) => _startRotation(-1),
        onLongPressEnd: (_) => _stopRotation(),
        onTapDown: (_) => _startRotation(-1),
        onTapUp: (_) => _stopRotation(),
        onTapCancel: _stopRotation,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.rotate_left, color: Colors.white54, size: 24),
        ),
      ),
      const SizedBox(width: 24),
      Text(
        '핀치로 확대 · 드래그로 이동',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 12,
        ),
      ),
      const SizedBox(width: 24),
      GestureDetector(
        onLongPressStart: (_) => _startRotation(1),
        onLongPressEnd: (_) => _stopRotation(),
        onTapDown: (_) => _startRotation(1),
        onTapUp: (_) => _stopRotation(),
        onTapCancel: _stopRotation,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.rotate_right, color: Colors.white54, size: 24),
        ),
      ),
    ],
  ),
),
```

- [ ] **Step 3: Painter와 HitTest에 angle 전달**

CustomPaint 생성에서:

```dart
painter: IsometricBiblePainter(
  progressData: data,
  glowAnimation: _glowController.value,
  hoveredBlock: _hoveredBlock,
  pressedBlock: _pressedBlock,
  bounceAnimation: _bounceController.value,
  cursorScenePos: _cursorScenePos,
  rotationAngle: _rotationAngle,
),
```

`AnimatedBuilder`의 animation에 `_rotationController` 추가:

```dart
animation: Listenable.merge([_glowController, _bounceController, _rotationController]),
```

히트테스트 호출에 angle 전달 (`_onPointerHover`, `_onPointerUp`):

```dart
final hit = BlockHitTest.hitTest(scenePos, _canvasSize, _rotationAngle);
```

툴팁 위치에 angle 전달 (`_buildTooltip`):

```dart
final canvasPos = BlockHitTest.blockTopCenter(_hoveredBlock!, _canvasSize, _rotationAngle);
```

- [ ] **Step 4: flutter run -d chrome으로 수동 테스트**

Run: `flutter run -d chrome`
확인: 회전 버튼 누르고 있으면 책이 좌/우로 부드럽게 회전, 놓으면 멈춤

- [ ] **Step 5: flutter analyze + test**

Run: `flutter analyze && flutter test`
Expected: No issues, all tests pass

- [ ] **Step 6: 커밋**

```bash
git add lib/screens/bible_view/bible_view_screen.dart
git commit -m "feat: add rotation buttons to 3D bible view"
```

---

### Task 4: 블록 채워지는 애니메이션

**Files:**
- Modify: `lib/painters/isometric_bible_painter.dart`
- Modify: `lib/screens/bible_view/bible_view_screen.dart`

- [ ] **Step 1: Painter에 fillAnimation 파라미터 추가**

`IsometricBiblePainter`에 필드 추가:

```dart
final Set<int> newlyFilledBlocks; // 새로 채워진 블록 인덱스
final double fillAnimation;       // 0.0 ~ 1.0
```

생성자에 추가:

```dart
this.newlyFilledBlocks = const {},
this.fillAnimation = 1.0,
```

`shouldRepaint`에 추가:

```dart
oldDelegate.fillAnimation != fillAnimation ||
oldDelegate.newlyFilledBlocks != newlyFilledBlocks
```

- [ ] **Step 2: _drawPageBlocks에서 새로 채워진 블록에 애니메이션 적용**

`_drawPageBlocks` 내부, 블록 렌더링 직전에:

```dart
final blockIndex = y * (bookWidth * bookHeight) + z * bookWidth + x;
final isNewlyFilled = newlyFilledBlocks.contains(blockIndex);

// 새로 채워진 블록: 위에서 떨어지는 + 페이드인
double extraZOffset = 0;
double opacity = 1.0;
if (isNewlyFilled && fillAnimation < 1.0) {
  final blockDelay = (blockIndex % 20) * 0.05; // 순차 딜레이
  final localT = ((fillAnimation - blockDelay) / (1.0 - blockDelay)).clamp(0.0, 1.0);
  extraZOffset = (1.0 - localT) * 2.0; // 위에서 2블록 높이로 시작
  opacity = localT;
}
final effectiveZ = z.toDouble() + zOffset + extraZOffset;
```

블록 색상에 opacity 적용:

```dart
if (fillRatio >= 1.0) {
  _drawCube(canvas, origin, x.toDouble(), y.toDouble(), effectiveZ,
      AppColors.pageIvory.withValues(alpha: opacity),
      AppColors.pageIvoryDark.withValues(alpha: opacity));
}
```

- [ ] **Step 3: BibleViewScreen에서 진행 diff 감지 + 애니메이션 트리거**

`_BibleViewScreenState`에 추가:

```dart
late AnimationController _fillController;
Map<int, Set<int>> _previousProgressData = {};
Set<int> _newlyFilledBlocks = {};
```

`initState`에 추가:

```dart
_fillController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 800),
)..value = 1.0; // 초기에는 완료 상태
```

`dispose`에 추가:

```dart
_fillController.dispose();
```

기존 `data:` 핸들러에서 diff 감지 로직 추가 (build 내 `progressAsync.when(data:)` 부분):

```dart
data: (data) {
  // 진행 diff 감지
  if (_previousProgressData.isNotEmpty && data != _previousProgressData) {
    final newBlocks = <int>{};
    for (int i = 0; i < IsometricBiblePainter.totalPageBlocks; i++) {
      final range = BlockHitTest.blockChapterRange(i);
      bool wasFullBefore = true;
      bool isFullNow = true;
      for (int g = range.globalStart; g < range.globalEnd; g++) {
        if (!ProgressService.isGlobalIndexRead(_previousProgressData, g)) wasFullBefore = false;
        if (!ProgressService.isGlobalIndexRead(data, g)) isFullNow = false;
      }
      if (!wasFullBefore && isFullNow) newBlocks.add(i);
    }
    if (newBlocks.isNotEmpty) {
      _newlyFilledBlocks = newBlocks;
      _fillController.forward(from: 0.0);
    }
  }
  _previousProgressData = Map.of(data);
  _latestProgressData = data;
  _checkCompletion(data);
  // ... return 위젯
```

`AnimatedBuilder` animation에 `_fillController` 추가.

Painter 생성에 전달:

```dart
newlyFilledBlocks: _newlyFilledBlocks,
fillAnimation: _fillController.value,
```

- [ ] **Step 4: flutter analyze + test**

Run: `flutter analyze && flutter test`
Expected: No issues, all tests pass

- [ ] **Step 5: 커밋**

```bash
git add lib/painters/isometric_bible_painter.dart lib/screens/bible_view/bible_view_screen.dart
git commit -m "feat: add block fill animation on progress change"
```

---

### Task 5: 인트로 애니메이션

**Files:**
- Modify: `lib/painters/isometric_bible_painter.dart`
- Modify: `lib/screens/bible_view/bible_view_screen.dart`

- [ ] **Step 1: Painter에 introAnimation 파라미터 추가**

`IsometricBiblePainter`에 필드 추가:

```dart
final double introAnimation; // 0.0 ~ 1.0
```

생성자에 추가:

```dart
this.introAnimation = 1.0,
```

`shouldRepaint`에 추가:

```dart
oldDelegate.introAnimation != introAnimation
```

- [ ] **Step 2: _drawPageBlocks에서 인트로 효과 적용**

블록 렌더링 시 인트로 애니메이션 적용 (채움 애니메이션보다 우선):

```dart
// 인트로: 아래→위, 뒤→앞 순서로 나타남
double introOpacity = 1.0;
double introZOffset = 0;
if (introAnimation < 1.0) {
  // 블록마다 순차적 딜레이: 아래→위(z), 뒤→앞(y)
  final order = (bookHeight - 1 - z) * bookDepth + (bookDepth - 1 - y);
  final maxOrder = bookHeight * bookDepth;
  final blockDelay = order / maxOrder * 0.6; // 60%의 시간에 걸쳐 순차 시작
  final localT = ((introAnimation - blockDelay) / 0.4).clamp(0.0, 1.0);
  introOpacity = localT;
  introZOffset = (1.0 - localT) * 3.0; // 위에서 3블록 높이
}
if (introOpacity <= 0) continue; // 아직 안 보이는 블록은 스킵

final effectiveZ = z.toDouble() + zOffset + introZOffset;
```

커버와 스파인에도 동일 패턴 적용 (introAnimation < 1.0이면 opacity/offset 적용).

- [ ] **Step 3: BibleViewScreen에 인트로 컨트롤러 추가**

`_BibleViewScreenState`에 추가:

```dart
late AnimationController _introController;
bool _introPlayed = false;
```

`initState`에 추가:

```dart
_introController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1500),
);
```

`dispose`에 추가:

```dart
_introController.dispose();
```

데이터 로드 완료 시 인트로 시작 (build 내 `data:` 핸들러):

```dart
if (!_introPlayed) {
  _introPlayed = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _introController.forward(from: 0.0);
  });
}
```

인트로 중 호버/탭 무시 — `_onPointerHover`, `_onPointerUp`에 가드:

```dart
if (_introController.isAnimating) return;
```

`AnimatedBuilder` animation에 `_introController` 추가.

Painter에 전달:

```dart
introAnimation: _introController.value,
```

- [ ] **Step 4: flutter analyze + test**

Run: `flutter analyze && flutter test`
Expected: No issues, all tests pass

- [ ] **Step 5: 수동 테스트**

Run: `flutter run -d chrome`
확인: 앱 최초 진입 시 블록들이 아래→위 순서로 나타남, 1.5초 후 인터랙션 활성화

- [ ] **Step 6: 커밋**

```bash
git add lib/painters/isometric_bible_painter.dart lib/screens/bible_view/bible_view_screen.dart
git commit -m "feat: add intro animation on first 3D view load"
```

---

### Task 6: 히트테스트 회전 테스트

**Files:**
- Create: `test/painters/block_hit_test_test.dart`

- [ ] **Step 1: 회전 상태 히트테스트 검증 테스트 작성**

```dart
// test/painters/block_hit_test_test.dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:bible_blocks/painters/block_hit_test.dart';

void main() {
  group('BlockHitTest with rotation', () {
    const canvasSize = Size(400, 400);

    test('hitTest at angle=0 returns same results as before', () {
      final center = BlockHitTest.blockTopCenter(
        (x: 4, y: 0, z: 6),
        canvasSize,
        0,
      );
      final hit = BlockHitTest.hitTest(center, canvasSize, 0);
      expect(hit, isNotNull);
      expect(hit!.x, 4);
      expect(hit.y, 0);
      expect(hit.z, 6);
    });

    test('hitTest at angle=pi/2 finds rotated block', () {
      // 90도 회전 후, 블록 (4,0,6)의 중심에서 히트테스트
      final center = BlockHitTest.blockTopCenter(
        (x: 4, y: 0, z: 6),
        canvasSize,
        pi / 2,
      );
      final hit = BlockHitTest.hitTest(center, canvasSize, pi / 2);
      expect(hit, isNotNull);
      expect(hit!.x, 4);
      expect(hit.y, 0);
      expect(hit.z, 6);
    });

    test('tooltipText returns correct info', () {
      final blockIndex = BlockHitTest.toBlockIndex((x: 0, y: 0, z: 0));
      final text = BlockHitTest.tooltipText(blockIndex, {});
      expect(text, contains('읽음'));
    });
  });
}
```

- [ ] **Step 2: 테스트 실행, 통과 확인**

Run: `flutter test test/painters/block_hit_test_test.dart`
Expected: PASS

- [ ] **Step 3: 커밋**

```bash
git add test/painters/block_hit_test_test.dart
git commit -m "test: add rotation hit test verification"
```

---

### Task 7: 최종 통합 검증

- [ ] **Step 1: 전체 정적 분석**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 2: 전체 테스트**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 3: 수동 통합 테스트**

Run: `flutter run -d chrome`

체크리스트:
1. 앱 진입 → 인트로 애니메이션 (블록 순차 등장)
2. 인트로 완료 후 블록 탭 → 바운스 + 툴팁
3. 회전 버튼 좌/우 → 부드러운 연속 회전, 놓으면 멈춤
4. 회전된 상태에서 블록 탭 → 정확한 히트테스트
5. 체크리스트 탭에서 읽음 처리 → 3D 뷰 복귀 → 블록 채워지는 애니메이션
6. 핀치줌/팬 정상 동작

- [ ] **Step 4: 최종 커밋**

```bash
git add -A
git commit -m "feat: interaction v2 - rotation, fill animation, intro animation"
```
