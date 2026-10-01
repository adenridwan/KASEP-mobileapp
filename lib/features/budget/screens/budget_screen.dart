import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../core/storage/budget_repository.dart';
import '../../../core/storage/transaction_repository.dart';

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
  Map<String, int> _categoryTotals = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadData();
  }

  void _initControllers() {
    for (final category in Categories.expense) {
      _controllers[category] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final progress = await BudgetRepository.instance.getBudgetProgress(
      widget.year,
      widget.month,
    );
    final totals = await TransactionRepository.instance.getTotalByCategoryForMonth(
      widget.year,
      widget.month,
    );

    // Set controller values from existing budgets
    for (final bp in progress) {
      if (_controllers.containsKey(bp.budget.category)) {
        _controllers[bp.budget.category]!.text =
            (bp.budget.amount ~/ 1000).toString(); // Show in thousands
      }
    }

    if (mounted) {
      setState(() {
        _categoryTotals = totals;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBudgets() async {
    setState(() => _isSaving = true);

    try {
      for (final entry in _controllers.entries) {
        final category = entry.key;
        final text = entry.value.text.trim();

        if (text.isNotEmpty) {
          final amount = (int.tryParse(text) ?? 0) * 1000; // Convert from thousands
          if (amount > 0) {
            await BudgetRepository.instance.createOrUpdate(
              category,
              amount,
              widget.year,
              widget.month,
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Target tersimpan'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.neutral900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String get _formattedMonth {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${months[widget.month - 1]} ${widget.year}';
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
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
                  : _buildContent(),
            ),
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
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_back, size: 20, color: AppColors.neutral700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Pengeluaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      _formattedMonth,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _isSaving ? null : _saveBudgets,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Atur target pengeluaran per kategori (dalam ribuan)',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: 16),
          ...Categories.expense.map((category) => _buildCategoryRow(category)),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String category) {
    final spent = _categoryTotals[category] ?? 0;
    final controller = _controllers[category]!;
    final budgetAmount = (int.tryParse(controller.text) ?? 0) * 1000;
    final percentage = budgetAmount > 0 ? (spent / budgetAmount * 100).clamp(0, 100) : 0;

    return Container(
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
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
              Text(
                'Terpakai: Rp ${_formatCurrency(spent)}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Rp',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: AppColors.neutral400),
                    suffixText: '.000',
                    suffixStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral600,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.neutral300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.neutral300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (budgetAmount > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: AppColors.neutral200,
                valueColor: AlwaysStoppedAnimation(
                  percentage >= 100
                      ? AppColors.negative
                      : percentage >= 80
                          ? AppColors.accent2
                          : AppColors.accent,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(0)}% dari target',
              style: TextStyle(
                fontSize: 11,
                color: percentage >= 100
                    ? AppColors.negative
                    : percentage >= 80
                        ? AppColors.accent2
                        : AppColors.neutral600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
