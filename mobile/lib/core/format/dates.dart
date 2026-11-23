import 'package:intl/intl.dart';

/// `2026-03-01` → a local DateTime at midnight.
DateTime parseDateOnly(String value) => DateTime.parse(value);

/// A DateTime → `2026-03-01`, as the API expects.
String toDateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// `1 Mar 2026`, in the app's language.
String formatDate(DateTime date, String locale) =>
    DateFormat.yMMMd(_dateLocale(locale)).format(date);

/// `1 Mar 2026, 14:05`, in the app's language.
String formatDateTime(DateTime date, String locale) =>
    DateFormat.yMMMd(_dateLocale(locale)).add_Hm().format(date.toLocal());

/// Tanzania writes the day first; plain `en` would give US order (Mar 1).
String _dateLocale(String locale) => locale == 'en' ? 'en_GB' : locale;
