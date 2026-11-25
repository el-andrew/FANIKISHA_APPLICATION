import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/l10n.dart';
import 'providers.dart';
import 'widgets/async_views.dart';

enum LegalPage {
  privacy('/privacy'),
  terms('/terms');

  const LegalPage(this.path);
  final String path;
}

/// The page on the public site ([siteUrl]), in [language].
Uri legalPageUri(LegalPage page, String siteUrl, String language) => Uri.parse(
  siteUrl,
).replace(path: page.path, queryParameters: {'lang': language});

typedef UrlOpener = Future<bool> Function(Uri uri);

/// Opens a URL in the phone's browser. Replaced in tests.
final urlOpenerProvider = Provider<UrlOpener>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

Future<void> openLegalPage(
  BuildContext context,
  WidgetRef ref,
  LegalPage page,
) async {
  final l10n = context.l10n;
  final uri = legalPageUri(
    page,
    ref.read(publicSiteUrlProvider),
    l10n.localeName,
  );
  final opened = await ref.read(urlOpenerProvider)(uri);
  if (!opened && context.mounted) showMessage(context, l10n.errorUnknown);
}
