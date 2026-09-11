import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/fund_source_repository.dart';
import '../../../models/fund_source.dart';

class AddFundSourceScreen extends StatefulWidget {
  const AddFundSourceScreen({super.key});

  @override
  State<AddFundSourceScreen> createState() => _AddFundSourceScreenState();
}

class _AddFundSourceScreenState extends State<AddFundSourceScreen> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nama sumber dana harus diisi'),
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
      final now = DateTime.now();
      final source = FundSource(
        id: 'fs_${now.millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        initialBalance: int.tryParse(_balanceController.text) ?? 0,
        createdAt: now,
      );

      await FundSourceRepository.instance.create(source);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sumber dana "${source.name}" ditambahkan'),
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildForm()),
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
            'TAMBAH SUMBER DANA',
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
                color: _nameController.text.isNotEmpty
                    ? AppColors.accent
                    : AppColors.neutral400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NAMA SUMBER DANA',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Contoh: Gaji, Freelance, Tabungan',
              hintStyle: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.neutral600,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.accent),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Text(
            'SALDO AWAL (OPSIONAL)',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _balanceController,
            decoration: InputDecoration(
              prefixText: 'Rp ',
              prefixStyle: TextStyle(
                fontSize: 14,
                color: AppColors.neutral700,
              ),
              hintText: '0',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.accent),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: AppColors.accent100,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.accent700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saldo awal adalah jumlah uang yang sudah ada di sumber ini sebelum mulai dicatat di aplikasi.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.accent700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
