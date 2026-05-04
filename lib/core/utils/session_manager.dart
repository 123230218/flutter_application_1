import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class SessionManager {
  static const String _boxName = 'session_box';
  static const String _keyToken = 'session_token';
  static const String _keyExpiry = 'session_expiry';
  static const String _keyUserId = 'session_user_id';

  final Uuid _uuid = const Uuid();

  Future<Box> _getBox() async {
    return await Hive.openBox(_boxName);
  }

  Future<String> createSession(int userId) async {
    final box = await _getBox();
    final token = _uuid.v4();
    final expiry = DateTime.now().add(const Duration(days: 7)).toIso8601String();
    
    await box.put(_keyToken, token);
    await box.put(_keyExpiry, expiry);
    await box.put(_keyUserId, userId);
    return token;
  }

  Future<void> clearSession() async {
    final box = await _getBox();
    await box.delete(_keyToken);
    await box.delete(_keyExpiry);
    await box.delete(_keyUserId);
  }

  Future<int?> getUserId() async {
    final box = await _getBox();
    return box.get(_keyUserId) as int?;
  }

  Future<bool> isSessionValid() async {
    final box = await _getBox();
    final expiryRaw = box.get(_keyExpiry) as String?;
    if (expiryRaw == null) {
      return false;
    }
    final expiry = DateTime.tryParse(expiryRaw);
    if (expiry == null) {
      return false;
    }
    return DateTime.now().isBefore(expiry);
  }
}
