import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/storage/transaction_repository.dart';
import '../../../models/transaction.dart';
import '../../transactions/screens/transaction_list_screen.dart';
import '../../transactions/screens/add_transaction_screen.dart';
import '../../transactions/screens/edit_transaction_screen.dart';
import '../../categories/screens/categories_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/balance_chart.dart';
import '../widgets/category_bar.dart';
import '../widgets/transaction_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  DateTime _selectedMonth = DateTime.now();
  List<Transaction> _todayTransactions = [];
  List<Transaction> _monthTransactions = [];
  int _totalIncome = 0;
  int _totalExpenses = 0;
  Map<String, int> _categoryTotals = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => _isLoading = true);

    final today = DateTime.now();
    final todayTransactions = await TransactionRepository.instance.getByDate(
      today,
    );
    final monthTransactions = await TransactionRepository.instance.getByMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final totalIncome = await TransactionRepository.instance
        .getTotalIncomeByMonth(_selectedMonth.year, _selectedMonth.month);
    final totalExpenses = await TransactionRepository.instance
        .getTotalExpensesByMonth(_selectedMonth.year, _selectedMonth.month);
    final categoryTotals = await TransactionRepository.instance
        .getTotalByCategoryForMonth(_selectedMonth.year, _selectedMonth.month);

    if (mounted) {
      setState(() {
        _todayTransactions = todayTransactions;
        _monthTransactions = monthTransactions;
        _totalIncome = totalIncome;
        _totalExpenses = totalExpenses;
        _categoryTotals = categoryTotals;
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
    loadData();
  }

  int get _netBalance => _totalIncome - _totalExpenses;

  String get _formattedMonth {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
                    child: Column(
                      children: [
                        _buildNetSummary(),
                        const SizedBox(height: 16),
                        _buildIncomeExpense(context),
                        const SizedBox(height: 24),
                        _buildBalanceChart(),
                        const SizedBox(height: 22),
                        _buildCategorySection(context),
                        const SizedBox(height: 22),
                        _buildTodayTransactions(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'KASEP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.neutral700,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _changeMonth(-1),
                child: Icon(
                  Icons.chevron_left,
                  size: 18,
                  color: AppColors.neutral500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formattedMonth,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _changeMonth(1),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.neutral400,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: AppColors.neutral700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetSummary() {
    final sign = _netBalance >= 0 ? '+' : '-';
    final displayAmount = _netBalance.abs();

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B5C4D), Color(0xFF147D68), Color(0xFF3AA58B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, .58, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BERSIH BULAN INI',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          _isLoading
              ? const CircularProgressIndicator()
              : Text(
                  '$sign${_formatCurrency(displayAmount)}',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.2,
                    color: Colors.white,
                  ),
                ),
          const SizedBox(height: 8),
          Text(
            '${_monthTransactions.length} catatan bulan ini',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpense(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToAddTransaction(context, isIncome: true),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEDF8F4), Color(0xFFD8F0E8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.south_west_rounded,
                          size: 14,
                          color: AppColors.accent700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pemasukan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.neutral700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatCurrency(_totalIncome),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToAddTransaction(context, isIncome: false),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5F3FA), Color(0xFFEBE7F5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.lavender.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.neutral700.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.north_east_rounded,
                          size: 14,
                          color: AppColors.neutral700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pengeluaran',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.neutral700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatCurrency(_totalExpenses),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceChart() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SectionHeader(
            title: 'Saldo berjalan',
            subtitle: 'harian, $_formattedMonth',
          ),
          const SizedBox(height: 10),
          BalanceChart(year: _selectedMonth.year, month: _selectedMonth.month),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context) {
    // Get top 3 categories
    final sortedCategories = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(3).toList();
    final maxAmount = topCategories.isNotEmpty ? topCategories.first.value : 1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SectionHeader(
            title: 'Pengeluaran Teratas',
            actionText: 'Semua kategori ›',
            onActionTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ),
          ),
          const SizedBox(height: 6),
          if (topCategories.isEmpty)
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
            ...topCategories.map(
              (entry) => CategoryBar(
                category: entry.key,
                amount: entry.value,
                barWidth: (entry.value / maxAmount * 100)
                    .clamp(10, 100)
                    .toDouble(),
                onTap: () =>
                    _navigateToTransactions(context, filter: entry.key),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTodayTransactions(BuildContext context) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final today = DateTime.now();
    final todayLabel = '${today.day} ${months[today.month - 1]}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SectionHeader(
            title: 'Hari ini · $todayLabel',
            actionText: 'Semua catatan ›',
            onActionTap: () => _navigateToTransactions(context),
          ),
          const SizedBox(height: 6),
          if (_todayTransactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Belum ada catatan hari ini',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ..._todayTransactions.map(
              (tx) => TransactionRow(
                transaction: tx,
                onTap: () => _navigateToEdit(context, tx),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToTransactions(BuildContext context, {String? filter}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionListScreen(initialFilter: filter),
      ),
    );
    if (result == true) {
      loadData();
    }
  }

  void _navigateToAddTransaction(
    BuildContext context, {
    required bool isIncome,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(isIncome: isIncome),
      ),
    );
    if (result == true) {
      loadData();
    }
  }

  void _navigateToEdit(BuildContext context, Transaction tx) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditTransactionScreen(transaction: tx)),
    );
    if (result == true) {
      loadData();
    }
  }
}
