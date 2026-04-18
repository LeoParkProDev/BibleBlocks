// Standalone voxel-count comparison.
// flutter run -t lib/main_voxel_count.dart -d chrome
import 'package:flutter/material.dart';

import 'painters/noahs_ark_painter.dart';
import 'painters/solomons_temple_painter.dart';
import 'painters/pilgrim_c_mountain_painter.dart';

void main() {
  final ark = ArkVoxels.build().length;
  final temple = templeVoxels.length;
  final pilgrim = PilgrimCLandscape.voxels.length;
  final pilgrimPath = PilgrimCLandscape.pathLength;

  final buf = StringBuffer()
    ..writeln('Noah ark       : $ark voxels')
    ..writeln('Solomon temple : $temple voxels')
    ..writeln('Pilgrim C      : $pilgrim voxels (path=$pilgrimPath)')
    ..writeln('Ratio C/Ark    : ${(pilgrim / ark).toStringAsFixed(1)}x')
    ..writeln('Ratio C/Temple : ${(pilgrim / temple).toStringAsFixed(1)}x');

  debugPrint(buf.toString());
  runApp(MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Center(
        child: Text(buf.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 18)),
      ),
    ),
  ));
}
