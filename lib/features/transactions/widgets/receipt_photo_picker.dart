import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_colors.dart';

class ReceiptPhotoPicker extends StatelessWidget {
  final String? receiptPath;
  final ValueChanged<String?> onPhotoChanged;
  final String? transactionId;

  const ReceiptPhotoPicker({
    super.key,
    this.receiptPath,
    required this.onPhotoChanged,
    this.transactionId,
  });

  Future<void> _showOptions(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Foto Struk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Simpan bukti transaksi',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildOption(
                      context,
                      icon: Icons.camera_alt_outlined,
                      title: 'Ambil Foto',
                      subtitle: 'Gunakan kamera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(context, ImageSource.camera);
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildOption(
                      context,
                      icon: Icons.photo_library_outlined,
                      title: 'Pilih dari Galeri',
                      subtitle: 'Pilih foto yang ada',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(context, ImageSource.gallery);
                      },
                    ),
                    if (receiptPath != null) ...[
                      const SizedBox(height: 10),
                      _buildOption(
                        context,
                        icon: Icons.fullscreen,
                        title: 'Lihat Foto',
                        subtitle: 'Tampilan penuh',
                        onTap: () {
                          Navigator.pop(context);
                          _showFullImage(context);
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildOption(
                        context,
                        icon: Icons.delete_outline,
                        title: 'Hapus Foto',
                        subtitle: 'Hapus foto struk',
                        isDestructive: true,
                        onTap: () {
                          Navigator.pop(context);
                          _deletePhoto(context);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.negative.withValues(alpha:0.05)
              : AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive
                ? AppColors.negative.withValues(alpha:0.2)
                : AppColors.neutral300,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.negative.withValues(alpha:0.1)
                    : AppColors.accent.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive ? AppColors.negative : AppColors.accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? AppColors.negative : AppColors.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final dir = await getApplicationDocumentsDirectory();
        final receiptsDir = Directory('${dir.path}/receipts');
        if (!await receiptsDir.exists()) {
          await receiptsDir.create(recursive: true);
        }

        final fileName = 'receipt_${transactionId ?? DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = '${receiptsDir.path}/$fileName';

        // Delete old receipt if exists
        if (receiptPath != null) {
          final oldFile = File(receiptPath!);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        }

        // Copy new image
        await File(image.path).copy(savedPath);
        onPhotoChanged(savedPath);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Foto struk tersimpan'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.neutral900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    }
  }

  void _showFullImage(BuildContext context) {
    if (receiptPath == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImage(imagePath: receiptPath!),
      ),
    );
  }

  Future<void> _deletePhoto(BuildContext context) async {
    if (receiptPath == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Foto?'),
        content: const Text('Foto struk akan dihapus permanen.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.negative),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final file = File(receiptPath!);
        if (await file.exists()) {
          await file.delete();
        }
        onPhotoChanged(null);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Foto struk dihapus'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.neutral900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            ),
          );
        }
      } catch (e) {
        // Ignore delete errors
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = receiptPath != null && File(receiptPath!).existsSync();

    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(22, 8, 22, 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (hasPhoto)
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: FileImage(File(receiptPath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 22,
                  color: AppColors.accent,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPhoto ? 'Foto Struk' : 'Tambah Foto Struk',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    hasPhoto ? 'Ketuk untuk melihat atau ganti' : 'Simpan bukti transaksi',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasPhoto ? Icons.check_circle : Icons.add_circle_outline,
              size: 22,
              color: hasPhoto ? AppColors.accent : AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String imagePath;

  const _FullScreenImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Foto Struk'),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
