import 'package:flutter/material.dart';

import 'screens/pilgrim_preview_a_screen.dart';

/// Standalone entry for the Pilgrim's Progress (A) spiral tower preview.
/// Run: flutter run -t lib/main_pilgrim_a.dart -d chrome
void main() {
  runApp(const _PilgrimAApp());
}

class _PilgrimAApp extends StatelessWidget {
  const _PilgrimAApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BibleBlocks · Pilgrim A Preview',
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
      home: const PilgrimPreviewAScreen(),
    );
  }
}
