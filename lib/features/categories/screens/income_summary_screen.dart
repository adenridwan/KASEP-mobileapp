import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/transaction_repository.dart';
import '../../../models/category_summary.dart';
import '../../transactions/screens/transaction_list_screen.dart';

class IncomeSummaryScreen extends StatefulWidget {
  const IncomeSummaryScreen({super.key});

  @override
  State<IncomeSummaryScreen> createState() => _IncomeSummaryScreenState();
}

class _IncomeSummaryScreenState extends State<IncomeSummaryScreen> {
  DateTime _selectedMonth = DateTime.now();
  List<CategorySummary> _categories = [];
  int _totalIncome = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final summaries = await TransactionRepository.instance.getIncomeCategorySummariesForMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    final total = summaries.fold<int>(0, (sum, item) => sum + (item['total'] as int));

    final categories = summaries.map((item) {
      final amount = item['total'] as int;
      final percentage = total > 0 ? (amount / total * 100) : 0.0;
      return CategorySummary(
        name: item['category'] as String,
        totalAmount: amount,
        transactionCount: item['count'] as int,
        percentage: percentage,
      );
    }).toList();

    if (mounted) {
      setState(() {
        _categories = categories;
        _totalIncome = total;
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

  String get _formattedMonth {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

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
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _categories.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: [
                              _buildStackedBar(),
                              const SizedBox(height: 6),
                              Text(
                                _buildInsightText(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.neutral700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._categories.asMap().entries.map((entry) =>
                                  _buildCategoryRow(context, entry.key + 1, entry.value)),
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
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  '< Kembali',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.accent,
                  ),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _changeMonth(-1),
                    child: Icon(Icons.chevron_left, size: 20, color: AppColors.neutral500),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formattedMonth,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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
          const SizedBox(height: 12),
          const Text(
            'Dari mana uang datang',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_formattedMonth - ${_formatAmount(_totalIncome)} masuk dari ${_categories.length} kategori',
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: AppColors.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada pemasukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Catat pemasukan pertama Anda',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  String _buildInsightText() {
    if (_categories.isEmpty) return '';
    final top = _categories.first;
    final pct = top.percentage.toInt();
    return '${top.name} menyumbang $pct% dari total pemasukan bulan ini.';
  }

  Widget _buildStackedBar() {
    if (_categories.isEmpty) {
      return Container(
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.neutral200,
          border: Border.all(color: AppColors.neutral300),
        ),
      );
    }

    final colors = [
      AppColors.accent700,
      AppColors.accent600,
      AppColors.accent500,
      AppColors.accent400,
      AppColors.accent300,
      AppColors.accent200,
      AppColors.accent100,
    ];

    return SizedBox(
      height: 26,
      child: Row(
        children: _categories.asMap().entries.map((entry) {
          final idx = entry.key;
          final cat = entry.value;
          final color = colors[idx % colors.length];
          final isLast = idx == _categories.length - 1;

          return Expanded(
            flex: cat.percentage.toInt().clamp(1, 100),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                border: isLast && idx >= colors.length - 1
                    ? Border.all(color: AppColors.neutral300)
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context, int index, CategorySummary cat) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TransactionListScreen(initialFilter: cat.name)),
        );
        if (result == true) {
          _loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 26,
              child: Text(
                index.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: AppColors.accent700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: const TextStyle(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${cat.transactionCount} catatan · ${_formatAmount(cat.averageAmount)}/rata',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.neutral700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatAmount(cat.totalAmount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '${cat.percentage.toInt()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: AppColors.neutral700,
                  ),
                ),
              ],
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
