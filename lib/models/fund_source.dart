class FundSource {
  final String id;
  final String name;
  final String? icon;
  final int initialBalance;
  final DateTime createdAt;
  final bool isActive;

  FundSource({
    required this.id,
    required this.name,
    this.icon,
    this.initialBalance = 0,
    required this.createdAt,
    this.isActive = true,
  });

  /// Convert FundSource to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'initialBalance': initialBalance,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  /// Create FundSource from database Map
  factory FundSource.fromMap(Map<String, dynamic> map) {
    return FundSource(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      initialBalance: (map['initialBalance'] as int?) ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isActive: (map['isActive'] as int?) == 1,
    );
  }

  FundSource copyWith({
    String? id,
    String? name,
    String? icon,
    int? initialBalance,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return FundSource(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      initialBalance: initialBalance ?? this.initialBalance,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
