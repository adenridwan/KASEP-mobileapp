import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/storage/fund_source_repository.dart';
import '../../../core/storage/transaction_repository.dart';
import '../../../models/fund_source.dart';
import '../../transactions/widgets/numeric_keypad.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  List<Map<String, dynamic>> _sourcesWithBalances = [];
  FundSource? _fromSource;
  FundSource? _toSource;
  int _fromBalance = 0;
  String _amount = '';
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  bool _isNoteFieldFocused = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSources();
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

  Future<void> _loadSources() async {
    final sourcesWithBalances = await FundSourceRepository.instance.getAllWithBalances();
    if (mounted) {
      setState(() {
        _sourcesWithBalances = sourcesWithBalances;
        if (sourcesWithBalances.isNotEmpty) {
          _fromSource = sourcesWithBalances[0]['source'] as FundSource;
          _fromBalance = sourcesWithBalances[0]['balance'] as int;
          if (sourcesWithBalances.length > 1) {
            _toSource = sourcesWithBalances[1]['source'] as FundSource;
          }
        }
      });
    }
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
    if (_fromSource == null || _toSource == null) return;
    if (_amount.isEmpty) return;

    final amount = int.tryParse(_amount) ?? 0;
    if (amount <= 0) return;

    if (_fromSource!.id == _toSource!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sumber dan tujuan tidak boleh sama'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await TransactionRepository.instance.createTransfer(
        fromSourceId: _fromSource!.id,
        fromSourceName: _fromSource!.name,
        toSourceId: _toSource!.id,
        toSourceName: _toSource!.name,
        amount: amount,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transfer Rp ${CurrencyFormatter.formatDigits(_amount)} ke ${_toSource!.name}',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.neutral900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal transfer: $e'),
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

  void _swapSources() {
    if (_fromSource == null || _toSource == null) return;

    final tempSource = _fromSource;

    // Find balance for new from source
    final newFromBalance = _sourcesWithBalances
        .firstWhere((s) => (s['source'] as FundSource).id == _toSource!.id)['balance'] as int;

    setState(() {
      _fromSource = _toSource;
      _fromBalance = newFromBalance;
      _toSource = tempSource;
    });
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
          const Text(
            'TRANSFER',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          GestureDetector(
            onTap: _amount.isNotEmpty ? _save : null,
            child: Text(
              'Kirim',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
          _buildSourceSelectors(),
          _buildNoteSection(),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 26),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          Text(
            'NOMINAL TRANSFER',
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
    );
  }

  Widget _buildSourceSelectors() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Column(
        children: [
          // From source
          _buildSourceSelector(
            label: 'DARI',
            source: _fromSource,
            balance: _fromBalance,
            onTap: () => _showSourcePicker(isFrom: true),
          ),
          const SizedBox(height: 8),
          // Swap button
          GestureDetector(
            onTap: _swapSources,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
              child: Icon(
                Icons.swap_vert,
                size: 20,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // To source
          _buildSourceSelector(
            label: 'KE',
            source: _toSource,
            balance: null,
            onTap: () => _showSourcePicker(isFrom: false),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceSelector({
    required String label,
    required FundSource? source,
    required int? balance,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                color: AppColors.neutral700,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source?.name ?? 'Pilih sumber',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: source != null ? null : AppColors.neutral600,
                    ),
                  ),
                  if (balance != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Saldo: Rp ${_formatCurrency(balance)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: AppColors.neutral500),
          ],
        ),
      ),
    );
  }

  void _showSourcePicker({required bool isFrom}) {
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
              isFrom ? 'Pilih Sumber' : 'Pilih Tujuan',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ..._sourcesWithBalances.map((item) {
              final source = item['source'] as FundSource;
              final balance = item['balance'] as int;
              final isSelected = isFrom
                  ? _fromSource?.id == source.id
                  : _toSource?.id == source.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isFrom) {
                      _fromSource = source;
                      _fromBalance = balance;
                    } else {
                      _toSource = source;
                    }
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              source.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? AppColors.accent : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Saldo: Rp ${_formatCurrency(balance)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.neutral600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check, size: 20, color: AppColors.accent),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATATAN (OPSIONAL)',
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
                hintText: 'Alasan transfer',
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
