import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) {
      return false;
    }
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    return canCheck && isSupported;
  }

  Future<bool> authenticate() async {
    if (kIsWeb) {
      return false;
    }
    return _auth.authenticate(
      localizedReason: 'Gunakan biometrik untuk masuk',
      options: const AuthenticationOptions(biometricOnly: true),
    );
  }
}
