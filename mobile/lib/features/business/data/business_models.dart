import '../../../core/format/dates.dart';

enum EntryType {
  sale('SALE'),
  expense('EXPENSE');

  const EntryType(this.apiValue);
  final String apiValue;

  static EntryType fromApi(String value) =>
      values.firstWhere((t) => t.apiValue == value);
}

class BusinessEntry {
  const BusinessEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.occurredOn,
    this.category,
    this.note,
  });

  factory BusinessEntry.fromJson(Map<String, dynamic> json) => BusinessEntry(
    id: json['id'] as String,
    type: EntryType.fromApi(json['type'] as String),
    amount: (json['amount'] as num).toInt(),
    category: json['category'] as String?,
    note: json['note'] as String?,
    occurredOn: parseDateOnly(json['occurredOn'] as String),
  );

  final String id;
  final EntryType type;
  final int amount;
  final String? category;
  final String? note;
  final DateTime occurredOn;
}

class EntryPage {
  const EntryPage({required this.items, required this.nextCursor});

  factory EntryPage.fromJson(Map<String, dynamic> json) => EntryPage(
    items: (json['items'] as List<Object?>)
        .cast<Map<String, dynamic>>()
        .map(BusinessEntry.fromJson)
        .toList(),
    nextCursor: json['nextCursor'] as String?,
  );

  final List<BusinessEntry> items;
  final String? nextCursor;
}

class DayTotals {
  const DayTotals({
    required this.date,
    required this.sales,
    required this.expenses,
  });

  final DateTime date;
  final int sales;
  final int expenses;
}

class BusinessSummary {
  const BusinessSummary({
    required this.sales,
    required this.expenses,
    required this.profit,
    required this.days,
    required this.expenseCategories,
  });

  factory BusinessSummary.fromJson(Map<String, dynamic> json) =>
      BusinessSummary(
        sales: (json['sales'] as num).toInt(),
        expenses: (json['expenses'] as num).toInt(),
        profit: (json['profit'] as num).toInt(),
        days: (json['days'] as List<Object?>)
            .cast<Map<String, dynamic>>()
            .map(
              (d) => DayTotals(
                date: parseDateOnly(d['date'] as String),
                sales: (d['sales'] as num).toInt(),
                expenses: (d['expenses'] as num).toInt(),
              ),
            )
            .toList(),
        expenseCategories: (json['expenseCategories'] as List<Object?>)
            .cast<Map<String, dynamic>>()
            .map(
              (c) => (
                category: c['category'] as String?,
                amount: (c['amount'] as num).toInt(),
              ),
            )
            .toList(),
      );

  final int sales;
  final int expenses;

  /// Sales minus expenses; negative for a loss.
  final int profit;
  final List<DayTotals> days;
  final List<({String? category, int amount})> expenseCategories;
}
