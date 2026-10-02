import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/storage/transaction_repository.dart';
import '../../../core/storage/fund_source_repository.dart';
import '../../../core/storage/monthly_note_repository.dart';
import '../../../core/storage/budget_repository.dart';
import '../../../models/transaction.dart';
import '../../../models/fund_source.dart';
import '../../../models/monthly_note.dart';
import '../../../models/budget.dart';
import '../../transactions/screens/transaction_list_screen.dart';
import '../../transactions/screens/add_transaction_screen.dart';
import '../../transactions/screens/edit_transaction_screen.dart';
import '../../categories/screens/categories_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../auth/screens/auth_router.dart';
import '../../monthly_notes/screens/monthly_notes_screen.dart';
import '../../budget/screens/budget_screen.dart';
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
  List<Map<String, dynamic>> _fundSourcesWithBalances = [];
  bool _isLoading = true;
  MonthlyNote? _monthlyNote;
  List<BudgetProgress> _budgetProgress = [];

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
    final fundSourcesWithBalances =
        await FundSourceRepository.instance.getAllWithBalances();
    final monthlyNote = await MonthlyNoteRepository.instance.getByMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final budgetProgress = await BudgetRepository.instance.getBudgetProgress(
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
        _fundSourcesWithBalances = fundSourcesWithBalances;
        _monthlyNote = monthlyNote;
        _budgetProgress = budgetProgress;
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
                        const SizedBox(height: 20),
                        _buildFundSourcesSection(),
                        const SizedBox(height: 20),
                        _buildBudgetCard(context),
                        const SizedBox(height: 20),
                        _buildBalanceChart(),
                        const SizedBox(height: 22),
                        _buildMonthlyNoteCard(context),
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
    final hasNote = _monthlyNote != null && _monthlyNote!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Spacer(),
              _buildHeaderIcon(
                icon: Icons.settings_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              const SizedBox(width: 8),
              _buildHeaderIcon(
                icon: Icons.logout,
                color: AppColors.negative,
                onTap: _showLogoutDialog,
              ),
            ],
          ),
          const SizedBox(height: 10),
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
              const SizedBox(width: 6),
              _buildHeaderIcon(
                icon: Icons.edit_note,
                color: hasNote ? AppColors.accent : AppColors.neutral700,
                background: hasNote ? AppColors.accent.withValues(alpha: 0.15) : null,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MonthlyNotesScreen(
                        initialYear: _selectedMonth.year,
                        initialMonth: _selectedMonth.month,
                      ),
                    ),
                  );
                  loadData();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    Color? background,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background ?? AppColors.surface,
        ),
        child: Icon(icon, size: 18, color: color ?? AppColors.neutral700),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun ini?'),
        content: const Text(
          'Catatan tetap tersimpan terenkripsi di ponsel. '
          'Anda perlu sidik jari atau PIN untuk masuk kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
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

  Widget _buildFundSourcesSection() {
    if (_fundSourcesWithBalances.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate total balance
    int totalBalance = 0;
    for (final item in _fundSourcesWithBalances) {
      totalBalance += item['balance'] as int;
    }

    // Gradient colors for cards
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)], // Purple-violet
      [const Color(0xFF11998e), const Color(0xFF38ef7d)], // Teal-green
      [const Color(0xFFf093fb), const Color(0xFFf5576c)], // Pink-red
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)], // Blue-cyan
      [const Color(0xFFfa709a), const Color(0xFFfee140)], // Pink-yellow
      [const Color(0xFF30cfd0), const Color(0xFF330867)], // Cyan-purple
    ];

    // Icons for fund sources
    IconData getIconForSource(String? iconName, String name) {
      if (iconName != null) {
        switch (iconName) {
          case 'wallet':
            return Icons.account_balance_wallet;
          case 'bank':
            return Icons.account_balance;
          case 'cash':
            return Icons.payments;
          case 'savings':
            return Icons.savings;
          case 'card':
            return Icons.credit_card;
        }
      }
      // Default based on name
      final lowerName = name.toLowerCase();
      if (lowerName.contains('bank') || lowerName.contains('bca') ||
          lowerName.contains('bni') || lowerName.contains('bri') ||
          lowerName.contains('mandiri')) {
        return Icons.account_balance;
      } else if (lowerName.contains('gopay') || lowerName.contains('ovo') ||
                 lowerName.contains('dana') || lowerName.contains('shopeepay')) {
        return Icons.phone_android;
      } else if (lowerName.contains('tunai') || lowerName.contains('cash')) {
        return Icons.payments;
      }
      return Icons.account_balance_wallet;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sumber Dana',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total: ${_formatCurrency(totalBalance)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_fundSourcesWithBalances.length} akun',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Horizontal scrollable cards
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _fundSourcesWithBalances.length,
            itemBuilder: (context, index) {
              final item = _fundSourcesWithBalances[index];
              final source = item['source'] as FundSource;
              final balance = item['balance'] as int;
              final gradient = gradients[index % gradients.length];
              final icon = getIconForSource(source.icon, source.name);

              return Container(
                width: 160,
                margin: EdgeInsets.only(
                  right: index < _fundSourcesWithBalances.length - 1 ? 12 : 0,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -20,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              icon,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            source.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _formatCurrency(balance),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BudgetScreen(
              year: _selectedMonth.year,
              month: _selectedMonth.month,
            ),
          ),
        );
        loadData();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent2.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.track_changes,
                        size: 18,
                        color: AppColors.accent2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Target Pengeluaran',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _budgetProgress.isEmpty ? 'Atur' : 'Edit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_budgetProgress.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent2.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent2.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_chart,
                      size: 28,
                      color: AppColors.accent2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada target bulan ini',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ketuk untuk atur target pengeluaran',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._budgetProgress.take(3).map((bp) => _buildBudgetProgressRow(bp)),
            if (_budgetProgress.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    '+${_budgetProgress.length - 3} target lainnya',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.neutral600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetProgressRow(BudgetProgress bp) {
    final percentage = bp.percentage;
    final isOver = bp.isOverBudget;
    final isWarning = bp.isWarning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  bp.fundSourceName != null
                      ? '${bp.budget.label} · ${bp.fundSourceName}'
                      : bp.budget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Rp ${_formatCurrency(bp.spent)} / ${_formatCurrency(bp.budget.amount)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isOver
                      ? AppColors.negative
                      : isWarning
                          ? AppColors.accent2
                          : AppColors.neutral600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (percentage / 100).clamp(0, 1),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOver
                        ? AppColors.negative
                        : isWarning
                            ? AppColors.accent2
                            : AppColors.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildMonthlyNoteCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MonthlyNotesScreen(
              initialYear: _selectedMonth.year,
              initialMonth: _selectedMonth.month,
            ),
          ),
        );
        loadData();
      },
      child: Container(
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.edit_note,
                    size: 18,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catatan Bulanan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        _formattedMonth,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.neutral400,
                ),
              ],
            ),
            if (_monthlyNote != null && _monthlyNote!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _monthlyNote!.content.length > 150
                      ? '${_monthlyNote!.content.substring(0, 150)}...'
                      : _monthlyNote!.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral700,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tulis catatan bulan ini',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
