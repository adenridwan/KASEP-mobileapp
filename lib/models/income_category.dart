class IncomeCategory {
  final String id;
  final String name;
  final DateTime createdAt;
  final bool isActive;

  IncomeCategory({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory IncomeCategory.fromMap(Map<String, dynamic> map) {
    return IncomeCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isActive: (map['isActive'] as int?) == 1,
    );
  }

  IncomeCategory copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return IncomeCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
