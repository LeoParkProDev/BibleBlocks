import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:bible_blocks/painters/block_hit_test.dart';

void main() {
  const origin = Offset(200, 300);

  // R-01: angle=0 produces same result as original formula
  test('R-01: angle=0 matches original projection', () {
    // At angle=0, rotation is identity: rotatedX=x, rotatedY=y
    // Expected: same as BlockHitTest.project without angle
    const x = 3.0, y = 2.0, z = 1.0;

    final withAngle = BlockHitTest.project(x, y, z, origin, 0);
    final withoutAngle = BlockHitTest.project(x, y, z, origin);

    expect(withAngle.dx, closeTo(withoutAngle.dx, 0.001));
    expect(withAngle.dy, closeTo(withoutAngle.dy, 0.001));
  });

  // R-02: angle=pi/2 swaps axes (rotatedX=-y, rotatedY=x)
  test('R-02: angle=pi/2 swaps axes correctly', () {
    const x = 1.0, y = 0.0, z = 0.0;
    // At angle=pi/2: rotatedX = x*cos(pi/2) - y*sin(pi/2) = 0
    //                rotatedY = x*sin(pi/2) + y*cos(pi/2) = 1
    // So projection of (1,0,0) at pi/2 == projection of (0,1,0) at angle=0
    const cos30 = 0.866;
    const sin30 = 0.5;
    const blockSize = 14.0;

    final projected = BlockHitTest.project(x, y, z, origin, pi / 2);

    // rotatedX = 0, rotatedY = 1
    final expectedDx = origin.dx + (0.0 - 1.0) * cos30 * blockSize;
    final expectedDy = origin.dy + (0.0 + 1.0) * sin30 * blockSize - z * blockSize;

    expect(projected.dx, closeTo(expectedDx, 0.01));
    expect(projected.dy, closeTo(expectedDy, 0.01));
  });

  // R-03: angle=pi mirrors the view (x->-x, y->-y in screen coords)
  test('R-03: angle=pi mirrors view — projection of (x,y,z) equals projection of (-x,-y,z) at angle=0', () {
    const x = 2.0, y = 3.0, z = 1.0;
    // At angle=pi: rotatedX = x*cos(pi) - y*sin(pi) = -x
    //              rotatedY = x*sin(pi) + y*cos(pi) = -y
    // So project(x,y,z,origin,pi) should equal project(-x,-y,z,origin,0)
    final atPi = BlockHitTest.project(x, y, z, origin, pi);
    final mirrored = BlockHitTest.project(-x, -y, z, origin, 0);

    expect(atPi.dx, closeTo(mirrored.dx, 0.01));
    expect(atPi.dy, closeTo(mirrored.dy, 0.01));
  });

  // R-04: z component is unaffected by rotation angle
  test('R-04: z component unaffected by rotation angle', () {
    const x = 1.0, y = 1.0;
    // For various angles, changing z by dz should always shift dy by -blockSize*dz
    const blockSize = 14.0;

    for (final angle in [0.0, pi / 4, pi / 2, pi]) {
      final pz0 = BlockHitTest.project(x, y, 0.0, origin, angle);
      final pz1 = BlockHitTest.project(x, y, 1.0, origin, angle);
      final pz2 = BlockHitTest.project(x, y, 2.0, origin, angle);

      // dx should not change with z
      expect(pz1.dx, closeTo(pz0.dx, 0.001),
          reason: 'dx should be same for different z at angle=$angle');
      expect(pz2.dx, closeTo(pz0.dx, 0.001),
          reason: 'dx should be same for different z at angle=$angle');

      // dy decreases by blockSize per unit z
      expect(pz1.dy, closeTo(pz0.dy - blockSize, 0.001),
          reason: 'dy should decrease by blockSize per z at angle=$angle');
      expect(pz2.dy, closeTo(pz0.dy - 2 * blockSize, 0.001),
          reason: 'dy should decrease by 2*blockSize per 2z at angle=$angle');
    }
  });

  // R-05: default angle (omitted) produces same result as angle=0
  test('R-05: omitted angle defaults to 0', () {
    const x = 4.0, y = 1.0, z = 2.0;
    final withDefault = BlockHitTest.project(x, y, z, origin);
    final withZero = BlockHitTest.project(x, y, z, origin, 0);

    expect(withDefault.dx, closeTo(withZero.dx, 0.001));
    expect(withDefault.dy, closeTo(withZero.dy, 0.001));
  });

  // R-06: face path methods accept angle parameter without error
  test('R-06: face path methods accept angle parameter', () {
    const angle = pi / 6;
    expect(
      () => BlockHitTest.topFacePath(0, 0, 0, origin, angle),
      returnsNormally,
    );
    expect(
      () => BlockHitTest.leftFacePath(0, 0, 0, origin, angle),
      returnsNormally,
    );
    expect(
      () => BlockHitTest.rightFacePath(0, 0, 0, origin, angle),
      returnsNormally,
    );
  });
}
