import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/transaction_repository.dart';
import '../../../core/storage/budget_repository.dart';
import '../../../core/utils/currency_formatter.dart';
import '../analysis_insights.dart';
import '../../../models/transaction.dart';
import '../../transactions/screens/transaction_list_screen.dart';
import '../../transactions/screens/edit_transaction_screen.dart';
import '../../categories/screens/categories_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => AnalysisScreenState();
}

class AnalysisScreenState extends State<AnalysisScreen> {
  DateTime _currentMonth = DateTime.now();
  late DateTime _previousMonth;

  List<Map<String, dynamic>> _categoryComparison = [];
  Map<int, int> _weekdayTotals = {};
  List<Transaction> _topExpenses = [];
  AnalysisResult? _analysis;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _previousMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    loadData();
  }

  Future<void> loadData() async {
    setState(() => _isLoading = true);

    final currentExp = await TransactionRepository.instance.getTotalExpensesByMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final prevExp = await TransactionRepository.instance.getTotalExpensesByMonth(
      _previousMonth.year,
      _previousMonth.month,
    );
    final comparison = await TransactionRepository.instance.getCategoryComparisonBetweenMonths(
      _currentMonth.year,
      _currentMonth.month,
      _previousMonth.year,
      _previousMonth.month,
    );
    final weekday = await TransactionRepository.instance.getTotalsByWeekdayForMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final topExp = await TransactionRepository.instance.getTopExpensesForMonth(
      _currentMonth.year,
      _currentMonth.month,
      limit: 5,
    );
    final income = await TransactionRepository.instance.getTotalIncomeByMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final daily = await TransactionRepository.instance.getDailyTotalsForMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final budgets = await BudgetRepository.instance.getBudgetProgress(
      _currentMonth.year,
      _currentMonth.month,
    );

    final analysis = AnalysisInsights.analyze(AnalysisInput(
      year: _currentMonth.year,
      month: _currentMonth.month,
      today: DateTime.now(),
      income: income,
      expense: currentExp,
      previousExpense: prevExp,
      categoryComparison: comparison,
      weekdayTotals: weekday,
      dailyExpense: daily,
      budgets: budgets,
      topExpenses: topExp,
    ));

    if (mounted) {
      setState(() {
        _categoryComparison = comparison;
        _weekdayTotals = weekday;
        _topExpenses = topExp;
        _analysis = analysis;
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
      _previousMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    loadData();
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[date.month - 1];
  }

  String _getMonthAbbr(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        children: [
                          _buildScoreCard(),
                          const SizedBox(height: 14),
                          _buildProjectionCard(),
                          _buildInsights(),
                          const SizedBox(height: 18),
                          _buildCategoryComparison(context),
                          const SizedBox(height: 18),
                          _buildWeekdayChart(),
                          const SizedBox(height: 18),
                          _buildTopExpenses(context),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ANALISIS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.7,
                  color: AppColors.neutral700,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _changeMonth(-1),
                    child: Icon(Icons.chevron_left, size: 20, color: AppColors.neutral500),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _changeMonth(1),
                    child: Icon(Icons.chevron_right, size: 20, color: AppColors.neutral400),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_getMonthName(_currentMonth)} vs ${_getMonthName(_previousMonth)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _toneColor(InsightTone tone) {
    switch (tone) {
      case InsightTone.positive:
        return AppColors.accent;
      case InsightTone.warning:
        return AppColors.accent2;
      case InsightTone.negative:
        return AppColors.negative;
      case InsightTone.neutral:
        return AppColors.neutral600;
    }
  }

  IconData _insightIcon(InsightKind kind) {
    switch (kind) {
      case InsightKind.target:
        return Icons.track_changes;
      case InsightKind.saving:
        return Icons.savings_outlined;
      case InsightKind.trendUp:
        return Icons.trending_up;
      case InsightKind.trendDown:
        return Icons.trending_down;
      case InsightKind.weekend:
        return Icons.weekend_outlined;
      case InsightKind.bigTransaction:
        return Icons.receipt_long_outlined;
      case InsightKind.noSpend:
        return Icons.celebration_outlined;
      case InsightKind.topCategory:
        return Icons.pie_chart_outline;
    }
  }

  Widget _buildScoreCard() {
    final score = _analysis?.score;

    if (score == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skor Kesehatan Kas',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Belum cukup data. Catat pemasukan, pengeluaran, atau buat target untuk melihat skor.',
              style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.neutral600),
            ),
          ],
        ),
      );
    }

    final color = _toneColor(score.tone);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: score.score / 100,
                        strokeWidth: 7,
                        backgroundColor: AppColors.neutral200,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    Text(
                      '${score.score}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skor Kesehatan Kas',
                      style: TextStyle(fontSize: 12, color: AppColors.neutral600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      score.label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'dari 100, ${_getMonthName(_currentMonth)} ${_currentMonth.year}',
                      style: TextStyle(fontSize: 11, color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...score.factors.map(_buildScoreFactor),
        ],
      ),
    );
  }

  Widget _buildScoreFactor(ScoreFactor factor) {
    final ratio = factor.points / factor.maxPoints;
    final color = ratio >= 0.75
        ? AppColors.accent
        : ratio >= 0.5
            ? AppColors.accent2
            : AppColors.negative;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              factor.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor: AppColors.neutral200,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  factor.detail,
                  style: TextStyle(fontSize: 11, color: AppColors.neutral600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${factor.points}/${factor.maxPoints}',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.neutral600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionCard() {
    final p = _analysis?.projection;
    if (p == null || p.spent == 0) return const SizedBox.shrink();

    final exceeded = p.remaining != null && p.remaining! < 0;
    final isBad = exceeded || p.willExceed;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.isCurrentMonth ? 'Proyeksi akhir bulan' : 'Ringkasan bulan',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildProjectionStat('Rata-rata/hari', p.avgDaily),
              _buildProjectionStat(
                p.isCurrentMonth ? 'Perkiraan total' : 'Total keluar',
                p.projected,
                color: p.willExceed ? AppColors.negative : null,
              ),
              if (p.limit != null)
                _buildProjectionStat(
                  p.limitLabel == 'pemasukan' ? 'Pemasukan' : 'Target',
                  p.limit!,
                ),
            ],
          ),
          if (p.isCurrentMonth && p.limit != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isBad ? AppColors.negative : AppColors.accent).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isBad ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    size: 20,
                    color: isBad ? AppColors.negative : AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      exceeded
                          ? 'Sudah melewati ${p.limitLabel} ${CurrencyFormatter.formatWithRp(-p.remaining!)}. '
                              'Coba tahan pengeluaran ${p.daysLeft} hari ke depan.'
                          : 'Aman belanja ${CurrencyFormatter.formatWithRp(p.safeDaily!)}/hari '
                              'selama ${p.daysLeft} hari lagi'
                              '${p.willExceed ? '. Dengan pola sekarang, ${p.limitLabel} akan terlampaui.' : '.'}',
                      style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectionStat(String label, int amount, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.neutral600)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.formatWithRp(amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color ?? AppColors.text,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    final insights = _analysis?.insights ?? [];

    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insight bulan ini',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (insights.isEmpty)
            Text(
              'Belum ada data untuk dianalisis.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral600,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...insights.map((insight) {
              final color = _toneColor(insight.tone);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_insightIcon(insight.kind), size: 18, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight.text,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCategoryComparison(BuildContext context) {
    final topCategories = _categoryComparison.take(4).toList();

    // Find max for scaling
    int maxValue = 1;
    for (final cat in topCategories) {
      final current = cat['current'] as int;
      final prev = cat['previous'] as int;
      if (current > maxValue) maxValue = current;
      if (prev > maxValue) maxValue = prev;
    }

    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bulan ke bulan, per kategori',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                ),
                child: Text(
                  'Rincian ›',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (topCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Belum ada data kategori',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else ...[
            ...topCategories.map((cat) {
              final current = cat['current'] as int;
              final prev = cat['previous'] as int;
              final change = (cat['changePercent'] as num).toDouble();
              final changeStr = change >= 0 ? '+${change.toInt()}%' : '${change.toInt()}%';

              return _buildComparisonRow(
                cat['category'] as String,
                current / maxValue * 100,
                prev / maxValue * 100,
                changeStr,
                isPositive: change <= 0,
                context: context,
              );
            }),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  _buildLegendItem(_getMonthAbbr(_currentMonth), AppColors.neutral800, null),
                  const SizedBox(width: 14),
                  _buildLegendItem(_getMonthAbbr(_previousMonth), Colors.transparent, AppColors.neutral500),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, double currentWidth, double prevWidth, String change, {bool isPositive = true, required BuildContext context}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TransactionListScreen(initialFilter: label)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(
                label,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 22,
                child: CustomPaint(
                  painter: _ComparisonBarPainter(currentWidth.clamp(0, 100), prevWidth.clamp(0, 100)),
                ),
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                change,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isPositive ? AppColors.neutral700 : AppColors.accent800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color fill, Color? border) {
    return Row(
      children: [
        Container(
          width: 13,
          height: 7,
          decoration: BoxDecoration(
            color: fill,
            border: border != null ? Border.all(color: border) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.neutral700,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayChart() {
    // Calculate totals
    final weekdayTotal = _weekdayTotals[1]! + _weekdayTotals[2]! + _weekdayTotals[3]! + _weekdayTotals[4]! + _weekdayTotals[5]!;
    final weekendTotal = _weekdayTotals[0]! + _weekdayTotals[6]!;
    final total = weekdayTotal + weekendTotal;

    // Find max for scaling
    int maxValue = 1;
    for (final v in _weekdayTotals.values) {
      if (v > maxValue) maxValue = v;
    }

    // Day order: Senin(1), Selasa(2), Rabu(3), Kamis(4), Jumat(5), Sabtu(6), Minggu(0)
    final dayOrder = [1, 2, 3, 4, 5, 6, 0];
    final dayLabels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hari kerja vs akhir pekan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Belum ada data',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 96,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: dayOrder.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final dayIdx = entry.value;
                  final value = _weekdayTotals[dayIdx] ?? 0;
                  final heightFactor = maxValue > 0 ? (value / maxValue).clamp(0.05, 1.0) : 0.05;
                  final isWeekend = idx >= 5; // Sabtu, Minggu

                  return _buildDayBar(heightFactor, isWeekend);
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: dayLabels.map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.neutral700,
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),
            if (total > 0)
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: AppColors.text,
                  ),
                  children: [
                    const TextSpan(text: 'Akhir pekan menyerap '),
                    TextSpan(
                      text: '${(weekendTotal / total * 100).toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' pengeluaran. '),
                    TextSpan(
                      text: 'Rp ${_formatAmount(weekendTotal)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' di akhir pekan vs '),
                    TextSpan(
                      text: 'Rp ${_formatAmount(weekdayTotal)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' di hari kerja.'),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayBar(double heightFactor, bool isWeekend) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: FractionallySizedBox(
          heightFactor: heightFactor,
          child: Container(
            decoration: BoxDecoration(
              color: isWeekend ? AppColors.accent200 : AppColors.neutral300,
              border: Border(
                top: BorderSide(
                  color: isWeekend ? AppColors.accent600 : AppColors.neutral700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopExpenses(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lima terbesar di ${_getMonthName(_currentMonth)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_topExpenses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Belum ada pengeluaran',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ..._topExpenses.map((tx) => _buildExpenseRow(tx, context)),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(Transaction tx, BuildContext context) {
    final day = tx.dateTime.day;
    final monthAbbr = _getMonthAbbr(tx.dateTime);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditTransactionScreen(transaction: tx),
          ),
        );
        if (result == true) {
          loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: AppColors.text),
                  children: [
                    TextSpan(text: tx.title),
                    TextSpan(
                      text: ' · $day $monthAbbr',
                      style: TextStyle(color: AppColors.neutral700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatAmount(tx.amount),
              style: const TextStyle(
                fontSize: 13,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

class _ComparisonBarPainter extends CustomPainter {
  final double currentWidth;
  final double prevWidth;

  _ComparisonBarPainter(this.currentWidth, this.prevWidth);

  @override
  void paint(Canvas canvas, Size size) {
    // Current month bar (top)
    if (currentWidth > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 1, currentWidth, 8),
        Paint()..color = AppColors.neutral800,
      );
    }

    // Previous month bar (bottom, outline only)
    if (prevWidth > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 12, prevWidth, 8),
        Paint()
          ..color = AppColors.neutral500
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
