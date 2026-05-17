import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._internal();
  static final BiometricService instance = BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) {
      return false;
    }
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (kIsWeb) {
      return false;
    }
    try {
      return await _auth.authenticate(
        localizedReason: 'Gunakan biometrik untuk masuk',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint('Error during biometric authentication: $e');
      return false;
    }
  }

  Future<void> stopAuthentication() async {
    if (!kIsWeb) {
      await _auth.stopAuthentication();
    }
  }
}
