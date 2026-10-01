import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/storage/monthly_note_repository.dart';
import '../../../core/storage/transaction_repository.dart';
import '../../../models/monthly_note.dart';

class MonthlyNotesScreen extends StatefulWidget {
  final int? initialYear;
  final int? initialMonth;

  const MonthlyNotesScreen({
    super.key,
    this.initialYear,
    this.initialMonth,
  });

  @override
  State<MonthlyNotesScreen> createState() => _MonthlyNotesScreenState();
}

class _MonthlyNotesScreenState extends State<MonthlyNotesScreen> {
  late DateTime _selectedMonth;
  final TextEditingController _contentController = TextEditingController();
  MonthlyNote? _currentNote;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  Timer? _autoSaveTimer;

  // Monthly summary data
  int _totalIncome = 0;
  int _totalExpenses = 0;
  int _transactionCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(
      widget.initialYear ?? DateTime.now().year,
      widget.initialMonth ?? DateTime.now().month,
    );
    _loadData();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    if (_hasChanges) {
      _saveNote();
    }
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final note = await MonthlyNoteRepository.instance.getByMonth(
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
    final count = await TransactionRepository.instance.getCountByMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    if (mounted) {
      setState(() {
        _currentNote = note;
        _contentController.text = note?.content ?? '';
        _totalIncome = totalIncome;
        _totalExpenses = totalExpenses;
        _transactionCount = count;
        _isLoading = false;
        _hasChanges = false;
      });
    }
  }

  void _onContentChanged(String value) {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }

    // Debounce auto-save
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _saveNote();
    });
  }

  Future<void> _saveNote() async {
    if (!_hasChanges || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final note = await MonthlyNoteRepository.instance.createOrUpdate(
        _selectedMonth.year,
        _selectedMonth.month,
        _contentController.text,
      );

      if (mounted) {
        setState(() {
          _currentNote = note;
          _hasChanges = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    }
  }

  void _changeMonth(int delta) {
    // Save current note before changing month
    if (_hasChanges) {
      _saveNote();
    }

    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
    _loadData();
  }

  String get _formattedMonth {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
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
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row with back button and title
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (_hasChanges) {
                    _saveNote();
                  }
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: AppColors.neutral700,
                  ),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    if (_isSaving)
                      Text(
                        'Menyimpan...',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.accent,
                        ),
                      )
                    else if (_hasChanges)
                      Text(
                        'Belum disimpan',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.accent2,
                        ),
                      )
                    else if (_currentNote != null)
                      Text(
                        'Tersimpan',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.neutral500,
                        ),
                      ),
                  ],
                ),
              ),
              if (_hasChanges)
                GestureDetector(
                  onTap: _saveNote,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
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
          const SizedBox(height: 14),
          // Month selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _changeMonth(-1),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chevron_left,
                    size: 20,
                    color: AppColors.neutral700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent, AppColors.accent500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha:0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  _formattedMonth,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _changeMonth(1),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.neutral700,
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
          _buildMonthlySummary(),
          const SizedBox(height: 20),
          _buildNoteEditor(),
          const SizedBox(height: 20),
          _buildPrompts(),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary() {
    final netBalance = _totalIncome - _totalExpenses;
    final isPositive = netBalance >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFFE8F5F1), const Color(0xFFD4EDE5)]
              : [const Color(0xFFFDF2F2), const Color(0xFFFCE8E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPositive
              ? AppColors.accent.withValues(alpha:0.2)
              : AppColors.negative.withValues(alpha:0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                size: 18,
                color: isPositive ? AppColors.accent700 : AppColors.negative,
              ),
              const SizedBox(width: 8),
              Text(
                'Ringkasan Bulan Ini',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? AppColors.accent700 : AppColors.negative,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Pemasukan',
                  _formatCurrency(_totalIncome),
                  AppColors.accent700,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.divider,
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Pengeluaran',
                  _formatCurrency(_totalExpenses),
                  AppColors.neutral700,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.divider,
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Bersih',
                  '${isPositive ? '+' : '-'}${_formatCurrency(netBalance.abs())}',
                  isPositive ? AppColors.accent700 : AppColors.negative,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              '$_transactionCount transaksi tercatat',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.neutral600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.neutral600,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteEditor() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note,
                  size: 20,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Catatan & Refleksi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.divider, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _contentController,
              onChanged: _onContentChanged,
              maxLines: null,
              minLines: 8,
              decoration: InputDecoration(
                hintText: 'Tulis catatan keuangan bulan ini...\n\nContoh:\n- Pengeluaran terbesar: ...\n- Target bulan depan: ...\n- Hal yang perlu diperbaiki: ...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral400,
                  height: 1.6,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.text,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrompts() {
    final prompts = [
      'Apa pengeluaran terbesar bulan ini?',
      'Apakah target keuangan tercapai?',
      'Apa yang bisa diperbaiki bulan depan?',
      'Ada pengeluaran tak terduga?',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IDE UNTUK DITULIS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.neutral600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: prompts.map((prompt) {
            return GestureDetector(
              onTap: () {
                // Insert prompt as template if editor is empty
                if (_contentController.text.isEmpty) {
                  _contentController.text = '$prompt\n\n';
                  _onContentChanged(_contentController.text);
                } else {
                  // Append to existing content
                  _contentController.text += '\n\n$prompt\n';
                  _onContentChanged(_contentController.text);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neutral300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 14,
                      color: AppColors.accent2,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        prompt,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
