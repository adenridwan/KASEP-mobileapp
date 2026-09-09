import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/transaction_repository.dart';

class BalanceChart extends StatefulWidget {
  final int year;
  final int month;

  const BalanceChart({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  State<BalanceChart> createState() => _BalanceChartState();
}

class _BalanceChartState extends State<BalanceChart> {
  List<Map<String, dynamic>> _balanceData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(BalanceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year || oldWidget.month != widget.month) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final data = await TransactionRepository.instance.getDailyRunningBalanceForMonth(
      widget.year,
      widget.month,
    );

    if (mounted) {
      setState(() {
        _balanceData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 84,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_balanceData.isEmpty || _balanceData.every((d) => d['balance'] == 0)) {
      return SizedBox(
        height: 84,
        child: Center(
          child: Text(
            'Belum ada data',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.neutral600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 84,
      child: CustomPaint(
        size: Size(MediaQuery.of(context).size.width - 44, 84),
        painter: _BalanceChartPainter(_balanceData),
      ),
    );
  }
}

class _BalanceChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  _BalanceChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;

    final chartHeight = size.height - 14;

    // Base line
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      linePaint,
    );

    if (data.isEmpty) return;

    // Find min and max balance for scaling
    int minBalance = 0;
    int maxBalance = 0;
    for (final d in data) {
      final balance = d['balance'] as int;
      if (balance < minBalance) minBalance = balance;
      if (balance > maxBalance) maxBalance = balance;
    }

    // Add padding to range
    final range = maxBalance - minBalance;
    if (range == 0) return;

    // Chart line
    final chartPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final path = Path();
    final dayWidth = size.width / (data.length - 1).clamp(1, data.length);

    for (var i = 0; i < data.length; i++) {
      final balance = data[i]['balance'] as int;
      final x = i * dayWidth;
      // Invert Y (higher balance = higher on screen = lower Y value)
      final y = chartHeight - ((balance - minBalance) / range * (chartHeight - 10)).clamp(5, chartHeight - 5);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, chartPaint);

    // End dot
    if (data.isNotEmpty) {
      final lastBalance = data.last['balance'] as int;
      final lastY = chartHeight - ((lastBalance - minBalance) / range * (chartHeight - 10)).clamp(5, chartHeight - 5);

      final dotPaint = Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width, lastY), 2.6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BalanceChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
