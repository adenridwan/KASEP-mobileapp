class CategorySummary {
  final String name;
  final int totalAmount;
  final int transactionCount;
  final double percentage;

  CategorySummary({
    required this.name,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentage,
  });

  int get averageAmount =>
      transactionCount > 0 ? totalAmount ~/ transactionCount : 0;
}
