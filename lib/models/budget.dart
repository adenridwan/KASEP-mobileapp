class Budget {
  final String id;
  final String? name; // Optional custom label, e.g. "Jajan anak"
  final String? category; // null = all expense categories
  final String? fundSourceId; // null = all fund sources
  final int amount; // Target amount
  final int month;
  final int year;
  final DateTime createdAt;

  Budget({
    required this.id,
    this.name,
    this.category,
    this.fundSourceId,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdAt,
  });

  /// Display title: custom name, else category, else "Semua pengeluaran"
  String get label {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    return category ?? 'Semua pengeluaran';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'fundSourceId': fundSourceId,
      'amount': amount,
      'month': month,
      'year': year,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      name: map['name'] as String?,
      category: map['category'] as String?,
      fundSourceId: map['fundSourceId'] as String?,
      amount: map['amount'] as int,
      month: map['month'] as int,
      year: map['year'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

/// Budget with current spending info
class BudgetProgress {
  final Budget budget;
  final int spent;
  final String? fundSourceName;

  BudgetProgress({
    required this.budget,
    required this.spent,
    this.fundSourceName,
  });

  int get remaining => budget.amount - spent;
  double get percentage => budget.amount > 0 ? (spent / budget.amount * 100).clamp(0, 100) : 0;
  bool get isOverBudget => spent > budget.amount;
  bool get isWarning => percentage >= 80 && !isOverBudget;
}
