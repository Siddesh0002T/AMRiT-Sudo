import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/db/database_helper.dart';
import '../models/teacher.dart';

class AuthService extends ChangeNotifier {
  static const String _keyIsLoggedIn = 'is_teacher_logged_in';
  static const String _keyCurrentUsername = 'current_teacher_username';
  static const String _keyCurrentName = 'current_teacher_name';

  Teacher? _currentTeacher;
  Teacher? get currentTeacher => _currentTeacher;

  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(salt + password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> signup({
    required String username,
    required String password,
    required String name,
  }) async {
    final db = await DatabaseHelper.instance.database;

    // Check existing
    final existing = await db.query(
      'teachers',
      where: 'username = ?',
      whereArgs: [username.trim().toLowerCase()],
    );

    if (existing.isNotEmpty) {
      throw Exception('Username already exists');
    }

    final salt = _generateSalt();
    final passwordHash = _hashPassword(password, salt);

    final teacher = Teacher(
      username: username.trim().toLowerCase(),
      passwordHash: passwordHash,
      salt: salt,
      name: name.trim(),
    );

    final id = await db.insert('teachers', teacher.toMap());
    _currentTeacher = Teacher(
      id: id,
      username: teacher.username,
      passwordHash: teacher.passwordHash,
      salt: teacher.salt,
      name: teacher.name,
    );

    await _persistSession(_currentTeacher!);
    return true;
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final results = await db.query(
      'teachers',
      where: 'username = ?',
      whereArgs: [username.trim().toLowerCase()],
    );

    if (results.isEmpty) {
      throw Exception('Invalid username or password');
    }

    final teacherMap = results.first;
    final storedSalt = teacherMap['salt'] as String;
    final storedHash = teacherMap['password_hash'] as String;

    final computedHash = _hashPassword(password, storedSalt);
    if (computedHash != storedHash) {
      throw Exception('Invalid username or password');
    }

    _currentTeacher = Teacher.fromMap(teacherMap);
    await _persistSession(_currentTeacher!);
    return true;
  }

  Future<void> _persistSession(Teacher teacher) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyCurrentUsername, teacher.username);
    await prefs.setString(_keyCurrentName, teacher.name);
  }

  Future<bool> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return false;

    final username = prefs.getString(_keyCurrentUsername);
    if (username == null) return false;

    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'teachers',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (results.isNotEmpty) {
      _currentTeacher = Teacher.fromMap(results.first);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyCurrentUsername);
    await prefs.remove(_keyCurrentName);
    _currentTeacher = null;
  }
}
