import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/fund_source_repository.dart';
import '../../../models/fund_source.dart';
import 'add_fund_source_screen.dart';
import 'transfer_screen.dart';

class FundSourcesScreen extends StatefulWidget {
  const FundSourcesScreen({super.key});

  @override
  State<FundSourcesScreen> createState() => _FundSourcesScreenState();
}

class _FundSourcesScreenState extends State<FundSourcesScreen> {
  List<Map<String, dynamic>> _sourcesWithBalances = [];
  int _totalBalance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final sourcesWithBalances = await FundSourceRepository.instance.getAllWithBalances();
    final totalBalance = await FundSourceRepository.instance.getTotalBalance();

    if (mounted) {
      setState(() {
        _sourcesWithBalances = sourcesWithBalances;
        _totalBalance = totalBalance;
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(int amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${isNegative ? '-' : ''}Rp $absAmount';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              '‹ Kembali',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.accent,
              ),
            ),
          ),
          const Text(
            'SUMBER DANA',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddFundSourceScreen()),
              );
              if (result == true) {
                _loadData();
              }
            },
            child: Text(
              '+ Tambah',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalBalance(),
          const SizedBox(height: 20),
          _buildTransferButton(),
          const SizedBox(height: 20),
          _buildSourcesList(),
        ],
      ),
    );
  }

  Widget _buildTotalBalance() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.accent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 20,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Text(
                'Total Saldo',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatCurrency(_totalBalance),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: _totalBalance >= 0 ? Colors.white : Colors.red[200],
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_sourcesWithBalances.length} sumber dana aktif',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferButton() {
    return GestureDetector(
      onTap: () async {
        if (_sourcesWithBalances.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Minimal 2 sumber dana untuk transfer'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.neutral900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            ),
          );
          return;
        }

        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TransferScreen()),
        );
        if (result == true) {
          _loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surface,
          border: Border.all(color: AppColors.accent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz, size: 20, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              'Transfer Antar Sumber',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourcesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Daftar Sumber Dana',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral700,
            ),
          ),
        ),
        if (_sourcesWithBalances.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 40,
                  color: AppColors.neutral400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum ada sumber dana',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_sourcesWithBalances.length, (index) {
            final item = _sourcesWithBalances[index];
            final source = item['source'] as FundSource;
            final balance = item['balance'] as int;
            return _buildSourceRow(source, balance, index);
          }),
      ],
    );
  }

  Widget _buildSourceRow(FundSource source, int balance, int index) {
    // Calculate percentage of total (for progress bar)
    final percentage = _totalBalance > 0 ? (balance / _totalBalance * 100).clamp(0, 100) : 0.0;

    return GestureDetector(
      onTap: () => _showSourceOptions(source),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 20,
                    color: AppColors.accent700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${percentage.toStringAsFixed(1)}% dari total',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatCurrency(balance),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: balance >= 0 ? AppColors.accent700 : Colors.red,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 6,
                backgroundColor: AppColors.neutral200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  balance >= 0 ? AppColors.accent : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSourceOptions(FundSource source) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              source.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionItem(
              icon: Icons.edit_outlined,
              label: 'Ubah nama',
              onTap: () {
                Navigator.pop(context);
                _editSourceName(source);
              },
            ),
            _buildOptionItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Atur saldo awal',
              onTap: () {
                Navigator.pop(context);
                _editInitialBalance(source);
              },
            ),
            _buildOptionItem(
              icon: Icons.delete_outline,
              label: 'Nonaktifkan',
              color: AppColors.accent800,
              onTap: () {
                Navigator.pop(context);
                _confirmDeactivate(source);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? AppColors.neutral700),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editSourceName(FundSource source) {
    final controller = TextEditingController(text: source.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nama sumber dana',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final nav = Navigator.of(context);
                await FundSourceRepository.instance.update(
                  source.copyWith(name: controller.text.trim()),
                );
                nav.pop();
                _loadData();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _editInitialBalance(FundSource source) {
    final controller = TextEditingController(
      text: source.initialBalance.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saldo Awal'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Saldo awal',
            prefixText: 'Rp ',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final balance = int.tryParse(controller.text) ?? 0;
              await FundSourceRepository.instance.update(
                source.copyWith(initialBalance: balance),
              );
              nav.pop();
              _loadData();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivate(FundSource source) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nonaktifkan Sumber Dana?'),
        content: Text(
          'Sumber dana "${source.name}" akan dinonaktifkan. '
          'Data transaksi tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              await FundSourceRepository.instance.deactivate(source.id);
              nav.pop();
              _loadData();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.accent800),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );
  }
}
