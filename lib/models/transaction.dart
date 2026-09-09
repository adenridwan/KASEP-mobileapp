class Transaction {
  final String id;
  final String title;
  final int amount;
  final String category;
  final DateTime dateTime;
  final String? note;
  final bool isIncome;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.dateTime,
    this.note,
    this.isIncome = false,
  });

  /// Convert Transaction to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'dateTime': dateTime.toIso8601String(),
      'note': note,
      'isIncome': isIncome ? 1 : 0,
    };
  }

  /// Create Transaction from database Map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: map['amount'] as int,
      category: map['category'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      note: map['note'] as String?,
      isIncome: (map['isIncome'] as int) == 1,
    );
  }

  String get formattedTime {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  String get formattedDateTime => '$formattedDate, $formattedTime';

  Transaction copyWith({
    String? id,
    String? title,
    int? amount,
    String? category,
    DateTime? dateTime,
    String? note,
    bool? isIncome,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      note: note ?? this.note,
      isIncome: isIncome ?? this.isIncome,
    );
  }
}
