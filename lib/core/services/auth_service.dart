import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  static final AuthService instance = AuthService._init();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _pinHashKey = 'pin_hash';
  static const String _biometricsEnabledKey = 'biometrics_enabled';

  AuthService._init();

  /// Hash PIN using SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if user has set a PIN (first launch detection)
  Future<bool> isPinSet() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Hash and store PIN securely
  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _storage.write(key: _pinHashKey, value: hash);
  }

  /// Verify entered PIN against stored hash
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _pinHashKey);
    if (storedHash == null) return false;

    final inputHash = _hashPin(pin);
    return storedHash == inputHash;
  }

  /// Check if device supports fingerprint/face
  Future<bool> isBiometricsAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if user enabled biometrics
  Future<bool> isBiometricsEnabled() async {
    final value = await _storage.read(key: _biometricsEnabledKey);
    return value == 'true';
  }

  /// Save user preference for biometrics
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _biometricsEnabledKey, value: enabled.toString());
  }

  /// Perform actual biometric authentication
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Verifikasi identitas untuk membuka KASEP',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Clear all auth data (for testing/reset)
  Future<void> clearAll() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _biometricsEnabledKey);
  }
}
