import 'package:flutter/material.dart';

import 'screens/pilgrim_preview_b_screen.dart';

/// Standalone entry point for the Pilgrim's Progress (B) isometric maze preview.
///
/// Run with:
///   flutter run -t lib/main_pilgrim_b.dart -d chrome
void main() {
  runApp(const _PilgrimBApp());
}

class _PilgrimBApp extends StatelessWidget {
  const _PilgrimBApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BibleBlocks · Pilgrim B Preview',
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
      home: const PilgrimPreviewBScreen(),
    );
  }
}
