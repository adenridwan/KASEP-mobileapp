import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../features/home/screens/home_screen.dart';
import '../features/reports/screens/report_screen.dart';
import '../features/analysis/screens/analysis_screen.dart';
import '../features/export/screens/export_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ReportScreen(),
    AnalysisScreen(),
    ExportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 34),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_outlined, Icons.home, 'Beranda'),
          _buildNavItem(1, Icons.description_outlined, Icons.description, 'Laporan'),
          _buildNavItem(2, Icons.bar_chart_outlined, Icons.bar_chart, 'Analisis'),
          _buildNavItem(3, Icons.upload_outlined, Icons.upload, 'Bagikan'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 21,
              color: isActive ? AppColors.accent700 : AppColors.neutral600,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.6,
                color: isActive ? AppColors.accent700 : AppColors.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
