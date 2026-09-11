import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/screens/auth_router.dart';
import '../../categories/screens/categories_screen.dart';
import '../../categories/screens/income_summary_screen.dart';
import '../../fund_sources/screens/fund_sources_screen.dart';
import '../../income_categories/screens/income_categories_screen.dart';
import '../../export/screens/export_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService.instance;
  final ImagePicker _picker = ImagePicker();

  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadProfileImage();
  }

  Future<void> _loadSettings() async {
    final enabled = await _authService.isBiometricsEnabled();
    final available = await _authService.isBiometricsAvailable();
    if (mounted) {
      setState(() {
        _biometricsEnabled = enabled;
        _biometricsAvailable = available;
      });
    }
  }

  Future<void> _loadProfileImage() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/profile.jpg');
    if (await file.exists()) {
      setState(() {
        _profileImage = file;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
            if (_profileImage != null)
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.accent800),
                title: Text(
                  'Hapus Foto',
                  style: TextStyle(color: AppColors.accent800),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final dir = await getApplicationDocumentsDirectory();
        final savedPath = '${dir.path}/profile.jpg';

        // Copy image to app directory
        await File(image.path).copy(savedPath);

        setState(() {
          _profileImage = File(savedPath);
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Foto profil disimpan')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
      }
    }
  }

  Future<void> _deleteImage() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/profile.jpg');
      if (await file.exists()) {
        await file.delete();
      }
      setState(() {
        _profileImage = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Foto profil dihapus')));
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    await _authService.setBiometricsEnabled(value);
    setState(() {
      _biometricsEnabled = value;
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun ini?'),
        content: const Text(
          'Catatan tetap tersimpan terenkripsi di ponsel. '
          'Anda perlu sidik jari atau PIN untuk masuk kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthRouter()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.accent800),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Keamanan'),
                    _buildBiometricsToggle(),
                    _buildMenuItem(
                      icon: Icons.lock_outline,
                      title: 'Ganti PIN',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fitur ganti PIN belum tersedia'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Analisis'),
                    _buildMenuItem(
                      icon: Icons.trending_down,
                      title: 'Pengeluaran per Kategori',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CategoriesScreen(),
                        ),
                      ),
                    ),
                    _buildMenuItem(
                      icon: Icons.trending_up,
                      title: 'Pemasukan per Kategori',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IncomeSummaryScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Master Data'),
                    _buildMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Sumber Dana',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FundSourcesScreen(),
                        ),
                      ),
                    ),
                    _buildMenuItem(
                      icon: Icons.label_outline,
                      title: 'Kategori Pemasukan',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IncomeCategoriesScreen(),
                        ),
                      ),
                    ),
                    _buildMenuItemStatic(
                      icon: Icons.attach_money,
                      title: 'Mata uang',
                      value: 'IDR · Rp',
                    ),
                    _buildMenuItem(
                      icon: Icons.upload_outlined,
                      title: 'Ekspor & cadangan',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ExportScreen()),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildLogoutButton(),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        'KASEP 1.1.0',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.neutral700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              '‹ Beranda',
              style: TextStyle(fontSize: 13, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pengaturan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return GestureDetector(
      onTap: _pickProfileImage,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent),
                image: _profileImage != null
                    ? DecorationImage(
                        image: FileImage(_profileImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _profileImage == null
                  ? const Center(
                      child: Icon(
                        Icons.person,
                        color: AppColors.accent700,
                        size: 28,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengguna',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _profileImage != null
                        ? 'Ketuk untuk ganti foto'
                        : 'Ketuk untuk tambah foto',
                    style: TextStyle(fontSize: 12, color: AppColors.neutral700),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.camera_alt_outlined,
              size: 20,
              color: AppColors.neutral500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.2,
          color: AppColors.neutral700,
        ),
      ),
    );
  }

  Widget _buildBiometricsToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.fingerprint, size: 20, color: AppColors.neutral700),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buka dengan biometrik',
                  style: TextStyle(fontSize: 14),
                ),
                if (!_biometricsAvailable)
                  Text(
                    'Tidak tersedia di perangkat ini',
                    style: TextStyle(fontSize: 11, color: AppColors.neutral600),
                  ),
              ],
            ),
          ),
          Switch(
            value: _biometricsEnabled,
            onChanged: _biometricsAvailable ? _toggleBiometrics : null,
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.neutral700),
            const SizedBox(width: 11),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
            Icon(Icons.chevron_right, size: 20, color: AppColors.neutral500),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemStatic({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.neutral700),
          const SizedBox(width: 11),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
          Text(
            value,
            style: TextStyle(fontSize: 13, color: AppColors.neutral700),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.negative.withOpacity(.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 17, color: AppColors.negative),
            const SizedBox(width: 9),
            Text(
              'Keluar',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.negative,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
