import 'package:fanikisha/core/format/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats whole shillings with thousands separators', () {
    expect(formatTzs(1250000), 'TZS 1,250,000');
    expect(formatTzs(0), 'TZS 0');
  });

  test('parses typed amounts, ignoring separators', () {
    expect(parseAmount('1,250,000'), 1250000);
    expect(parseAmount(' 5000 '), 5000);
    expect(parseAmount(''), isNull);
    expect(parseAmount('abc'), isNull);
    expect(parseAmount('12345678901234'), isNull);
  });

  test('groups digits while typing and drops anything else', () {
    final formatter = AmountInputFormatter();
    TextEditingValue type(String text) => formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: text),
    );
    expect(type('1250000').text, '1,250,000');
    expect(type('12a3').text, '123');
    expect(type('').text, '');
  });
}
