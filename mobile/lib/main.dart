import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config.dart';
import 'core/providers.dart';

Future<void> main() async {
  final problem = releaseConfigProblem(
    isRelease: kReleaseMode,
    apiBaseUrl: AppConfig.apiBaseUrl,
    publicSiteUrl: AppConfig.publicSiteUrl,
  );
  if (problem != null) throw StateError(problem);
  WidgetsFlutterBinding.ensureInitialized();
  // The bundled font's licence (SIL Open Font License) travels with it.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'DM Sans',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  await initializeDateFormatting();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      // Failed requests are retried by the user ("Try again"), not silently.
      retry: (_, _) => null,
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const FanikishaApp(),
    ),
  );
}
