import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../core/storage/budget_repository.dart';
import '../../../core/storage/fund_source_repository.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/budget.dart';
import '../../../models/fund_source.dart';

const _months = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
];

class BudgetScreen extends StatefulWidget {
  final int year;
  final int month;

  const BudgetScreen({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late int _year;
  late int _month;
  List<BudgetProgress> _progress = [];
  List<FundSource> _fundSources = [];
  bool _isLoading = true;
  bool _hasPrevMonthTargets = false;

  @override
  void initState() {
    super.initState();
    _year = widget.year;
    _month = widget.month;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final progress = await BudgetRepository.instance.getBudgetProgress(_year, _month);
    final sources = await FundSourceRepository.instance.getAll();
    final prev = DateTime(_year, _month - 1);
    final prevBudgets = await BudgetRepository.instance.getByMonth(prev.year, prev.month);

    if (mounted) {
      setState(() {
        _progress = progress;
        _fundSources = sources;
        _hasPrevMonthTargets = prevBudgets.isNotEmpty;
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int delta) {
    final d = DateTime(_year, _month + delta);
    setState(() {
      _year = d.year;
      _month = d.month;
    });
    _loadData();
  }

  Future<void> _copyFromPreviousMonth() async {
    final count = await BudgetRepository.instance.copyFromPreviousMonth(_year, _month);
    if (!mounted) return;
    _showSnack('$count target disalin dari bulan lalu');
    _loadData();
  }

  Future<void> _openForm([Budget? budget]) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BudgetForm(
        year: _year,
        month: _month,
        budget: budget,
        fundSources: _fundSources,
      ),
    );
    if (changed == true) _loadData();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.neutral900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  void _showMonthPicker() {
    int tempYear = _year;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHandle(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildIconButton(
                          Icons.chevron_left,
                          () => setModalState(() => tempYear--),
                        ),
                        Text(
                          '$tempYear',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        _buildIconButton(
                          Icons.chevron_right,
                          () => setModalState(() => tempYear++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.6,
                      children: List.generate(12, (i) {
                        final isSelected = tempYear == _year && i + 1 == _month;
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _year = tempYear;
                              _month = i + 1;
                            });
                            _loadData();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.accent : AppColors.bg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _shortMonths[i],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.text,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: _progress.isEmpty ? _buildEmpty() : _buildList(),
                    ),
            ),
            if (!_isLoading && _progress.isNotEmpty) _buildAddButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildIconButton(Icons.arrow_back, () => Navigator.pop(context, true)),
              const SizedBox(width: 12),
              Text(
                'Target Pengeluaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildIconButton(Icons.chevron_left, () => _changeMonth(-1)),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: _showMonthPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month, size: 16, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text(
                          '${_months[_month - 1]} $_year',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.expand_more, size: 18, color: AppColors.neutral600),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildIconButton(Icons.chevron_right, () => _changeMonth(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        Icon(Icons.track_changes, size: 48, color: AppColors.accent2),
        const SizedBox(height: 16),
        Text(
          'Belum ada target untuk ${_months[_month - 1]} $_year',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Buat target per kategori, per sumber dana, atau total pengeluaran bulan ini.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.neutral600, height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton('Tambah Target', Icons.add, () => _openForm()),
        if (_hasPrevMonthTargets) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _copyFromPreviousMonth,
            icon: const Icon(Icons.copy_all, size: 18),
            label: const Text('Salin dari bulan lalu'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: BorderSide(color: AppColors.accent300),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildList() {
    final totalTarget = _progress.fold<int>(0, (s, p) => s + p.budget.amount);
    final totalSpent = _progress.fold<int>(0, (s, p) => s + p.spent);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSummary(totalTarget, totalSpent),
        const SizedBox(height: 16),
        ..._progress.map(_buildTargetCard),
      ],
    );
  }

  Widget _buildSummary(int totalTarget, int totalSpent) {
    final remaining = totalTarget - totalSpent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildSummaryItem('Total target', totalTarget, AppColors.text),
          _buildSummaryItem('Terpakai', totalSpent, AppColors.text),
          _buildSummaryItem(
            remaining >= 0 ? 'Sisa' : 'Lebih',
            remaining.abs(),
            remaining >= 0 ? AppColors.accent700 : AppColors.negative,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int amount, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.neutral700)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.formatWithRp(amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard(BudgetProgress bp) {
    final budget = bp.budget;
    final percentage = bp.percentage;
    final statusColor = bp.isOverBudget
        ? AppColors.negative
        : bp.isWarning
            ? AppColors.accent2
            : AppColors.accent;

    return GestureDetector(
      onTap: () => _openForm(budget),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    budget.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Icon(Icons.edit_outlined, size: 16, color: AppColors.neutral500),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildTag(Icons.category_outlined, budget.category ?? 'Semua kategori'),
                _buildTag(
                  Icons.account_balance_wallet_outlined,
                  bp.fundSourceName ?? 'Semua sumber dana',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: AppColors.neutral200,
                valueColor: AlwaysStoppedAnimation(statusColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${CurrencyFormatter.formatWithRp(bp.spent)} / ${CurrencyFormatter.format(budget.amount)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Text(
                  bp.isOverBudget
                      ? 'Lebih ${CurrencyFormatter.format(-bp.remaining)}'
                      : '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.neutral600),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: AppColors.neutral700)),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      color: AppColors.bg,
      child: SizedBox(
        width: double.infinity,
        child: _buildPrimaryButton('Tambah Target', Icons.add, () => _openForm()),
      ),
    );
  }

  Widget _buildPrimaryButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.neutral200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppColors.neutral700),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.neutral300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Bottom sheet for creating or editing a target. Pops `true` when data changed.
class _BudgetForm extends StatefulWidget {
  final int year;
  final int month;
  final Budget? budget;
  final List<FundSource> fundSources;

  const _BudgetForm({
    required this.year,
    required this.month,
    required this.fundSources,
    this.budget,
  });

  @override
  State<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<_BudgetForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  String? _category;
  String? _fundSourceId;
  int? _currentSpent;
  bool _isSaving = false;

  bool get _isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    _nameController = TextEditingController(text: b?.name ?? '');
    _amountController = TextEditingController(
      text: b != null ? CurrencyFormatter.format(b.amount) : '',
    );
    _category = b?.category;
    _fundSourceId = b?.fundSourceId;
    _loadCurrentSpent();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSpent() async {
    final spent = await BudgetRepository.instance.getSpent(
      widget.year,
      widget.month,
      category: _category,
      fundSourceId: _fundSourceId,
    );
    if (mounted) setState(() => _currentSpent = spent);
  }

  int get _amount => int.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;

  Future<void> _save() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nominal target terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final name = _nameController.text.trim().isEmpty ? null : _nameController.text.trim();

    if (_isEditing) {
      final b = widget.budget!;
      await BudgetRepository.instance.update(Budget(
        id: b.id,
        name: name,
        category: _category,
        fundSourceId: _fundSourceId,
        amount: _amount,
        month: b.month,
        year: b.year,
        createdAt: b.createdAt,
      ));
    } else {
      await BudgetRepository.instance.create(
        name: name,
        category: _category,
        fundSourceId: _fundSourceId,
        amount: _amount,
        year: widget.year,
        month: widget.month,
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus target?'),
        content: Text('Target "${widget.budget!.label}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: TextStyle(color: AppColors.negative)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await BudgetRepository.instance.delete(widget.budget!.id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neutral300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isEditing ? 'Edit Target' : 'Target Baru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  '${_months[widget.month - 1]} ${widget.year}',
                  style: TextStyle(fontSize: 12, color: AppColors.neutral600),
                ),
                const SizedBox(height: 20),
                _buildLabel('Nominal target'),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandsFormatter(),
                  ],
                  autofocus: !_isEditing,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  decoration: _inputDecoration(hint: '0', prefix: 'Rp '),
                ),
                const SizedBox(height: 20),
                _buildLabel('Kategori'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChoice('Semua kategori', _category == null, () {
                      setState(() => _category = null);
                      _loadCurrentSpent();
                    }),
                    ...Categories.expense.map((c) => _buildChoice(c, _category == c, () {
                          setState(() => _category = c);
                          _loadCurrentSpent();
                        })),
                  ],
                ),
                const SizedBox(height: 20),
                _buildLabel('Sumber dana'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChoice('Semua sumber dana', _fundSourceId == null, () {
                      setState(() => _fundSourceId = null);
                      _loadCurrentSpent();
                    }),
                    ...widget.fundSources.map((s) => _buildChoice(
                          s.name,
                          _fundSourceId == s.id,
                          () {
                            setState(() => _fundSourceId = s.id);
                            _loadCurrentSpent();
                          },
                        )),
                  ],
                ),
                const SizedBox(height: 20),
                _buildLabel('Nama target (opsional)'),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(hint: 'Contoh: Jajan bulanan'),
                ),
                const SizedBox(height: 16),
                if (_currentSpent != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.neutral600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pengeluaran yang cocok bulan ini: ${CurrencyFormatter.formatWithRp(_currentSpent!)}',
                            style: TextStyle(fontSize: 12, color: AppColors.neutral700),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (_isEditing) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _delete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.negative,
                            side: BorderSide(color: AppColors.negative.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Hapus'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.neutral700,
        ),
      ),
    );
  }

  Widget _buildChoice(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.accent : AppColors.neutral300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.neutral400),
      prefixText: prefix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.neutral300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.neutral300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    );
  }
}

/// Formats digits as 1.500.000 while typing
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final formatted = CurrencyFormatter.format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
