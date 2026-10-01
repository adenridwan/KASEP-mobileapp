class Budget {
  final String id;
  final String category;
  final int amount; // Target amount
  final int month;
  final int year;
  final DateTime createdAt;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'month': month,
      'year': year,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      category: map['category'] as String,
      amount: map['amount'] as int,
      month: map['month'] as int,
      year: map['year'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Budget copyWith({
    String? id,
    String? category,
    int? amount,
    int? month,
    int? year,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Budget with current spending info
class BudgetProgress {
  final Budget budget;
  final int spent;

  BudgetProgress({
    required this.budget,
    required this.spent,
  });

  int get remaining => budget.amount - spent;
  double get percentage => budget.amount > 0 ? (spent / budget.amount * 100).clamp(0, 100) : 0;
  bool get isOverBudget => spent > budget.amount;
  bool get isWarning => percentage >= 80 && !isOverBudget;
}
