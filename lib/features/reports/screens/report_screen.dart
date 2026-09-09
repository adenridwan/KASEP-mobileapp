import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/transaction_repository.dart';
import '../../transactions/screens/transaction_list_screen.dart';
import '../../export/screens/export_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _selectedMonth = DateTime.now();
  int _totalIncome = 0;
  int _totalExpenses = 0;
  int _transactionCount = 0;
  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final income = await TransactionRepository.instance.getTotalIncomeByMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final expenses = await TransactionRepository.instance.getTotalExpensesByMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final count = await TransactionRepository.instance.getCountByMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final weekly = await TransactionRepository.instance.getWeeklyTotalsForMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    if (mounted) {
      setState(() {
        _totalIncome = income;
        _totalExpenses = expenses;
        _transactionCount = count;
        _weeklyData = weekly;
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
    _loadData();
  }

  int get _netBalance => _totalIncome - _totalExpenses;

  String get _formattedMonth {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  int get _daysInMonth => DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
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
                          _buildSummaryCards(context),
                          const SizedBox(height: 20),
                          _buildLegend(),
                          const SizedBox(height: 12),
                          _buildBarChart(),
                          const SizedBox(height: 20),
                          _buildWeeklyTable(context),
                          const SizedBox(height: 18),
                          if (_netBalance != 0) _buildCarryOverCallout(),
                          if (_netBalance != 0) const SizedBox(height: 16),
                          _buildViewAllButton(context),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                'LAPORAN',
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
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExportScreen()),
                    ),
                    child: Text(
                      'Ekspor ›',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formattedMonth,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _changeMonth(-1),
                    child: Icon(Icons.chevron_left, size: 24, color: AppColors.neutral500),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _changeMonth(1),
                    child: Icon(Icons.chevron_right, size: 24, color: AppColors.neutral400),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '1–$_daysInMonth ${_formattedMonth.split(' ')[0]} · $_transactionCount catatan',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.neutral700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final netSign = _netBalance >= 0 ? '+' : '';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _buildSummaryCard('MASUK', _formatAmount(_totalIncome), isActive: true, context: context),
          Container(width: 1, color: AppColors.divider),
          _buildSummaryCard('KELUAR', _formatAmount(_totalExpenses), context: context),
          Container(width: 1, color: AppColors.divider),
          _buildSummaryCard('BERSIH', '$netSign${_formatAmount(_netBalance)}', isNet: true, context: context),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, {bool isActive = false, bool isNet = false, required BuildContext context}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TransactionListScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          color: isActive ? AppColors.accent100 : Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: isActive ? AppColors.accent700 : AppColors.neutral700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isNet ? (_netBalance >= 0 ? AppColors.accent700 : Colors.red) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem('masuk', AppColors.accent200, AppColors.accent600),
        const SizedBox(width: 16),
        _buildLegendItem('keluar', AppColors.neutral800, null),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color fill, Color? border) {
    return Row(
      children: [
        Container(
          width: 13,
          height: 9,
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

  Widget _buildBarChart() {
    if (_weeklyData.isEmpty || (_totalIncome == 0 && _totalExpenses == 0)) {
      return SizedBox(
        height: 130,
        child: Center(
          child: Text(
            'Belum ada data',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.neutral600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: CustomPaint(
        size: const Size(double.infinity, 130),
        painter: _WeeklyBarChartPainter(_weeklyData),
      ),
    );
  }

  Widget _buildWeeklyTable(BuildContext context) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    final monthAbbr = months[_selectedMonth.month - 1];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.text)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'PEKAN',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: AppColors.neutral700,
                  ),
                ),
              ),
              SizedBox(
                width: 86,
                child: Text(
                  'MASUK',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: AppColors.neutral700,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  'KELUAR',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: AppColors.neutral700,
                  ),
                ),
              ),
            ],
          ),
        ),
        ..._weeklyData.map((week) => _buildWeekRow(
          '${week['startDay']}–${week['endDay']} $monthAbbr',
          week['income'] as int,
          week['expense'] as int,
          context: context,
        )),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.text)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 86,
                child: Text(
                  _formatAmount(_totalIncome),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  _formatAmount(_totalExpenses),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekRow(String period, int income, int expense, {required BuildContext context}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TransactionListScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                period,
                style: const TextStyle(
                  fontSize: 13,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            SizedBox(
              width: 86,
              child: Text(
                income > 0 ? _formatAmount(income) : '—',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: income == 0 ? AppColors.neutral500 : null,
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                expense > 0 ? _formatAmount(expense) : '—',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: expense == 0 ? AppColors.neutral500 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarryOverCallout() {
    final sign = _netBalance >= 0 ? '' : '-';
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final nextMonthName = months[nextMonth.month - 1];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 2,
            height: 40,
            color: _netBalance >= 0 ? AppColors.accent : AppColors.accent800,
            margin: const EdgeInsets.only(right: 14),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: AppColors.text,
                ),
                children: [
                  TextSpan(text: _netBalance >= 0 ? 'Sisa bulan ini: ' : 'Defisit bulan ini: '),
                  TextSpan(
                    text: '$sign Rp ${_formatAmount(_netBalance.abs())}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: _netBalance >= 0 ? AppColors.accent700 : Colors.red,
                    ),
                  ),
                  TextSpan(text: ' — ${_netBalance >= 0 ? 'dibawa ke' : 'perlu ditutup di'} $nextMonthName.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TransactionListScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.accent),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                'Lihat semua catatan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Text(
                '›',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    return amount.abs().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

class _WeeklyBarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> weeklyData;

  _WeeklyBarChartPainter(this.weeklyData);

  @override
  void paint(Canvas canvas, Size size) {
    final baseLine = size.height - 18;

    // Base line
    canvas.drawLine(
      Offset(0, baseLine),
      Offset(size.width, baseLine),
      Paint()..color = AppColors.divider,
    );

    // Find max value for scaling
    int maxValue = 0;
    for (final week in weeklyData) {
      final income = week['income'] as int;
      final expense = week['expense'] as int;
      if (income > maxValue) maxValue = income;
      if (expense > maxValue) maxValue = expense;
    }

    if (maxValue == 0) return;

    final maxBarHeight = baseLine - 10;

    // Week labels
    final labelPaint = TextPainter(textDirection: TextDirection.ltr);
    final weekWidth = size.width / weeklyData.length;

    for (var i = 0; i < weeklyData.length; i++) {
      labelPaint.text = TextSpan(
        text: 'pekan ${i + 1}',
        style: TextStyle(
          fontSize: 10,
          color: AppColors.neutral700,
        ),
      );
      labelPaint.layout();
      labelPaint.paint(
        canvas,
        Offset(weekWidth * i + (weekWidth - labelPaint.width) / 2, size.height - 14),
      );
    }

    // Bars
    const barWidth = 26.0;
    const gap = 4.0;

    for (var i = 0; i < weeklyData.length; i++) {
      final week = weeklyData[i];
      final income = week['income'] as int;
      final expense = week['expense'] as int;

      final incomeHeight = income / maxValue * maxBarHeight;
      final expenseHeight = expense / maxValue * maxBarHeight;

      final startX = weekWidth * i + (weekWidth - (barWidth * 2 + gap)) / 2;

      // Income bar
      if (income > 0) {
        _drawBar(canvas, startX, baseLine, barWidth, incomeHeight, AppColors.accent200, AppColors.accent600);
      }

      // Expense bar
      if (expense > 0) {
        _drawBar(canvas, startX + barWidth + gap, baseLine, barWidth, expenseHeight, AppColors.neutral800, null);
      }
    }
  }

  void _drawBar(Canvas canvas, double x, double baseLine, double width, double height, Color fill, Color? border) {
    if (height <= 0) return;
    final rect = Rect.fromLTWH(x, baseLine - height, width, height);
    canvas.drawRect(rect, Paint()..color = fill);
    if (border != null) {
      canvas.drawRect(rect, Paint()..color = border..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.weeklyData != weeklyData;
  }
}
