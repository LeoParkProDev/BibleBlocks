import 'package:bible_blocks/painters/noahs_ark_painter.dart';
import 'package:bible_blocks/painters/solomons_temple_painter.dart';
import 'package:bible_blocks/painters/pilgrim_c_mountain_painter.dart';
import 'package:bible_blocks/painters/pilgrim_c3_opt_painter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('voxel counts', () {
    final ark = ArkVoxels.build().length;
    final temple = templeVoxels.length;
    final pilgrim = PilgrimCLandscape.voxels.length;
    final pilgrimPath = PilgrimCLandscape.pathLength;
    final c3Opt = PilgrimC3OptPainter.cachedVoxelCount;
    // ignore: avoid_print
    print('----------- voxel count report -----------');
    // ignore: avoid_print
    print('Noah ark          : $ark');
    // ignore: avoid_print
    print('Solomon temple    : $temple');
    // ignore: avoid_print
    print('Pilgrim C         : $pilgrim (path=$pilgrimPath)');
    // ignore: avoid_print
    print('Pilgrim C3.opt    : $c3Opt');
    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print('C3.opt / Ark      : ${(c3Opt / ark).toStringAsFixed(2)}x');
    // ignore: avoid_print
    print('C3.opt / Temple   : ${(c3Opt / temple).toStringAsFixed(2)}x');
    // ignore: avoid_print
    print('C3.opt vs C       : ${(c3Opt / pilgrim * 100).toStringAsFixed(0)}% (reduction '
        '${((1 - c3Opt / pilgrim) * 100).toStringAsFixed(0)}%)');
    // ignore: avoid_print
    print('------------------------------------------');
  });
}
