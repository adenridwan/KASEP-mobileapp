import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../features/home/screens/home_screen.dart';
import '../features/reports/screens/report_screen.dart';
import '../features/analysis/screens/analysis_screen.dart';
import '../features/export/screens/export_screen.dart';
import '../features/transactions/screens/add_transaction_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Keys to force rebuild screens when needed
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<ReportScreenState> _reportKey =
      GlobalKey<ReportScreenState>();
  final GlobalKey<AnalysisScreenState> _analysisKey =
      GlobalKey<AnalysisScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(key: _homeKey),
          ReportScreen(key: _reportKey),
          AnalysisScreen(key: _analysisKey),
          const ExportScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
      // Reload data when switching to these tabs
      if (index == 0) {
        _homeKey.currentState?.loadData();
      } else if (index == 1) {
        _reportKey.currentState?.loadData();
      } else if (index == 2) {
        _analysisKey.currentState?.loadData();
      }
    }
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.07),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              0,
              Icons.home_outlined,
              Icons.home_rounded,
              'Beranda',
            ),
            _buildNavItem(
              1,
              Icons.description_outlined,
              Icons.description_rounded,
              'Laporan',
            ),
            _buildAddButton(),
            _buildNavItem(
              2,
              Icons.insights_outlined,
              Icons.insights_rounded,
              'Analisis',
            ),
            _buildNavItem(
              3,
              Icons.ios_share_outlined,
              Icons.ios_share_rounded,
              'Ekspor',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() => GestureDetector(
    onTap: () async {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AddTransactionScreen(isIncome: false),
        ),
      );
      if (result == true) _homeKey.currentState?.loadData();
    },
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(.28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 25),
    ),
  );

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? AppColors.accent700 : AppColors.neutral600,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.1,
                color: isActive ? AppColors.accent700 : AppColors.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
