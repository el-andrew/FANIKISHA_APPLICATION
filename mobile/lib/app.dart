import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/reminders/reminders.dart';
import 'l10n/app_localizations.dart';

class FanikishaApp extends ConsumerWidget {
  const FanikishaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the phone's reminders up to date for as long as the app runs.
    ref.listen(reminderSyncProvider, (_, _) {});
    return MaterialApp.router(
      title: 'Fanikisha',
      debugShowCheckedModeBanner: false,
      // Light only, for now: the design is made for it.
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      locale: ref.watch(localeControllerProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
