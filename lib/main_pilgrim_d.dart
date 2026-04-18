import 'package:flutter/material.dart';

import 'screens/pilgrim_preview_d_screen.dart';

/// Standalone entry for the Pilgrim's Progress (D) journey scroll preview.
/// Run: flutter run -t lib/main_pilgrim_d.dart -d chrome
void main() {
  runApp(const _PilgrimDApp());
}

class _PilgrimDApp extends StatelessWidget {
  const _PilgrimDApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BibleBlocks · Pilgrim D Preview',
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
      home: const PilgrimPreviewDScreen(),
    );
  }
}
