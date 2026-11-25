import '../l10n/app_localizations.dart';
import 'format/money.dart';

// The same rules the API applies, checked before sending.

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _phone = RegExp(r'^\+[1-9]\d{7,14}$');

String? validateEmail(String? value, AppLocalizations l10n) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return l10n.fieldRequired;
  return _email.hasMatch(text) ? null : l10n.emailInvalid;
}

String? validateNewPassword(String? value, AppLocalizations l10n) {
  final text = value ?? '';
  if (text.isEmpty) return l10n.fieldRequired;
  return text.length < 8 ? l10n.passwordTooShort : null;
}

String? validateRequired(String? value, AppLocalizations l10n) =>
    (value?.trim() ?? '').isEmpty ? l10n.fieldRequired : null;

String? validateFullName(String? value, AppLocalizations l10n) =>
    (value?.trim() ?? '').length < 2 ? l10n.fullNameInvalid : null;

/// Empty is fine (the phone number is optional).
String? validateOptionalPhone(String? value, AppLocalizations l10n) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return _phone.hasMatch(text) ? null : l10n.phoneInvalid;
}

String? validateAmount(String? value, AppLocalizations l10n) {
  final amount = parseAmount(value ?? '');
  return amount == null || amount <= 0 ? l10n.amountInvalid : null;
}

/// Trimmed text, or null when blank.
String? trimmedOrNull(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}
