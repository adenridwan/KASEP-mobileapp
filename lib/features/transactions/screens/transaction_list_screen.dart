import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_chip.dart';
import '../../../core/storage/transaction_repository.dart';
import '../../../models/transaction.dart';
import '../../home/widgets/transaction_row.dart';
import 'add_transaction_screen.dart';
import 'edit_transaction_screen.dart';

class TransactionListScreen extends StatefulWidget {
  final String? initialFilter;

  const TransactionListScreen({super.key, this.initialFilter});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  late String _currentFilter;
  final List<String> _baseFilters = ['Semua', 'Keluar', 'Masuk'];

  List<Transaction> _allTransactions = [];
  bool _isLoading = true;
  bool _hasChanges = false;
  final DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter ?? 'Semua';
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    final transactions = await TransactionRepository.instance.getByMonth(
      _currentMonth.year,
      _currentMonth.month,
    );

    if (mounted) {
      setState(() {
        _allTransactions = transactions;
        _isLoading = false;
      });
    }
  }

  List<Transaction> get _filteredTransactions {
    if (_currentFilter == 'Semua') return _allTransactions;
    if (_currentFilter == 'Keluar') {
      return _allTransactions.where((tx) => !tx.isIncome).toList();
    }
    if (_currentFilter == 'Masuk') {
      return _allTransactions.where((tx) => tx.isIncome).toList();
    }
    // Filter by category
    return _allTransactions.where((tx) => tx.category == _currentFilter).toList();
  }

  Map<String, List<Transaction>> get _filteredTransactionsByDate {
    final filtered = _filteredTransactions;
    final grouped = <String, List<Transaction>>{};
    for (final tx in filtered) {
      final key = '${tx.dateTime.year}-${tx.dateTime.month}-${tx.dateTime.day}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(tx);
    }
    return grouped;
  }

  List<String> get _filters {
    if (_baseFilters.contains(_currentFilter)) {
      return _baseFilters;
    }
    return [..._baseFilters, _currentFilter];
  }

  String get _countText {
    final count = _filteredTransactions.length;
    if (_currentFilter == 'Semua') return '$count catatan';
    return '$_currentFilter · $count catatan';
  }

  String get _monthName {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[_currentMonth.month - 1];
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
              GestureDetector(
                onTap: () => Navigator.pop(context, _hasChanges),
                child: Text(
                  '‹ Laporan',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.accent,
                  ),
                ),
              ),
              Text(
                _countText,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Catatan · $_monthName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _filters.map((f) => CustomChip(
              label: f,
              isSelected: f == _currentFilter,
              isSmall: true,
              onTap: () => setState(() => _currentFilter = f),
            )).toList(),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _getDayName(DateTime date) {
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return days[date.weekday % 7];
  }

  String _formatDateLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${_getDayName(date)} ${date.day} ${months[date.month - 1]}';
  }

  String _getDaySummary(List<Transaction> transactions) {
    int income = 0;
    int expense = 0;
    for (final tx in transactions) {
      if (tx.isIncome) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    final parts = <String>[];
    if (income > 0) parts.add('masuk ${_formatCurrency(income)}');
    if (expense > 0) parts.add('keluar ${_formatCurrency(expense)}');
    return parts.join(' · ');
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final grouped = _filteredTransactionsByDate;
    if (grouped.isEmpty) {
      return Center(
        child: Text(
          'Belum ada catatan',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.neutral600,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Sort date keys descending
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      children: [
        ...sortedKeys.map((key) {
          final transactions = grouped[key]!;
          final date = transactions.first.dateTime;
          return _buildDaySection(
            _formatDateLabel(date),
            _getDaySummary(transactions),
            transactions,
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDaySection(String title, String summary, List<Transaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.text)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                summary,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.neutral700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        ...transactions.map((tx) => TransactionRow(
          transaction: tx,
          onTap: () => _navigateToEdit(tx),
        )),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 34),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: GestureDetector(
        onTap: () => _navigateToAdd(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.accent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 17, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                'Tambah kas keluar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen(isIncome: false)),
    );
    if (result == true) {
      _hasChanges = true;
      _loadTransactions();
    }
  }

  void _navigateToEdit(Transaction tx) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditTransactionScreen(transaction: tx)),
    );
    if (result == true) {
      _hasChanges = true;
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _hasChanges) {
          // Parent will handle refresh based on the returned value
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildList()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
