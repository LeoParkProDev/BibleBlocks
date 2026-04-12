import 'package:flutter/material.dart';

import 'config/router.dart';
import 'theme/app_theme.dart';

class BibleBlocksApp extends StatelessWidget {
  const BibleBlocksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BibleBlocks',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
