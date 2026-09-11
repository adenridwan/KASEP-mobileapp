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

class EditTransactionScreen extends StatefulWidget {
  final Transaction transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late String _selectedCategory;
  late String _amountStr;
  late DateTime _dateTime;
  late TextEditingController _noteController;
  List<String> _expenseCategories = [];
  List<IncomeCategory> _incomeCategories = [];
  List<FundSource> _fundSources = [];
  FundSource? _selectedFundSource;
  final FocusNode _noteFocusNode = FocusNode();
  bool _showDeleteDialog = false;
  bool _isSaving = false;
  bool _isNoteFieldFocused = false;
  bool _isEditingAmount = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.transaction.category;
    _amountStr = widget.transaction.amount.toString();
    _dateTime = widget.transaction.dateTime;
    _noteController = TextEditingController(text: widget.transaction.note ?? '');
    _noteFocusNode.addListener(_onNoteFocusChange);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final sources = await FundSourceRepository.instance.getAll();

    if (widget.transaction.isIncome) {
      final incomeCategories = await IncomeCategoryRepository.instance.getAll();
      if (mounted) {
        setState(() {
          _incomeCategories = incomeCategories;
          _fundSources = sources;
          _findSelectedFundSource(sources);
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _expenseCategories = Categories.expense;
          _fundSources = sources;
          _findSelectedFundSource(sources);
          _isLoading = false;
        });
      }
    }
  }

  void _findSelectedFundSource(List<FundSource> sources) {
    if (sources.isEmpty) return;

    if (widget.transaction.fundSourceId != null) {
      final found = sources.where((s) => s.id == widget.transaction.fundSourceId);
      if (found.isNotEmpty) {
        _selectedFundSource = found.first;
        return;
      }
    }

    if (widget.transaction.fundSource != null) {
      final found = sources.where((s) => s.name == widget.transaction.fundSource);
      if (found.isNotEmpty) {
        _selectedFundSource = found.first;
        return;
      }
    }

    // For income, default to first source if none selected
    if (widget.transaction.isIncome && sources.isNotEmpty) {
      _selectedFundSource = sources.first;
    }
  }

  void _onNoteFocusChange() {
    setState(() {
      _isNoteFieldFocused = _noteFocusNode.hasFocus;
      if (_isNoteFieldFocused) {
        _isEditingAmount = false;
      }
    });
  }

  @override
  void dispose() {
    _noteFocusNode.removeListener(_onNoteFocusChange);
    _noteFocusNode.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'del') {
        if (_amountStr.isNotEmpty) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        }
      } else if (_amountStr.length <= 11) {
        _amountStr = (_amountStr + key).replaceFirst(RegExp(r'^0+(?=\d)'), '');
      }
    });
  }

  void _focusOnAmount() {
    if (_noteFocusNode.hasFocus) {
      _noteFocusNode.unfocus();
    }
    setState(() {
      _isEditingAmount = true;
      _isNoteFieldFocused = false;
    });
  }

  int get _amount => int.tryParse(_amountStr) ?? 0;

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final updatedTransaction = widget.transaction.copyWith(
        category: _selectedCategory,
        amount: _amount,
        dateTime: _dateTime,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        title: _noteController.text.isNotEmpty
            ? _noteController.text
            : _selectedCategory,
        fundSource: _selectedFundSource?.name,
        fundSourceId: _selectedFundSource?.id,
      );

      await TransactionRepository.instance.update(updatedTransaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Catatan diperbarui'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.neutral900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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

  Future<void> _delete() async {
    setState(() => _showDeleteDialog = false);

    try {
      await TransactionRepository.instance.delete(widget.transaction.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Catatan dihapus'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.neutral900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
            content: Text('Gagal menghapus: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildForm()),
                if (_isEditingAmount && !_isNoteFieldFocused)
                  NumericKeypad(
                    onKeyPress: _onKeyPress,
                    onSave: _save,
                  ),
              ],
            ),
            if (_showDeleteDialog) _buildDeleteDialog(),
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
              '‹ Catatan',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.accent,
              ),
            ),
          ),
          const Text(
            'UBAH CATATAN',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          GestureDetector(
            onTap: _save,
            child: Text(
              'Simpan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final tx = widget.transaction;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAmountSection(tx),
          _buildCategorySection(),
          _buildFundSourceSection(),
          _buildDateTimeSection(tx),
          _buildNoteSection(tx),
          _buildImpactCallout(),
          _buildDeleteButton(),
        ],
      ),
    );
  }

  Widget _buildAmountSection(Transaction tx) {
    return GestureDetector(
      onTap: _focusOnAmount,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
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
                  'NOMINAL',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: AppColors.neutral700,
                  ),
                ),
                if (!_isEditingAmount)
                  Text(
                    'Ketuk untuk ubah',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: _isEditingAmount ? AppColors.accent : AppColors.divider,
                )),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Rp',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      CurrencyFormatter.formatDigits(_amountStr),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.8,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  if (_isEditingAmount)
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.accent,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${tx.title} · ${tx.formattedDateTime}',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.neutral700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    final List<String> categoryNames;
    if (widget.transaction.isIncome) {
      categoryNames = _incomeCategories.map((c) => c.name).toList();
      // Include current category if not in the list (might be deactivated)
      if (!categoryNames.contains(_selectedCategory)) {
        categoryNames.insert(0, _selectedCategory);
      }
    } else {
      categoryNames = _expenseCategories;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KATEGORI',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryNames.map((cat) => CustomChip(
              label: cat,
              isSelected: cat == _selectedCategory,
              onTap: () => setState(() => _selectedCategory = cat),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFundSourceSection() {
    if (_fundSources.isEmpty) {
      return const SizedBox.shrink();
    }

    final isIncome = widget.transaction.isIncome;
    final label = isIncome ? 'MASUK KE' : 'SUMBER DANA';
    final isRequired = isIncome;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: AppColors.neutral700,
                ),
              ),
              if (!isRequired) ...[
                const SizedBox(width: 8),
                Text(
                  '(opsional)',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _fundSources.map((source) => CustomChip(
              label: source.name,
              isSelected: _selectedFundSource?.id == source.id,
              onTap: () => setState(() {
                if (isRequired) {
                  // For income, always select (can't deselect)
                  _selectedFundSource = source;
                } else {
                  // For expense, toggle selection - can be deselected
                  if (_selectedFundSource?.id == source.id) {
                    _selectedFundSource = null;
                  } else {
                    _selectedFundSource = source;
                  }
                }
              }),
            )).toList(),
          ),
        ],
      ),
    );
  }

  String get _formattedDateTime {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final hour = _dateTime.hour.toString().padLeft(2, '0');
    final minute = _dateTime.minute.toString().padLeft(2, '0');
    return '${_dateTime.day} ${months[_dateTime.month - 1]} ${_dateTime.year}, $hour:$minute';
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dateTime),
      );

      if (time != null && mounted) {
        setState(() {
          _dateTime = DateTime(
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

  Widget _buildDateTimeSection(Transaction tx) {
    return GestureDetector(
      onTap: _selectDateTime,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TANGGAL & WAKTU',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                color: AppColors.neutral700,
              ),
            ),
            Row(
              children: [
                Text(
                  _formattedDateTime,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: AppColors.neutral500),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection(Transaction tx) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isEditingAmount = false;
        });
        _noteFocusNode.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CATATAN',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                color: AppColors.neutral700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              focusNode: _noteFocusNode,
              decoration: InputDecoration(
                hintText: 'Tambah catatan...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.neutral600,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 14),
              maxLines: null,
              textInputAction: TextInputAction.done,
              onEditingComplete: () {
                _noteFocusNode.unfocus();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactCallout() {
    return Container(
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border(
          top: BorderSide(color: AppColors.divider),
          right: BorderSide(color: AppColors.divider),
          bottom: BorderSide(color: AppColors.divider),
          left: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            color: AppColors.neutral800,
            height: 1.6,
          ),
          children: const [
            TextSpan(text: 'Perubahan ini membuat total makan Agustus menjadi '),
            TextSpan(
              text: 'Rp 3.155.000',
              style: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
            ),
            TextSpan(text: ' dan bersih menjadi '),
            TextSpan(
              text: '+Rp 3.400.000',
              style: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
            ),
            TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: GestureDetector(
          onTap: () => setState(() => _showDeleteDialog = true),
          child: Container(
            padding: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.accent800)),
            ),
            child: Text(
              'Hapus catatan ini',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.accent800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    final tx = widget.transaction;
    return GestureDetector(
      onTap: () => setState(() => _showDeleteDialog = false),
      child: Container(
        color: Colors.black.withOpacity(0.46),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Hapus catatan ini?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${tx.title} — Rp ${tx.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}, ${tx.formattedDateTime}. Total keluar Agustus turun jadi Rp 8.680.000. Tindakan ini tidak bisa dibatalkan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.neutral800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: _delete,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.accent800),
                      ),
                      child: Center(
                        child: Text(
                          'Hapus',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() => _showDeleteDialog = false),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Center(
                        child: Text(
                          'Biarkan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
