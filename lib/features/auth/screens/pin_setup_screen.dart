import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../navigation/main_navigation.dart';

enum PinSetupStep { enter, confirm, biometrics }

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final AuthService _authService = AuthService.instance;

  PinSetupStep _step = PinSetupStep.enter;
  String _pin = '';
  String _firstPin = '';
  bool _pinError = false;
  bool _biometricsAvailable = false;
  bool _isSettingUp = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await _authService.isBiometricsAvailable();
    if (mounted) {
      setState(() {
        _biometricsAvailable = available;
      });
    }
  }

  void _pressPin(String key) {
    if (_isSettingUp || _isProcessing) return;

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

      // Check after adding digit
      if (_pin.length == 6) {
        _isProcessing = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          _handlePinComplete();
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        });
      }
    }
  }

  void _handlePinComplete() {
    if (!mounted || _pin.length != 6) return;

    if (_step == PinSetupStep.enter) {
      final pinToSave = _pin;
      setState(() {
        _firstPin = pinToSave;
        _pin = '';
        _step = PinSetupStep.confirm;
      });
    } else if (_step == PinSetupStep.confirm) {
      if (_pin == _firstPin) {
        if (_biometricsAvailable) {
          _showBiometricsDialog();
        } else {
          _finishSetup(enableBiometrics: false);
        }
      } else {
        setState(() {
          _pin = '';
          _pinError = true;
        });
      }
    }
  }

  Future<void> _finishSetup({required bool enableBiometrics}) async {
    setState(() {
      _isSettingUp = true;
    });

    await _authService.setPin(_firstPin);
    await _authService.setBiometricsEnabled(enableBiometrics);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  void _showBiometricsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Aktifkan Sidik Jari?'),
        content: const Text(
          'Gunakan sidik jari atau wajah untuk masuk lebih cepat. '
          'PIN tetap tersedia sebagai cadangan.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _finishSetup(enableBiometrics: false);
            },
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _finishSetup(enableBiometrics: true);
            },
            child: const Text('Aktifkan'),
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
                    _buildPinSection(),
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
          Text(
            'KASEP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.2,
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Buat PIN Keamanan',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'PIN digunakan untuk melindungi data keuangan Anda',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.neutral700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinSection() {
    final title = _step == PinSetupStep.enter
        ? 'MASUKKAN PIN 6 ANGKA'
        : 'KONFIRMASI PIN ANDA';

    final hint = _step == PinSetupStep.enter
        ? 'Pilih PIN yang mudah diingat'
        : (_pinError ? 'PIN tidak cocok, coba lagi' : 'Masukkan PIN yang sama');

    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          title,
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
            hint,
            style: TextStyle(
              fontSize: 12,
              color: _pinError ? AppColors.accent800 : AppColors.neutral700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 22),
        _buildPinPad(),
        if (_isSettingUp)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: CircularProgressIndicator(),
          ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 12, color: AppColors.neutral700),
          const SizedBox(width: 8),
          Text(
            'PIN disimpan terenkripsi di ponsel ini',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.neutral700,
            ),
          ),
        ],
      ),
    );
  }
}
