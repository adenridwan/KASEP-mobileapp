class MonthlyNote {
  final String id;
  final int year;
  final int month;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyNote({
    required this.id,
    required this.year,
    required this.month,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'month': month,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MonthlyNote.fromMap(Map<String, dynamic> map) {
    return MonthlyNote(
      id: map['id'] as String,
      year: map['year'] as int,
      month: map['month'] as int,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  MonthlyNote copyWith({
    String? id,
    int? year,
    int? month,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyNote(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedMonth {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${months[month - 1]} $year';
  }

  bool get isEmpty => content.trim().isEmpty;
  bool get isNotEmpty => content.trim().isNotEmpty;
}
