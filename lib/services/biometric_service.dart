import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final BiometricService instance = BiometricService._();
  BiometricService._();
  final _auth = LocalAuthentication();

  // --- PIN Security ---
  Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('velo_pin_code');
    return pin != null && pin.length == 4;
  }

  Future<String?> getPinCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('velo_pin_code');
  }

  Future<void> setPinCode(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('velo_pin_code', pin);
  }

  Future<void> disableSecurity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('velo_pin_code');
    await prefs.remove('velo_biometric_lock');
  }

  // --- Biometric Security ---
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('velo_biometric_lock') ?? false;
  }

  Future<void> setBiometricEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('velo_biometric_lock', val);
  }

  Future<bool> canUseBiometrics() async {
    try {
      final isAvailable = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access Velo',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
