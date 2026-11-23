import 'package:fanikisha/core/format/dates.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  test('writes the day first, as in Tanzania', () {
    expect(formatDate(DateTime(2027, 2, 17), 'en'), '17 Feb 2027');
  });

  test('uses Swahili month names', () {
    expect(formatDate(DateTime(2027, 2, 17), 'sw'), contains('Feb'));
  });

  test('converts to and from the API date format', () {
    expect(toDateOnly(DateTime(2027, 2, 7)), '2027-02-07');
    expect(parseDateOnly('2027-02-07'), DateTime(2027, 2, 7));
  });
}
