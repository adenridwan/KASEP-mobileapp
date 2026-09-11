import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../navigation/main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService.instance;

  bool _isBioMode = true;
  String _pin = '';
  bool _pinError = false;
  bool _isScanning = false;
  bool _isRecognized = false;
  bool _biometricsEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final biometricsEnabled = await _authService.isBiometricsEnabled();
    final biometricsAvailable = await _authService.isBiometricsAvailable();

    if (mounted) {
      setState(() {
        _biometricsEnabled = biometricsEnabled && biometricsAvailable;
        _isBioMode = _biometricsEnabled;
        _isLoading = false;
      });

      // Auto-trigger biometrics on launch if enabled
      if (_biometricsEnabled) {
        Future.delayed(const Duration(milliseconds: 300), _scanBio);
      }
    }
  }

  void _scanBio() async {
    if (!_biometricsEnabled) return;

    setState(() {
      _isScanning = true;
    });

    final success = await _authService.authenticateWithBiometrics();

    if (!mounted) return;

    if (success) {
      setState(() {
        _isScanning = false;
        _isRecognized = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _navigateToHome();
      }
    } else {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _pressPin(String key) {
    if (key == 'del') {
      setState(() {
        _pin = _pin.isNotEmpty ? _pin.substring(0, _pin.length - 1) : '';
        _pinError = false;
      });
    } else if (_pin.length < 6) {
      setState(() {
        _pin += key;
        _pinError = false;
      });
    }

    if (_pin.length == 6) {
      Future.delayed(const Duration(milliseconds: 250), _verifyPin);
    }
  }

  Future<void> _verifyPin() async {
    final isValid = await _authService.verifyPin(_pin);

    if (!mounted) return;

    if (isValid) {
      _navigateToHome();
    } else {
      setState(() {
        _pin = '';
        _pinError = true;
      });
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isBioMode = !_isBioMode;
      _pin = '';
      _pinError = false;
      _isScanning = false;
      _isRecognized = false;
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    _buildHeader(),
                    const SizedBox(height: 30),
                    if (_isBioMode && _biometricsEnabled)
                      _buildBioAuth()
                    else
                      _buildPinAuth(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 26),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent),
            ),
            child: const Center(
              child: Text(
                'K',
                style: TextStyle(
                  color: AppColors.accent700,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'KASEP',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: AppColors.accent700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kas Sehat Personal',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Atur Arus, Sehatkan Kas.',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Selamat datang kembali',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioAuth() {
    Color ringColor = AppColors.neutral400;
    Color bgColor = Colors.transparent;
    String title = 'Sentuh untuk masuk';
    String hint =
        'Buka dengan sidik jari atau wajah — PIN tetap tersedia sebagai cadangan.';

    if (_isScanning) {
      ringColor = AppColors.accent600;
      bgColor = AppColors.accent100;
      title = 'Memindai…';
      hint = 'Tahan jari Anda pada sensor';
    } else if (_isRecognized) {
      ringColor = AppColors.accent;
      bgColor = AppColors.accent100;
      title = 'Dikenali';
      hint = 'Membuka buku kas…';
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        GestureDetector(
          // Allow tap even when scanning to retry biometric
          onTap: _isRecognized ? null : _scanBio,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: Border.all(color: ringColor),
              boxShadow: _isScanning
                  ? [
                      BoxShadow(
                        color: AppColors.accent100,
                        blurRadius: 0,
                        spreadRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.fingerprint,
              size: 52,
              color: ringColor,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.neutral700,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinAuth() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          'MASUKKAN PIN 6 ANGKA',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: AppColors.neutral700,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final isFilled = index < _pin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 7),
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pinError
                    ? Colors.transparent
                    : (isFilled ? AppColors.accent : Colors.transparent),
                border: Border.all(
                  color: _pinError
                      ? AppColors.accent800
                      : (isFilled ? AppColors.accent : AppColors.neutral400),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 20,
          child: Text(
            _pinError ? 'PIN salah, coba lagi' : ' ',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.accent800,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 22),
        _buildPinPad(),
      ],
    );
  }

  Widget _buildPinPad() {
    return SizedBox(
      width: 280,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map(_buildPinKey),
          const SizedBox(),
          _buildPinKey('0'),
          _buildPinKey('del', isDelete: true),
        ],
      ),
    );
  }

  Widget _buildPinKey(String key, {bool isDelete = false}) {
    return Material(
      color: isDelete ? Colors.transparent : AppColors.bg,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: () => _pressPin(key),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: isDelete ? null : Border.all(color: AppColors.divider),
          ),
          child: Center(
            child: isDelete
                ? Icon(Icons.backspace_outlined, color: AppColors.neutral700)
                : Text(
                    key,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
      child: Column(
        children: [
          if (_biometricsEnabled)
            GestureDetector(
              onTap: _toggleAuthMode,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Center(
                  child: Text(
                    _isBioMode ? 'Masuk dengan PIN' : 'Masuk dengan sidik jari',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          if (_biometricsEnabled) const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 12, color: AppColors.neutral700),
              const SizedBox(width: 8),
              Text(
                'Data kas tersimpan terenkripsi di ponsel ini',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
