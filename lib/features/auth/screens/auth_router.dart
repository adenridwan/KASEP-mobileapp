import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import 'login_screen.dart';
import 'pin_setup_screen.dart';

class AuthRouter extends StatefulWidget {
  const AuthRouter({super.key});

  @override
  State<AuthRouter> createState() => _AuthRouterState();
}

class _AuthRouterState extends State<AuthRouter> {
  final AuthService _authService = AuthService.instance;
  bool _isLoading = true;
  bool _isPinSet = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final isPinSet = await _authService.isPinSet();
    if (mounted) {
      setState(() {
        _isPinSet = isPinSet;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isPinSet) {
      return const LoginScreen();
    } else {
      return const PinSetupScreen();
    }
  }
}
