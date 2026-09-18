import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_chip.dart';
import '../../../core/storage/transaction_repository.dart';
import '../../../core/storage/fund_source_repository.dart';
import '../../../core/storage/income_category_repository.dart';
import '../../../models/transaction.dart';
import '../../../models/fund_source.dart';
import '../../../models/income_category.dart';
import '../widgets/numeric_keypad.dart';

class AddTransactionScreen extends StatefulWidget {
  final bool isIncome;

  const AddTransactionScreen({super.key, required this.isIncome});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _amount = '';
  String? _selectedCategory;
  List<String> _expenseCategories = [];
  List<IncomeCategory> _incomeCategories = [];
  List<FundSource> _fundSources = [];
  FundSource? _selectedFundSource;
  DateTime _selectedDateTime = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load fund sources for both income and expense
    final sources = await FundSourceRepository.instance.getAll();

    if (widget.isIncome) {
      // Load income categories from database
      final incomeCategories = await IncomeCategoryRepository.instance.getAll();
      if (mounted) {
        setState(() {
          _incomeCategories = incomeCategories;
          _fundSources = sources;
          if (incomeCategories.isNotEmpty) {
            _selectedCategory = incomeCategories.first.name;
          }
          if (sources.isNotEmpty) {
            _selectedFundSource = sources.first;
          }
          _isLoading = false;
        });
      }
    } else {
      // Use static expense categories
      if (mounted) {
        setState(() {
          _expenseCategories = Categories.expense;
          _fundSources = sources;
          _selectedCategory = _expenseCategories.first;
          if (sources.isNotEmpty) {
            _selectedFundSource = sources.first;
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'del') {
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else if (_amount.length <= 11) {
        _amount = (_amount + key).replaceFirst(RegExp(r'^0+(?=\d)'), '');
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving || _selectedCategory == null) return;

    setState(() => _isSaving = true);

    try {
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _noteController.text.isNotEmpty
            ? _noteController.text
            : _selectedCategory!,
        amount: int.tryParse(_amount) ?? 0,
        category: _selectedCategory!,
        dateTime: _selectedDateTime,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        isIncome: widget.isIncome,
        fundSource: _selectedFundSource?.name,
        fundSourceId: _selectedFundSource?.id,
      );

      await TransactionRepository.instance.create(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tersimpan · Rp ${CurrencyFormatter.formatDigits(_amount)}',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.neutral900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            duration: const Duration(milliseconds: 2200),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate data changed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildForm()),
            NumericKeypad(onKeyPress: _onKeyPress, onSave: _save),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 22, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.close,
                size: 20,
                color: AppColors.neutral700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              widget.isIncome ? 'Tambah pemasukan' : 'Tambah pengeluaran',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 36), // Balance the close button width
        ],
      ),
    );
  }

  Widget _buildForm() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildAmountSection(),
          _buildCategorySection(),
          _buildFundSourceSection(),
          _buildDateTimeSection(),
          _buildNoteSection(),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Container(
        margin: const EdgeInsets.fromLTRB(22, 16, 22, 6),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isIncome
                ? [const Color(0xFFE8F5F1), const Color(0xFFD4EDE5)]
                : [const Color(0xFFF3F0FA), const Color(0xFFE8E4F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.isIncome
                ? AppColors.accent.withValues(alpha: 0.2)
                : AppColors.lavender.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isIncome
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : AppColors.neutral700.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.isIncome ? 'PEMASUKAN' : 'PENGELUARAN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: widget.isIncome ? AppColors.accent700 : AppColors.neutral700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Rp',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: widget.isIncome ? AppColors.accent600 : AppColors.neutral600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _amount.isEmpty ? '0' : CurrencyFormatter.formatDigits(_amount),
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: widget.isIncome ? AppColors.accent700 : AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: widget.isIncome
                    ? AppColors.accent
                    : AppColors.neutral500,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildCategorySection() {
    final List<String> categoryNames;
    if (widget.isIncome) {
      categoryNames = _incomeCategories.map((c) => c.name).toList();
    } else {
      categoryNames = _expenseCategories;
    }

    if (categoryNames.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(22, 16, 22, 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: AppColors.neutral500),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.isIncome
                    ? 'Belum ada kategori pemasukan. Tambah di Pengaturan.'
                    : 'Tidak ada kategori tersedia.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(22, 12, 22, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryNames
                .map(
                  (cat) => CustomChip(
                    label: cat,
                    isSelected: cat == _selectedCategory,
                    onTap: () => setState(() => _selectedCategory = cat),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFundSourceSection() {
    if (_fundSources.isEmpty) {
      return const SizedBox.shrink();
    }

    final label = widget.isIncome ? 'Masuk ke' : 'Sumber Dana';
    final isRequired = widget.isIncome;

    return Container(
      margin: const EdgeInsets.fromLTRB(22, 8, 22, 6),
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
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: AppColors.neutral600,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral700,
                ),
              ),
              if (!isRequired) ...[
                const SizedBox(width: 6),
                Text(
                  '(opsional)',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _fundSources
                .map(
                  (source) => CustomChip(
                    label: source.name,
                    isSelected: _selectedFundSource?.id == source.id,
                    onTap: () => setState(() {
                      if (isRequired) {
                        _selectedFundSource = source;
                      } else {
                        if (_selectedFundSource?.id == source.id) {
                          _selectedFundSource = null;
                        } else {
                          _selectedFundSource = source;
                        }
                      }
                    }),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  String get _formattedDateTime {
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
    final hour = _selectedDateTime.hour.toString().padLeft(2, '0');
    final minute = _selectedDateTime.minute.toString().padLeft(2, '0');
    return '${_selectedDateTime.day} ${months[_selectedDateTime.month - 1]} ${_selectedDateTime.year}, $hour:$minute';
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Widget _buildDateTimeSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 8, 22, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: GestureDetector(
        onTap: _selectDateTime,
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.neutral600,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tanggal & Waktu',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral700,
                ),
              ),
            ),
            Text(
              _formattedDateTime,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog() {
    final tempController = TextEditingController(text: _noteController.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Catatan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: 22,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: tempController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Tulis catatan di sini...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(fontSize: 14, height: 1.5),
                  maxLines: 6,
                  minLines: 4,
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _noteController.text = tempController.text;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Simpan Catatan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    final hasNote = _noteController.text.isNotEmpty;

    return GestureDetector(
      onTap: _showNoteDialog,
      child: Container(
        margin: const EdgeInsets.fromLTRB(22, 8, 22, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.edit_note,
              size: 18,
              color: hasNote ? AppColors.accent : AppColors.neutral600,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasNote ? _noteController.text : 'Catatan (opsional)',
                style: TextStyle(
                  fontSize: 14,
                  color: hasNote ? AppColors.text : AppColors.neutral500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}
