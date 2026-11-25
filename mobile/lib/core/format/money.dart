import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _grouped = NumberFormat.decimalPattern('en');

/// `TZS 1,250,000`. Amounts are whole shillings.
String formatTzs(num amount) => 'TZS ${_grouped.format(amount)}';

/// `1,250,000`, for places where the currency is already shown.
String formatGrouped(num amount) => _grouped.format(amount);

/// Reads a typed amount, ignoring separators: `1,250,000` → 1250000.
/// Returns null for an empty or unreadable value.
int? parseAmount(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty || digits.length > 13) return null;
  return int.parse(digits);
}

/// Accepts digits only and shows them grouped in thousands while typing.
class AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    if (digits.length > 13) return oldValue;
    final formatted = _grouped.format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
