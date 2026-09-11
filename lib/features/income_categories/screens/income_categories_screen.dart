import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/income_category_repository.dart';
import '../../../models/income_category.dart';

class IncomeCategoriesScreen extends StatefulWidget {
  const IncomeCategoriesScreen({super.key});

  @override
  State<IncomeCategoriesScreen> createState() => _IncomeCategoriesScreenState();
}

class _IncomeCategoriesScreenState extends State<IncomeCategoriesScreen> {
  List<IncomeCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final categories = await IncomeCategoryRepository.instance.getAll();
    if (mounted) {
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
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
              '< Kembali',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.accent,
              ),
            ),
          ),
          const Text(
            'KATEGORI PEMASUKAN',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          GestureDetector(
            onTap: _showAddDialog,
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
          Text(
            'Kategori pemasukan digunakan untuk mengelompokkan jenis pendapatan Anda.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.neutral700,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'DAFTAR KATEGORI',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 12),
          if (_categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Belum ada kategori',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...List.generate(_categories.length, (index) {
              return _buildCategoryRow(_categories[index]);
            }),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(IncomeCategory category) {
    return GestureDetector(
      onTap: () => _showCategoryOptions(category),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: AppColors.neutral500),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Kategori'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nama kategori',
            hintText: 'Contoh: Tabungan 1, Uang Jaja',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
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
                final id = await IncomeCategoryRepository.instance.generateId();
                await IncomeCategoryRepository.instance.create(
                  IncomeCategory(
                    id: id,
                    name: controller.text.trim(),
                    createdAt: DateTime.now(),
                  ),
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

  void _showCategoryOptions(IncomeCategory category) {
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
              category.name,
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
                _editCategoryName(category);
              },
            ),
            _buildOptionItem(
              icon: Icons.delete_outline,
              label: 'Hapus',
              color: AppColors.accent800,
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(category);
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

  void _editCategoryName(IncomeCategory category) {
    final controller = TextEditingController(text: category.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nama kategori',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
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
                await IncomeCategoryRepository.instance.update(
                  category.copyWith(name: controller.text.trim()),
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

  void _confirmDelete(IncomeCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: Text(
          'Kategori "${category.name}" akan dihapus. '
          'Transaksi yang menggunakan kategori ini tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              await IncomeCategoryRepository.instance.deactivate(category.id);
              nav.pop();
              _loadData();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.accent800),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
