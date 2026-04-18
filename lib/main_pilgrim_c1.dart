import 'package:flutter/material.dart';

import 'screens/pilgrim_preview_c1_screen.dart';

void main() => runApp(const _App());

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BibleBlocks · Pilgrim C1',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0A1A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFC47B5A),
            secondary: Color(0xFFD4A843),
            surface: Color(0xFF151530),
          ),
          useMaterial3: true,
        ),
        home: const PilgrimPreviewC1Screen(),
      );
}
