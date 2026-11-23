import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../api/api_exception.dart';

export '../../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get localeName => AppLocalizations.of(this).localeName;
}

/// A message for any error, in the app's language where we have one.
/// Requests the API refused come with the server's own explanation.
String describeError(Object error, AppLocalizations l10n) {
  if (error is ApiException) {
    switch (error.kind) {
      case ApiErrorKind.network:
        return l10n.errorNetwork;
      case ApiErrorKind.server:
        return l10n.errorServer;
      case ApiErrorKind.sessionExpired:
        return l10n.errorSessionExpired;
      case ApiErrorKind.rejected:
        if (error.messages.isNotEmpty) return error.messages.join('\n');
    }
  }
  return l10n.errorUnknown;
}

String priorityLabel(int priority, AppLocalizations l10n) => switch (priority) {
  1 => l10n.priority1,
  2 => l10n.priority2,
  3 => l10n.priority3,
  4 => l10n.priority4,
  _ => l10n.priority5,
};
