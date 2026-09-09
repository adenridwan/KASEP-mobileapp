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
import '../../auth/screens/auth_router.dart';
import '../widgets/balance_chart.dart';
import '../widgets/category_bar.dart';
import '../widgets/transaction_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final today = DateTime.now();
    final todayTransactions = await TransactionRepository.instance.getByDate(today);
    final monthTransactions = await TransactionRepository.instance.getByMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final totalIncome = await TransactionRepository.instance.getTotalIncomeByMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final totalExpenses = await TransactionRepository.instance.getTotalExpensesByMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final categoryTotals = await TransactionRepository.instance.getTotalByCategoryForMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );

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
                        const SizedBox(height: 18),
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
            Positioned(
              right: 22,
              bottom: 20,
              child: _buildFAB(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'KASEP',
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
              const SizedBox(width: 14),
              Text(
                _formattedMonth,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => _changeMonth(1),
                child: Icon(Icons.chevron_right, size: 20, color: AppColors.neutral400),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: AppColors.neutral700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _showLogoutDialog,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Icon(
                    Icons.logout,
                    size: 18,
                    color: AppColors.accent800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Catatan tetap tersimpan terenkripsi di ponsel. '
          'Anda perlu sidik jari atau PIN untuk masuk kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthRouter()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.accent800),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _buildNetSummary() {
    final sign = _netBalance >= 0 ? '+' : '-';
    final displayAmount = _netBalance.abs();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.divider),
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        children: [
          Text(
            'BERSIH BULAN INI',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 6),
          _isLoading
              ? const CircularProgressIndicator()
              : Text(
                  '$sign${_formatCurrency(displayAmount)}',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.2,
                    color: _netBalance >= 0 ? AppColors.accent700 : Colors.red,
                  ),
                ),
          const SizedBox(height: 8),
          Text(
            '${_monthTransactions.length} catatan',
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

  Widget _buildIncomeExpense(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToAddTransaction(context, isIncome: true),
            child: Container(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_upward, size: 13, color: AppColors.accent),
                      const SizedBox(width: 7),
                      Text(
                        'KAS MASUK',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.8,
                          color: AppColors.neutral700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatCurrency(_totalIncome),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(width: 1, height: 50, color: AppColors.divider),
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToAddTransaction(context, isIncome: false),
            child: Container(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_downward, size: 13, color: AppColors.neutral800),
                      const SizedBox(width: 7),
                      Text(
                        'KAS KELUAR',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.8,
                          color: AppColors.neutral700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatCurrency(_totalExpenses),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          SectionHeader(
            title: 'Saldo berjalan',
            subtitle: 'harian, $_formattedMonth',
          ),
          const SizedBox(height: 10),
          BalanceChart(
            year: _selectedMonth.year,
            month: _selectedMonth.month,
          ),
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
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          SectionHeader(
            title: 'Ke mana perginya',
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
            ...topCategories.map((entry) => CategoryBar(
              category: entry.key,
              amount: entry.value,
              barWidth: (entry.value / maxAmount * 100).clamp(10, 100).toDouble(),
              onTap: () => _navigateToTransactions(context, filter: entry.key),
            )),
        ],
      ),
    );
  }

  Widget _buildTodayTransactions(BuildContext context) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final today = DateTime.now();
    final todayLabel = '${today.day} ${months[today.month - 1]}';

    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
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
            ..._todayTransactions.map((tx) => TransactionRow(
              transaction: tx,
              onTap: () => _navigateToEdit(context, tx),
            )),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToAddTransaction(context, isIncome: false),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bg,
          border: Border.all(color: AppColors.accent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: AppColors.accent, size: 24),
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
      _loadData();
    }
  }

  void _navigateToAddTransaction(BuildContext context, {required bool isIncome}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(isIncome: isIncome),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _navigateToEdit(BuildContext context, Transaction tx) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTransactionScreen(transaction: tx),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }
}
