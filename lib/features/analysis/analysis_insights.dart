import '../../core/utils/currency_formatter.dart';
import '../../models/budget.dart';
import '../../models/transaction.dart';

const _monthNames = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

enum InsightTone { positive, warning, negative, neutral }

enum InsightKind { target, saving, trendUp, trendDown, weekend, bigTransaction, noSpend, topCategory }

class Insight {
  final InsightKind kind;
  final InsightTone tone;
  final String text;

  const Insight(this.kind, this.tone, this.text);
}

class ScoreFactor {
  final String name;
  final int points;
  final int maxPoints;
  final String detail;

  const ScoreFactor(this.name, this.points, this.maxPoints, this.detail);
}

class HealthScore {
  final int score;
  final List<ScoreFactor> factors;

  const HealthScore(this.score, this.factors);

  InsightTone get tone => score >= 75
      ? InsightTone.positive
      : score >= 50
          ? InsightTone.warning
          : InsightTone.negative;

  String get label => score >= 75
      ? 'Sehat'
      : score >= 50
          ? 'Waspada'
          : 'Perlu perhatian';
}

class Projection {
  final bool isCurrentMonth;
  final int daysInMonth;
  final int daysElapsed;
  final int spent;
  final int avgDaily;
  final int projected;

  /// The amount spending is measured against: overall target, else income
  final int? limit;
  final String? limitLabel;

  const Projection({
    required this.isCurrentMonth,
    required this.daysInMonth,
    required this.daysElapsed,
    required this.spent,
    required this.avgDaily,
    required this.projected,
    this.limit,
    this.limitLabel,
  });

  /// Days left including today
  int get daysLeft => isCurrentMonth ? daysInMonth - daysElapsed + 1 : 0;
  int? get remaining => limit == null ? null : limit! - spent;
  int? get safeDaily =>
      remaining == null || daysLeft == 0 ? null : (remaining! / daysLeft).floor();
  bool get willExceed => limit != null && projected > limit!;
}

/// Everything the analysis needs for one month, already loaded from the DB
class AnalysisInput {
  final int year;
  final int month;
  final DateTime today;
  final int income;
  final int expense;
  final int previousExpense;
  final List<Map<String, dynamic>> categoryComparison;
  final Map<int, int> weekdayTotals; // 0 = Sunday
  final Map<int, int> dailyExpense; // day of month -> total
  final List<BudgetProgress> budgets;
  final List<Transaction> topExpenses;

  const AnalysisInput({
    required this.year,
    required this.month,
    required this.today,
    required this.income,
    required this.expense,
    required this.previousExpense,
    required this.categoryComparison,
    required this.weekdayTotals,
    required this.dailyExpense,
    required this.budgets,
    required this.topExpenses,
  });
}

class AnalysisResult {
  final Projection? projection;
  final HealthScore? score;
  final List<Insight> insights;

  const AnalysisResult(this.projection, this.score, this.insights);
}

class AnalysisInsights {
  static const _minAmount = 50000; // ignore category swings smaller than this

  static AnalysisResult analyze(AnalysisInput input) {
    final projection = _projection(input);
    return AnalysisResult(
      projection,
      _score(input, projection),
      _insights(input, projection),
    );
  }

  static Projection? _projection(AnalysisInput input) {
    final daysInMonth = DateTime(input.year, input.month + 1, 0).day;
    final isCurrent = input.today.year == input.year && input.today.month == input.month;
    final isFuture = DateTime(input.year, input.month).isAfter(input.today);
    if (isFuture) return null;

    final daysElapsed = isCurrent ? input.today.day : daysInMonth;
    final avgDaily = (input.expense / daysElapsed).round();

    final overall = input.budgets
        .where((b) => b.budget.category == null && b.budget.fundSourceId == null)
        .toList();
    int? limit;
    String? limitLabel;
    if (overall.isNotEmpty) {
      limit = overall.first.budget.amount;
      limitLabel = 'target bulan ini';
    } else if (input.income > 0) {
      limit = input.income;
      limitLabel = 'pemasukan';
    }

    return Projection(
      isCurrentMonth: isCurrent,
      daysInMonth: daysInMonth,
      daysElapsed: daysElapsed,
      spent: input.expense,
      avgDaily: avgDaily,
      projected: isCurrent ? avgDaily * daysInMonth : input.expense,
      limit: limit,
      limitLabel: limitLabel,
    );
  }

  static HealthScore? _score(AnalysisInput input, Projection? projection) {
    final factors = <ScoreFactor>[];

    if (input.income > 0) {
      final rate = (input.income - input.expense) / input.income;
      final points = (rate.clamp(0.0, 0.2) / 0.2 * 40).round();
      final detail = rate < 0
          ? 'Pengeluaran melebihi pemasukan'
          : 'Menyisihkan ${(rate * 100).round()}% pemasukan';
      factors.add(ScoreFactor('Tabungan', points, 40, detail));
    }

    if (input.budgets.isNotEmpty) {
      final safe = input.budgets.where((b) => !b.isOverBudget).length;
      final points = (safe / input.budgets.length * 30).round();
      factors.add(ScoreFactor(
        'Target',
        points,
        30,
        '$safe dari ${input.budgets.length} target aman',
      ));
    }

    if (input.previousExpense > 0 && projection != null) {
      final change = (projection.projected - input.previousExpense) / input.previousExpense;
      final points = (30 * (1 - change.clamp(0.0, 0.3) / 0.3)).round();
      final pct = (change.abs() * 100).round();
      final word = projection.isCurrentMonth ? 'Proyeksi' : 'Pengeluaran';
      final detail = change <= 0
          ? '$word turun $pct% dari bulan lalu'
          : '$word naik $pct% dari bulan lalu';
      factors.add(ScoreFactor('Tren', points, 30, detail));
    }

    if (factors.isEmpty) return null;
    final total = factors.fold<int>(0, (s, f) => s + f.points);
    final max = factors.fold<int>(0, (s, f) => s + f.maxPoints);
    return HealthScore((total / max * 100).round(), factors);
  }

  static List<Insight> _insights(AnalysisInput input, Projection? projection) {
    final insights = <Insight>[];
    if (input.expense == 0 && input.income == 0) return insights;

    final prevName = _monthNames[(input.month + 10) % 12];
    final isCurrent = projection?.isCurrentMonth ?? false;

    // Targets that are over, or close to it
    for (final b in input.budgets.where((b) => b.isOverBudget).take(2)) {
      insights.add(Insight(
        InsightKind.target,
        InsightTone.negative,
        'Target ${b.budget.label} terlampaui ${CurrencyFormatter.formatWithRp(-b.remaining)}',
      ));
    }
    if (isCurrent) {
      for (final b in input.budgets.where((b) => b.isWarning).take(2)) {
        insights.add(Insight(
          InsightKind.target,
          InsightTone.warning,
          'Target ${b.budget.label} sudah ${b.percentage.round()}%, sisa ${projection!.daysLeft} hari',
        ));
      }
    }

    // Savings rate
    if (input.income > 0) {
      final rate = (input.income - input.expense) / input.income;
      if (rate < 0) {
        insights.add(Insight(
          InsightKind.saving,
          InsightTone.negative,
          'Pengeluaran melebihi pemasukan ${CurrencyFormatter.formatWithRp(input.expense - input.income)}',
        ));
      } else if (rate >= 0.2) {
        insights.add(Insight(
          InsightKind.saving,
          InsightTone.positive,
          'Kamu menyisihkan ${(rate * 100).round()}% pemasukan bulan ini',
        ));
      } else {
        insights.add(Insight(
          InsightKind.saving,
          InsightTone.warning,
          'Baru ${(rate * 100).round()}% pemasukan yang tersisa, idealnya minimal 20%',
        ));
      }
    }

    // Biggest category increase vs previous month
    final rising = input.categoryComparison.where((c) {
      final cur = c['current'] as int;
      final prev = c['previous'] as int;
      return prev >= _minAmount && cur - prev >= _minAmount && (cur - prev) / prev >= 0.2;
    }).toList()
      ..sort((a, b) => ((b['current'] as int) - (b['previous'] as int))
          .compareTo((a['current'] as int) - (a['previous'] as int)));
    if (rising.isNotEmpty) {
      final c = rising.first;
      final cur = c['current'] as int;
      final prev = c['previous'] as int;
      insights.add(Insight(
        InsightKind.trendUp,
        InsightTone.warning,
        '${c['category']} ${isCurrent ? 'sudah ' : ''}naik ${((cur - prev) / prev * 100).round()}% '
        '(+${CurrencyFormatter.formatWithRp(cur - prev)}) dari $prevName',
      ));
    }

    // Biggest drop: only meaningful once the month is complete
    if (!isCurrent) {
      final falling = input.categoryComparison.where((c) {
        final cur = c['current'] as int;
        final prev = c['previous'] as int;
        return prev >= _minAmount && prev - cur >= _minAmount && (prev - cur) / prev >= 0.2;
      }).toList()
        ..sort((a, b) => ((a['current'] as int) - (a['previous'] as int))
            .compareTo((b['current'] as int) - (b['previous'] as int)));
      if (falling.isNotEmpty) {
        final c = falling.first;
        final cur = c['current'] as int;
        final prev = c['previous'] as int;
        insights.add(Insight(
          InsightKind.trendDown,
          InsightTone.positive,
          '${c['category']} turun ${((prev - cur) / prev * 100).round()}% dari $prevName',
        ));
      }
    }

    // Weekend vs weekday, averaged per day that actually occurred
    if (projection != null && input.expense > 0) {
      var weekendDays = 0;
      var weekDays = 0;
      for (var d = 1; d <= projection.daysElapsed; d++) {
        final wd = DateTime(input.year, input.month, d).weekday % 7;
        if (wd == 0 || wd == 6) {
          weekendDays++;
        } else {
          weekDays++;
        }
      }
      final weekendTotal = (input.weekdayTotals[0] ?? 0) + (input.weekdayTotals[6] ?? 0);
      final weekTotal = input.weekdayTotals.entries
          .where((e) => e.key != 0 && e.key != 6)
          .fold<int>(0, (s, e) => s + e.value);
      if (weekendDays > 0 && weekDays > 0 && weekTotal > 0) {
        final ratio = (weekendTotal / weekendDays) / (weekTotal / weekDays);
        if (ratio >= 1.5) {
          insights.add(Insight(
            InsightKind.weekend,
            InsightTone.neutral,
            'Belanja per hari di akhir pekan ${ratio.toStringAsFixed(1).replaceAll('.', ',')}x lebih besar dari hari kerja',
          ));
        }
      }
    }

    // One transaction dominating the month
    if (input.topExpenses.isNotEmpty && input.expense > 0) {
      final top = input.topExpenses.first;
      final share = top.amount / input.expense;
      if (share >= 0.25 && input.topExpenses.length > 1) {
        insights.add(Insight(
          InsightKind.bigTransaction,
          InsightTone.neutral,
          '"${top.title}" menyumbang ${(share * 100).round()}% dari pengeluaran bulan ini',
        ));
      }
    }

    // Top category share
    if (input.categoryComparison.isNotEmpty && input.expense > 0) {
      final top = input.categoryComparison.first;
      final share = (top['current'] as int) / input.expense;
      if (share >= 0.4) {
        insights.add(Insight(
          InsightKind.topCategory,
          InsightTone.neutral,
          '${top['category']} mengambil ${(share * 100).round()}% dari total pengeluaran',
        ));
      }
    }

    // No-spend days
    if (projection != null) {
      final noSpend = List.generate(projection.daysElapsed, (i) => i + 1)
          .where((d) => (input.dailyExpense[d] ?? 0) == 0)
          .length;
      if (noSpend >= 3) {
        insights.add(Insight(
          InsightKind.noSpend,
          InsightTone.positive,
          '$noSpend hari tanpa pengeluaran bulan ini',
        ));
      }
    }

    return insights;
  }
}
