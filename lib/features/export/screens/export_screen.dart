import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/transaction_repository.dart';
import '../../../models/transaction.dart';
import '../../reports/screens/report_screen.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final TransactionRepository _repository = TransactionRepository.instance;
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');

  String _selectedFormat = 'PDF';
  bool _includeEntries = true;
  bool _includeCharts = false;
  bool _isLoading = true;
  bool _isExporting = false;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  int _totalIncome = 0;
  int _totalExpense = 0;
  int _transactionCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final income = await _repository.getTotalIncomeByMonth(_selectedYear, _selectedMonth);
    final expense = await _repository.getTotalExpensesByMonth(_selectedYear, _selectedMonth);
    final count = await _repository.getCountByMonth(_selectedYear, _selectedMonth);

    if (mounted) {
      setState(() {
        _totalIncome = income;
        _totalExpense = expense;
        _transactionCount = count;
        _isLoading = false;
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  Future<void> _shareReport() async {
    setState(() => _isExporting = true);

    try {
      final file = await _generateFile();
      if (file != null && mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Laporan Kas ${_getMonthName(_selectedMonth)} $_selectedYear',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat laporan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _saveToFiles() async {
    setState(() => _isExporting = true);

    try {
      final file = await _generateFile();
      if (file != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Disimpan ke: ${file.path}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.neutral900,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<File?> _generateFile() async {
    switch (_selectedFormat) {
      case 'PDF':
        return await _generatePdf();
      case 'CSV':
        return await _generateCsv();
      default:
        return await _generatePdf();
    }
  }

  Future<File> _generatePdf() async {
    final transactions = await _repository.getByMonth(_selectedYear, _selectedMonth);
    final pdf = pw.Document();

    final monthName = _getMonthName(_selectedMonth);
    final netAmount = _totalIncome - _totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'LAPORAN KAS',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '$monthName $_selectedYear',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              children: [
                _buildPdfSummaryRow('Kas Masuk', 'Rp ${_currencyFormat.format(_totalIncome)}'),
                pw.SizedBox(height: 8),
                _buildPdfSummaryRow('Kas Keluar', 'Rp ${_currencyFormat.format(_totalExpense)}'),
                pw.Divider(),
                _buildPdfSummaryRow(
                  'Bersih',
                  '${netAmount >= 0 ? '+' : ''}Rp ${_currencyFormat.format(netAmount)}',
                  bold: true,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          pw.Text(
            'Total $_transactionCount transaksi',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),

          // Transaction list
          if (_includeEntries && transactions.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            pw.Text(
              'DAFTAR TRANSAKSI',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildPdfTableHeader('Tanggal'),
                    _buildPdfTableHeader('Keterangan'),
                    _buildPdfTableHeader('Kategori'),
                    _buildPdfTableHeader('Jumlah'),
                  ],
                ),
                ...transactions.map((tx) => pw.TableRow(
                  children: [
                    _buildPdfTableCell(DateFormat('dd/MM/yyyy').format(tx.dateTime)),
                    _buildPdfTableCell(tx.title),
                    _buildPdfTableCell(tx.category),
                    _buildPdfTableCell(
                      '${tx.isIncome ? '+' : '-'}Rp ${_currencyFormat.format(tx.amount)}',
                      align: pw.TextAlign.right,
                    ),
                  ],
                )),
              ],
            ),
          ],

          pw.SizedBox(height: 40),
          pw.Center(
            child: pw.Text(
              'Dibuat dengan KASEP',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'Laporan_Kas_${monthName}_$_selectedYear.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildPdfSummaryRow(String label, String value, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 12, fontWeight: bold ? pw.FontWeight.bold : null)),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: bold ? pw.FontWeight.bold : null)),
      ],
    );
  }

  pw.Widget _buildPdfTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildPdfTableCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9), textAlign: align),
    );
  }

  Future<File> _generateCsv() async {
    final transactions = await _repository.getByMonth(_selectedYear, _selectedMonth);
    final monthName = _getMonthName(_selectedMonth);

    final buffer = StringBuffer();
    buffer.writeln('Laporan Kas - $monthName $_selectedYear');
    buffer.writeln('');
    buffer.writeln('RINGKASAN');
    buffer.writeln('Kas Masuk,Rp ${_currencyFormat.format(_totalIncome)}');
    buffer.writeln('Kas Keluar,Rp ${_currencyFormat.format(_totalExpense)}');
    buffer.writeln('Bersih,Rp ${_currencyFormat.format(_totalIncome - _totalExpense)}');
    buffer.writeln('');

    if (_includeEntries) {
      buffer.writeln('DAFTAR TRANSAKSI');
      buffer.writeln('Tanggal,Keterangan,Kategori,Tipe,Jumlah');
      for (final tx in transactions) {
        final date = DateFormat('dd/MM/yyyy').format(tx.dateTime);
        final desc = tx.title.replaceAll(',', ';'); // Escape commas
        buffer.writeln('$date,$desc,${tx.category},${tx.isIncome ? "Masuk" : "Keluar"},${tx.amount}');
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'Laporan_Kas_${monthName}_$_selectedYear.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    return file;
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Pilih Bulan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected = month == _selectedMonth && _selectedYear == DateTime.now().year;
                    return ListTile(
                      title: Text('${_getMonthName(month)} $_selectedYear'),
                      trailing: isSelected ? Icon(Icons.check, color: AppColors.accent) : null,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _selectedMonth = month);
                        _loadData();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPreviewCard(),
                    const SizedBox(height: 22),
                    _buildFormatSection(),
                    const SizedBox(height: 20),
                    _buildOptionsSection(),
                    const SizedBox(height: 24),
                    _buildShareButtons(),
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
              '‹ Pengaturan',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ekspor & Bagikan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    final netAmount = _totalIncome - _totalExpense;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReportScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.divider)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'LAPORAN KAS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.6,
                            color: AppColors.accent700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getMonthName(_selectedMonth)} $_selectedYear',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPreviewRow('Kas masuk', 'Rp ${_currencyFormat.format(_totalIncome)}'),
                  _buildPreviewRow('Kas keluar', 'Rp ${_currencyFormat.format(_totalExpense)}'),
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.divider)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bersih',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${netAmount >= 0 ? '+' : ''}Rp ${_currencyFormat.format(netAmount)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: netAmount >= 0 ? AppColors.accent700 : AppColors.accent800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_transactionCount transaksi',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: AppColors.neutral700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FORMAT',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: AppColors.neutral700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              _buildFormatTab('PDF'),
              _buildFormatTab('CSV'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormatTab(String format) {
    final isSelected = _selectedFormat == format;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFormat = format),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent100 : Colors.transparent,
            border: format != 'PDF'
                ? Border(left: BorderSide(color: AppColors.divider))
                : null,
          ),
          child: Center(
            child: Text(
              format,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.accent700 : AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PENGATURAN',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: AppColors.neutral700,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _showMonthPicker,
          child: _buildOptionRow(
            '${_getMonthName(_selectedMonth)} $_selectedYear',
            trailing: Icon(Icons.chevron_right, size: 20, color: AppColors.neutral600),
          ),
        ),
        _buildOptionRow(
          'Sertakan daftar transaksi',
          trailing: _buildSwitch(_includeEntries, (v) => setState(() => _includeEntries = v)),
        ),
      ],
    );
  }

  Widget _buildOptionRow(String label, {required Widget trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSwitch(bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 22,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: value ? AppColors.accent100 : Colors.transparent,
          border: Border.all(
            color: value ? AppColors.accent : AppColors.neutral400,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? AppColors.accent : AppColors.neutral400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareButtons() {
    return Column(
      children: [
        GestureDetector(
          onTap: _isExporting ? null : _shareReport,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.accent),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isExporting)
                  SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  )
                else
                  Icon(Icons.share, size: 17, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'Bagikan laporan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _isExporting ? null : _saveToFiles,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: Text(
                'Simpan ke Files',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
