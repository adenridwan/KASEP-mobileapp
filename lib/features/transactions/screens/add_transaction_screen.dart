import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_chip.dart';
import '../../../core/storage/transaction_repository.dart';
import '../../../models/transaction.dart';
import '../widgets/numeric_keypad.dart';

class AddTransactionScreen extends StatefulWidget {
  final bool isIncome;

  const AddTransactionScreen({super.key, required this.isIncome});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _amount = '';
  late String _selectedCategory;
  late List<String> _categories;
  DateTime _selectedDateTime = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  bool _isSaving = false;
  bool _isNoteFieldFocused = false;

  @override
  void initState() {
    super.initState();
    _categories = widget.isIncome ? Categories.income : Categories.expense;
    _selectedCategory = _categories.first;
    _noteFocusNode.addListener(_onNoteFocusChange);
  }

  void _onNoteFocusChange() {
    setState(() {
      _isNoteFieldFocused = _noteFocusNode.hasFocus;
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
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else if (_amount.length <= 11) {
        _amount = (_amount + key).replaceFirst(RegExp(r'^0+(?=\d)'), '');
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _noteController.text.isNotEmpty
            ? _noteController.text
            : _selectedCategory,
        amount: int.tryParse(_amount) ?? 0,
        category: _selectedCategory,
        dateTime: _selectedDateTime,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        isIncome: widget.isIncome,
      );

      await TransactionRepository.instance.create(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tersimpan · Rp ${CurrencyFormatter.formatDigits(_amount)}'),
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
            if (!_isNoteFieldFocused)
              NumericKeypad(
                onKeyPress: _onKeyPress,
                onSave: _save,
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
              'Batal',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral700,
              ),
            ),
          ),
          Text(
            widget.isIncome ? 'KAS MASUK' : 'KAS KELUAR',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          GestureDetector(
            onTap: _amount.isNotEmpty ? _save : null,
            child: Text(
              'Simpan',
              style: TextStyle(
                fontSize: 13,
                color: _amount.isNotEmpty ? AppColors.accent : AppColors.neutral400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildAmountSection(),
          _buildCategorySection(),
          _buildDateTimeSection(),
          _buildNoteSection(),
        ],
      ),
    );
  }

  void _focusOnAmount() {
    // Unfocus note field to show numeric keypad
    if (_noteFocusNode.hasFocus) {
      _noteFocusNode.unfocus();
    }
  }

  Widget _buildAmountSection() {
    return GestureDetector(
      onTap: _focusOnAmount,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 26),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          children: [
            Text(
              'NOMINAL',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                color: AppColors.neutral700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Rp',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  CurrencyFormatter.formatDigits(_amount),
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 44,
                  color: AppColors.accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
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
            children: _categories.map((cat) => CustomChip(
              label: cat,
              isSelected: cat == _selectedCategory,
              onTap: () => setState(() => _selectedCategory = cat),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: GestureDetector(
        onTap: _selectDateTime,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
      ),
    );
  }

  Widget _buildNoteSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
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
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: TextField(
              controller: _noteController,
              focusNode: _noteFocusNode,
              decoration: InputDecoration(
                hintText: widget.isIncome
                    ? 'Invoice, gaji, atau uang masuk lain'
                    : 'Warung, nasi campur',
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.neutral600,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 10),
              ),
              style: const TextStyle(fontSize: 14),
              textInputAction: TextInputAction.done,
              onEditingComplete: () {
                _noteFocusNode.unfocus();
              },
            ),
          ),
        ],
      ),
    );
  }
}
