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
    required this.balance,
    required this.totalWithdrawn,
    required this.totalDeposited,
    required this.unallocatedAmount,
    required this.depositCount,
    required this.activeGoals,
    required this.completedGoals,
  });

  factory SavingsSummary.fromJson(Map<String, dynamic> json) => SavingsSummary(
    balance: (json['balance'] as num).toInt(),
    totalWithdrawn: (json['totalWithdrawn'] as num).toInt(),
    totalDeposited: (json['totalDeposited'] as num).toInt(),
    unallocatedAmount: (json['unallocatedAmount'] as num).toInt(),
    depositCount: (json['depositCount'] as num).toInt(),
    activeGoals: (json['activeGoals'] as num).toInt(),
    completedGoals: (json['completedGoals'] as num).toInt(),
  );

  /// The money saved now: in goals plus general savings.
  final int balance;
  final int totalWithdrawn;
  final int totalDeposited;

  /// General savings: saved money that is not in any goal.
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

/// A goal, or general savings when [goalId] is null.
class MoneyPlace {
  const MoneyPlace({this.goalId, this.goalName});

  factory MoneyPlace.fromJson(Map<String, dynamic> json) => MoneyPlace(
    goalId: json['goalId'] as String?,
    goalName: json['goalName'] as String?,
  );

  final String? goalId;
  final String? goalName;

  bool get isGeneralSavings => goalId == null;
}

/// One line of savings history.
sealed class Activity {
  const Activity();

  static Activity fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String;
    if (kind == 'DEPOSIT') return DepositActivity(Deposit.fromJson(json));
    return MovementActivity(
      id: json['id'] as String,
      isTransfer: kind == 'TRANSFER',
      amount: (json['amount'] as num).toInt(),
      from: MoneyPlace.fromJson(json['from'] as Map<String, dynamic>),
      to: json['to'] == null
          ? null
          : MoneyPlace.fromJson(json['to'] as Map<String, dynamic>),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class DepositActivity extends Activity {
  const DepositActivity(this.deposit);
  final Deposit deposit;
}

/// A withdrawal, or a transfer between goals and general savings.
class MovementActivity extends Activity {
  const MovementActivity({
    required this.id,
    required this.isTransfer,
    required this.amount,
    required this.from,
    required this.to,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final bool isTransfer;
  final int amount;
  final MoneyPlace from;

  /// Transfers only.
  final MoneyPlace? to;
  final String? note;
  final DateTime createdAt;
}

class ActivityPage {
  const ActivityPage({required this.items, required this.nextCursor});

  factory ActivityPage.fromJson(Map<String, dynamic> json) => ActivityPage(
    items: (json['items'] as List<Object?>)
        .cast<Map<String, dynamic>>()
        .map(Activity.fromJson)
        .toList(),
    nextCursor: json['nextCursor'] as String?,
  );

  final List<Activity> items;
  final String? nextCursor;
}
