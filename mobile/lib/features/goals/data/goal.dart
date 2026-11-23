import '../../../core/format/dates.dart';

enum GoalStatus {
  active('ACTIVE'),
  completed('COMPLETED'),
  archived('ARCHIVED');

  const GoalStatus(this.apiValue);
  final String apiValue;

  static GoalStatus fromApi(String value) =>
      values.firstWhere((status) => status.apiValue == value);
}

class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.remainingAmount,
    required this.progressPercent,
    required this.priority,
    required this.startDate,
    required this.targetDate,
    required this.daysLeft,
    required this.dailyTargetAmount,
    required this.status,
    this.category,
    this.completedAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String?,
    targetAmount: (json['targetAmount'] as num).toInt(),
    savedAmount: (json['savedAmount'] as num).toInt(),
    remainingAmount: (json['remainingAmount'] as num).toInt(),
    progressPercent: (json['progressPercent'] as num).toDouble(),
    priority: (json['priority'] as num).toInt(),
    startDate: parseDateOnly(json['startDate'] as String),
    targetDate: parseDateOnly(json['targetDate'] as String),
    daysLeft: (json['daysLeft'] as num).toInt(),
    dailyTargetAmount: (json['dailyTargetAmount'] as num).toInt(),
    status: GoalStatus.fromApi(json['status'] as String),
    completedAt: json['completedAt'] == null
        ? null
        : DateTime.parse(json['completedAt'] as String),
  );

  final String id;
  final String name;
  final String? category;
  final int targetAmount;
  final int savedAmount;
  final int remainingAmount;

  /// 0 to 100.
  final double progressPercent;

  /// 1 (low) to 5 (very high).
  final int priority;
  final DateTime startDate;
  final DateTime targetDate;
  final int daysLeft;

  /// Shillings per day needed to finish on time.
  final int dailyTargetAmount;
  final GoalStatus status;
  final DateTime? completedAt;

  double get progress => (progressPercent / 100).clamp(0, 1);
}
