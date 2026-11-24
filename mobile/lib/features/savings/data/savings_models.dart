class Allocation {
  const Allocation({
    required this.goalId,
    required this.goalName,
    required this.amount,
  });

  factory Allocation.fromJson(Map<String, dynamic> json) => Allocation(
    goalId: json['goalId'] as String,
    goalName: json['goalName'] as String,
    amount: (json['amount'] as num).toInt(),
  );

  final String goalId;
  final String goalName;
  final int amount;
}

/// How a deposit is (or would be) shared between goals.
class DepositSplit {
  const DepositSplit({
    required this.amount,
    required this.unallocatedAmount,
    required this.allocations,
  });

  factory DepositSplit.fromJson(Map<String, dynamic> json) => DepositSplit(
    amount: (json['amount'] as num).toInt(),
    unallocatedAmount: (json['unallocatedAmount'] as num).toInt(),
    allocations: (json['allocations'] as List<Object?>)
        .cast<Map<String, dynamic>>()
        .map(Allocation.fromJson)
        .toList(),
  );

  final int amount;

  /// The part no goal needed, kept as general savings.
  final int unallocatedAmount;
  final List<Allocation> allocations;
}

class Deposit extends DepositSplit {
  const Deposit({
    required this.id,
    required this.createdAt,
    required super.amount,
    required super.unallocatedAmount,
    required super.allocations,
    this.note,
  });

  factory Deposit.fromJson(Map<String, dynamic> json) {
    final split = DepositSplit.fromJson(json);
    return Deposit(
      id: json['id'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      amount: split.amount,
      unallocatedAmount: split.unallocatedAmount,
      allocations: split.allocations,
    );
  }

  final String id;
  final String? note;
  final DateTime createdAt;
}

class DepositPage {
  const DepositPage({required this.items, required this.nextCursor});

  factory DepositPage.fromJson(Map<String, dynamic> json) => DepositPage(
    items: (json['items'] as List<Object?>)
        .cast<Map<String, dynamic>>()
        .map(Deposit.fromJson)
        .toList(),
    nextCursor: json['nextCursor'] as String?,
  );

  final List<Deposit> items;
  final String? nextCursor;
}

class SavingsSummary {
  const SavingsSummary({
    required this.totalDeposited,
    required this.unallocatedAmount,
    required this.depositCount,
    required this.activeGoals,
    required this.completedGoals,
  });

  factory SavingsSummary.fromJson(Map<String, dynamic> json) => SavingsSummary(
    totalDeposited: (json['totalDeposited'] as num).toInt(),
    unallocatedAmount: (json['unallocatedAmount'] as num).toInt(),
    depositCount: (json['depositCount'] as num).toInt(),
    activeGoals: (json['activeGoals'] as num).toInt(),
    completedGoals: (json['completedGoals'] as num).toInt(),
  );

  final int totalDeposited;
  final int unallocatedAmount;
  final int depositCount;
  final int activeGoals;
  final int completedGoals;
}

enum SavingBasis {
  sales('SALES'),
  profit('PROFIT');

  const SavingBasis(this.apiValue);
  final String apiValue;

  static SavingBasis fromApi(String value) =>
      values.firstWhere((b) => b.apiValue == value);
}

/// "Save [percent]% of each day's [basis]".
class SavingRule {
  const SavingRule({required this.basis, required this.percent});

  static SavingRule? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return SavingRule(
      basis: SavingBasis.fromApi(json['basis'] as String),
      percent: (json['percent'] as num).toInt(),
    );
  }

  final SavingBasis basis;
  final int percent;

  /// What the rule asks to save for a day; nothing on a day with a loss.
  int targetFor({required int sales, required int expenses}) {
    final base = basis == SavingBasis.sales
        ? sales
        : (sales - expenses).clamp(0, sales);
    return base * percent ~/ 100;
  }
}

/// Today's sales and what the saving rule asks to save from them.
class TodaySavings {
  const TodaySavings({
    required this.sales,
    required this.expenses,
    required this.profit,
    required this.rule,
    required this.target,
    required this.savedToday,
    required this.remaining,
  });

  factory TodaySavings.fromJson(Map<String, dynamic> json) => TodaySavings(
    sales: (json['sales'] as num).toInt(),
    expenses: (json['expenses'] as num).toInt(),
    profit: (json['profit'] as num).toInt(),
    rule: SavingRule.fromJson(json['rule']),
    target: (json['target'] as num).toInt(),
    savedToday: (json['savedToday'] as num).toInt(),
    remaining: (json['remaining'] as num).toInt(),
  );

  final int sales;
  final int expenses;
  final int profit;
  final SavingRule? rule;
  final int target;
  final int savedToday;
  final int remaining;
}
