import 'package:flutter_test/flutter_test.dart';
import 'package:cash_flow_app/features/analysis/analysis_insights.dart';
import 'package:cash_flow_app/models/budget.dart';
import 'package:cash_flow_app/models/transaction.dart';

Budget _budget(int amount, {String? category}) => Budget(
      id: 'b$amount',
      category: category,
      amount: amount,
      month: 10,
      year: 2026,
      createdAt: DateTime(2026, 10, 1),
    );

Transaction _tx(String title, int amount) => Transaction(
      id: title,
      title: title,
      amount: amount,
      category: 'Belanja',
      dateTime: DateTime(2026, 10, 3),
    );

AnalysisInput _input({
  int income = 10000000,
  int expense = 3000000,
  int previousExpense = 6000000,
  List<BudgetProgress> budgets = const [],
  List<Map<String, dynamic>> comparison = const [],
  Map<int, int> daily = const {},
  List<Transaction> top = const [],
}) =>
    AnalysisInput(
      year: 2026,
      month: 10,
      today: DateTime(2026, 10, 10),
      income: income,
      expense: expense,
      previousExpense: previousExpense,
      categoryComparison: comparison,
      weekdayTotals: const {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0},
      dailyExpense: daily,
      budgets: budgets,
      topExpenses: top,
    );

void main() {
  test('projection uses average daily pace and safe daily limit', () {
    final r = AnalysisInsights.analyze(_input());
    final p = r.projection!;
    expect(p.daysElapsed, 10);
    expect(p.avgDaily, 300000);
    expect(p.projected, 9300000); // 31 days
    expect(p.limitLabel, 'pemasukan');
    expect(p.daysLeft, 22);
    expect(p.safeDaily, 318181); // (10jt - 3jt) / 22
    expect(p.willExceed, isFalse);
  });

  test('overall target takes priority over income as the limit', () {
    final r = AnalysisInsights.analyze(_input(budgets: [
      BudgetProgress(budget: _budget(5000000), spent: 3000000),
    ]));
    expect(r.projection!.limit, 5000000);
    expect(r.projection!.willExceed, isTrue);
  });

  test('health score combines saving, target and trend', () {
    final r = AnalysisInsights.analyze(_input(budgets: [
      BudgetProgress(budget: _budget(1000000, category: 'Makan'), spent: 500000),
      BudgetProgress(budget: _budget(200000, category: 'Hiburan'), spent: 400000),
    ]));
    final s = r.score!;
    // saving 70% -> 40/40, targets 1 of 2 safe -> 15/30, projection 9.3jt vs 6jt (+55%) -> 0/30
    expect(s.factors.map((f) => f.points).toList(), [40, 15, 0]);
    expect(s.score, 55);
    expect(s.label, 'Waspada');
  });

  test('no data gives no score and no insights', () {
    final r = AnalysisInsights.analyze(_input(income: 0, expense: 0, previousExpense: 0));
    expect(r.score, isNull);
    expect(r.insights, isEmpty);
  });

  test('insights cover overspending, category rise, big transaction and no-spend days', () {
    final r = AnalysisInsights.analyze(_input(
      income: 2000000,
      expense: 2500000,
      budgets: [BudgetProgress(budget: _budget(300000, category: 'Hiburan'), spent: 450000)],
      comparison: [
        {'category': 'Belanja', 'current': 1500000, 'previous': 1000000},
        {'category': 'Hiburan', 'current': 450000, 'previous': 400000},
      ],
      daily: {1: 1000000, 2: 1500000},
      top: [_tx('Kulkas', 1000000), _tx('Makan', 100000)],
    ));
    final texts = r.insights.map((i) => i.text).toList();
    expect(texts, contains('Target Hiburan terlampaui Rp 150.000'));
    expect(texts, contains('Pengeluaran melebihi pemasukan Rp 500.000'));
    expect(texts, contains('Belanja sudah naik 50% (+Rp 500.000) dari September'));
    expect(texts, contains('"Kulkas" menyumbang 40% dari pengeluaran bulan ini'));
    expect(texts, contains('Belanja mengambil 60% dari total pengeluaran'));
    expect(texts, contains('8 hari tanpa pengeluaran bulan ini'));
  });
}
