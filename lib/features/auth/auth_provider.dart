import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../core/services/database_service.dart';
import '../../core/utils/encryption_helper.dart';
import '../../core/utils/notification_helper.dart';
import '../../core/utils/session_manager.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.sessionManager}) {
    _init();
  }

  final SessionManager sessionManager;

  bool isLoading = true;
  bool isLoggedIn = false;
  int? userId;

  Future<void> _init() async {
    // Selalu paksa logout setiap kali aplikasi baru dibuka (proses dimulai ulang)
    await sessionManager.clearSession();
    isLoggedIn = false;
    userId = null;
    isLoading = false;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    final user = await DatabaseService.instance.getUserByEmail(email);
    if (user == null) {
      return 'Email tidak ditemukan.';
    }

    final stored = user['password_hash'] as String;
    final isMatch = EncryptionHelper.verifyPassword(password, stored);
    if (!isMatch) {
      return 'Password salah.';
    }

    final id = user['id'] as int;
    await sessionManager.createSession(id);
    
    userId = id;
    isLoggedIn = true;
    
    // Simpan email ke cache secara asinkron agar tidak menghambat navigasi
    _saveLastEmail(email);
    
    await NotificationHelper.scheduleSessionReminder(
      DateTime.now().add(const Duration(days: 7)),
    );

    notifyListeners();
    return null;
  }

  Future<void> _saveLastEmail(String email) async {
    try {
      final box = await Hive.openBox('auth_cache');
      await box.put('last_email', email);
    } catch (e) {
      debugPrint('Error saving last email: $e');
    }
  }

  Future<String?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final existing = await DatabaseService.instance.getUserByEmail(email);
    if (existing != null) {
      return 'Email sudah terdaftar.';
    }

    final salt = EncryptionHelper.generateSalt();
    final hash = EncryptionHelper.hashPassword(password, salt);
    final stored = '$salt:$hash';

    await DatabaseService.instance.createUser(
      username: username,
      email: email,
      passwordHash: stored,
      salt: salt,
    );
    return null;
  }

  Future<void> logout() async {
    await sessionManager.clearSession();
    isLoggedIn = false;
    userId = null;
    notifyListeners();
  }

  Future<String?> getLastEmail() async {
    final box = await Hive.openBox('auth_cache');
    return box.get('last_email') as String?;
  }

  Future<String?> loginWithBiometric(String email) async {
    final user = await DatabaseService.instance.getUserByEmail(email);
    if (user == null) {
      return 'User tidak ditemukan.';
    }

    final id = user['id'] as int;
    await sessionManager.createSession(id);
    userId = id;
    isLoggedIn = true;
    await NotificationHelper.scheduleSessionReminder(
      DateTime.now().add(const Duration(days: 7)),
    );
    notifyListeners();
    return null;
  }
}
