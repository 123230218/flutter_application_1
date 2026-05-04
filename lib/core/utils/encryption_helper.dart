import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class EncryptionHelper {
  static String generateSalt([int length = 16]) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt$password');
    final digest = sha256.convert(bytes).toString();
    return digest;
  }

  static String buildStoredPassword(String password) {
    final salt = generateSalt();
    final hash = hashPassword(password, salt);
    return '$salt:$hash';
  }

  static bool verifyPassword(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) {
      return false;
    }
    final salt = parts[0];
    final hash = parts[1];
    final check = hashPassword(password, salt);
    return check == hash;
  }
}
