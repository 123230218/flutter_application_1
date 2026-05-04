import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;
  final bool _isWeb = kIsWeb;
  final List<Map<String, Object?>> _users = [];
  final List<Map<String, Object?>> _feedback = [];
  final List<Map<String, Object?>> _quizScores = [];
  final List<Map<String, Object?>> _favorites = [];
  int _userAutoId = 1;
  int _feedbackAutoId = 1;
  int _scoreAutoId = 1;
  int _favoriteAutoId = 1;

  Future<void> initialize() async {
    if (_isWeb) {
      await Hive.initFlutter();
      await Hive.openBox('saved_builds');
      return;
    }
    final dbPath = await getDatabasesPath();
    final filePath = path.join(dbPath, 'pc_builder.db');
    _db = await openDatabase(
      filePath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            email TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            salt TEXT NOT NULL,
            profile_image TEXT,
            biometric_enabled INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE parts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            name TEXT NOT NULL,
            brand TEXT,
            price REAL,
            benchmark REAL,
            specs TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE builds (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            parts TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE build_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            build_id INTEGER NOT NULL,
            part_id INTEGER NOT NULL,
            quantity INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            part_id INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE feedback (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            message TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE quiz_scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            score INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE builds ADD COLUMN parts TEXT');
        }
      },
    );
  }

  Database get db {
    if (_isWeb) {
      throw StateError('Database SQLite tidak tersedia di web');
    }
    if (_db == null) {
      throw StateError('Database belum diinisialisasi');
    }
    return _db!;
  }

  Future<int> createUser({
    required String username,
    required String email,
    required String passwordHash,
    required String salt,
  }) async {
    if (_isWeb) {
      final id = _userAutoId++;
      _users.add({
        'id': id,
        'username': username,
        'email': email,
        'password_hash': passwordHash,
        'salt': salt,
        'profile_image': null,
        'created_at': DateTime.now().toIso8601String(),
      });
      return id;
    }
    return db.insert('users', {
      'username': username,
      'email': email,
      'password_hash': passwordHash,
      'salt': salt,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, Object?>?> getUserByEmail(String email) async {
    if (_isWeb) {
      try {
        return _users.firstWhere((user) => user['email'] == email);
      } catch (_) {
        return null;
      }
    }
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (result.isEmpty) {
      return null;
    }
    return result.first;
  }

  Future<Map<String, Object?>?> getUserById(int id) async {
    if (_isWeb) {
      try {
        return _users.firstWhere((user) => user['id'] == id);
      } catch (_) {
        return null;
      }
    }
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) {
      return null;
    }
    return result.first;
  }

  Future<void> updateProfileImage(int userId, String path) async {
    if (_isWeb) {
      final index = _users.indexWhere((user) => user['id'] == userId);
      if (index != -1) {
        _users[index]['profile_image'] = path;
      }
      return;
    }
    await db.update('users', {'profile_image': path}, where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> updateBiometricStatus(int userId, bool enabled) async {
    if (_isWeb) {
      final index = _users.indexWhere((user) => user['id'] == userId);
      if (index != -1) {
        _users[index] = Map<String, Object?>.from(_users[index])..['biometric_enabled'] = enabled ? 1 : 0;
      }
      return;
    }
    await db.update('users', {'biometric_enabled': enabled ? 1 : 0}, where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> updateUsername(int userId, String username) async {
    if (_isWeb) {
      final index = _users.indexWhere((user) => user['id'] == userId);
      if (index != -1) {
        _users[index] = Map<String, Object?>.from(_users[index])..['username'] = username;
      }
      return;
    }
    await db.update('users', {'username': username}, where: 'id = ?', whereArgs: [userId]);
  }

  Future<int> createFeedback(int userId, String message) async {
    if (_isWeb) {
      final id = _feedbackAutoId++;
      _feedback.add({
        'id': id,
        'user_id': userId,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });
      return id;
    }
    return db.insert('feedback', {
      'user_id': userId,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> saveQuizScore(int userId, int score) async {
    if (_isWeb) {
      final id = _scoreAutoId++;
      _quizScores.add({
        'id': id,
        'user_id': userId,
        'score': score,
        'created_at': DateTime.now().toIso8601String(),
      });
      return id;
    }
    return db.insert('quiz_scores', {
      'user_id': userId,
      'score': score,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> addFavorite(int userId, int partId) async {
    if (_isWeb) {
      final id = _favoriteAutoId++;
      _favorites.add({
        'id': id,
        'user_id': userId,
        'part_id': partId,
      });
      return id;
    }
    return db.insert('favorites', {
      'user_id': userId,
      'part_id': partId,
    });
  }

  Future<List<Map<String, Object?>>> getTopScores() async {
    if (_isWeb) {
      final sorted = List<Map<String, Object?>>.from(_quizScores);
      sorted.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      return sorted.take(5).toList();
    }
    return db.query('quiz_scores', orderBy: 'score DESC', limit: 5);
  }

  Future<int> saveBuild(int userId, String name, Map<String, dynamic> parts) async {
    final timestamp = DateTime.now().toIso8601String();
    
    if (_isWeb) {
      final box = Hive.box('saved_builds');
      final id = box.length + 1;
      final buildData = {
        'id': id,
        'user_id': userId,
        'name': name,
        'parts': parts,
        'created_at': timestamp,
      };
      await box.put(id.toString(), buildData);
      return id;
    }

    final buildId = await db.insert('builds', {
      'user_id': userId,
      'name': name,
      'parts': jsonEncode(parts),
      'created_at': timestamp,
    });

    return buildId;
  }

  Future<List<Map<String, dynamic>>> getSavedBuilds(int userId) async {
    if (_isWeb) {
      final box = Hive.box('saved_builds');
      return box.values
          .where((b) => b['user_id'] == userId)
          .map((b) => Map<String, dynamic>.from(b as Map))
          .toList();
    }
    
    final builds = await db.query('builds', where: 'user_id = ?', whereArgs: [userId]);
    return builds.map((b) => Map<String, dynamic>.from(b)).toList();
  }

  Future<void> deleteBuild(int buildId) async {
    if (_isWeb) {
      final box = Hive.box('saved_builds');
      await box.delete(buildId.toString());
      return;
    }
    
    await db.delete('build_items', where: 'build_id = ?', whereArgs: [buildId]);
    await db.delete('builds', where: 'id = ?', whereArgs: [buildId]);
  }
}
