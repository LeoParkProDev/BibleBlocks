import 'package:flutter/material.dart';

import 'screens/pilgrim_preview_e_screen.dart';

/// Standalone entry for the Pilgrim's Progress (E) constellation preview.
/// Run: flutter run -t lib/main_pilgrim_e.dart -d chrome
void main() {
  runApp(const _PilgrimEApp());
}

class _PilgrimEApp extends StatelessWidget {
  const _PilgrimEApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BibleBlocks · Pilgrim E Preview',
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
      home: const PilgrimPreviewEScreen(),
    );
  }
}
