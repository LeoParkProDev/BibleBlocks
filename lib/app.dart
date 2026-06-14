import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/router.dart';
import 'l10n/l10n.dart';
import 'providers/locale_provider.dart';
import 'theme/app_theme.dart';

class BibleBlocksApp extends ConsumerWidget {
  const BibleBlocksApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(routerProvider);
    // null = 시스템 기본(기기 언어). 저장값 없으면 한국어가 기본.
    final locale = ref.watch(localeProvider).value;
    return MaterialApp.router(
      title: 'BibleBlocks',
      theme: AppTheme.lightTheme,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
