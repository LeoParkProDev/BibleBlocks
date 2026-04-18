import 'package:flutter/material.dart';

import 'screens/pilgrim_preview_c_screen.dart';

void main() {
  runApp(const PilgrimCApp());
}

class PilgrimCApp extends StatelessWidget {
  const PilgrimCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BibleBlocks — Pilgrim Mountain (C)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0a0a1a),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC47B5A),
          secondary: Color(0xFF7A8E99),
          surface: Color(0xFF0F0F22),
        ),
        fontFamily: 'Pretendard',
      ),
      home: const PilgrimPreviewCScreen(),
    );
  }
}
