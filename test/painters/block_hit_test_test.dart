import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:bible_blocks/painters/block_hit_test.dart';

void main() {
  group('BlockHitTest with rotation', () {
    const canvasSize = Size(400, 400);

    test('hitTest at angle=0 finds block at its top center', () {
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

    test('hitTest at angle=pi/2 finds rotated block at its center', () {
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

    test('hitTest at angle=pi finds block correctly', () {
      final center = BlockHitTest.blockTopCenter(
        (x: 2, y: 1, z: 3),
        canvasSize,
        pi,
      );
      final hit = BlockHitTest.hitTest(center, canvasSize, pi);
      expect(hit, isNotNull);
      expect(hit!.x, 2);
      expect(hit.y, 1);
      expect(hit.z, 3);
    });

    test('tooltipText returns correct info for empty progress', () {
      final blockIndex = BlockHitTest.toBlockIndex((x: 0, y: 0, z: 0));
      final text = BlockHitTest.tooltipText(blockIndex, {});
      expect(text, contains('읽음'));
      expect(text, contains('0/'));
    });

    test('hitTest returns null for point far outside book', () {
      final hit = BlockHitTest.hitTest(const Offset(0, 0), canvasSize, 0);
      expect(hit, isNull);
    });
  });
}
