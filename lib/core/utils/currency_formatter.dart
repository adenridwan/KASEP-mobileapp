import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat('#,###', 'id_ID');

  static String format(int amount) {
    return _formatter.format(amount).replaceAll(',', '.');
  }

  static String formatWithRp(int amount) {
    return 'Rp ${format(amount)}';
  }

  static String formatWithSign(int amount, {bool isIncome = false}) {
    final prefix = isIncome ? '+' : '−';
    return '$prefix${format(amount)}';
  }

  static String formatDigits(String digits) {
    if (digits.isEmpty) return '0';
    final number = int.tryParse(digits) ?? 0;
    return format(number);
  }
}
