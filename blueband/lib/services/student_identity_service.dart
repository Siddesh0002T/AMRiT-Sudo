import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentIdentityService extends ChangeNotifier {
  static const String _keyRollNumber = 'student_roll_number';
  static const String _keyName = 'student_name';
  static const String _keySection = 'student_section';
  static const String _keyEmail = 'student_email';
  static const String _keyPhone = 'student_phone';
  static const String _keyIsLoggedIn = 'student_is_logged_in';

  String _rollNumber = '23CE045';
  String get rollNumber => _rollNumber;

  String _name = 'Aditi Sharma';
  String get name => _name;

  String _section = 'CS-A';
  String get section => _section;

  String _email = '';
  String get email => _email;

  String _phone = '';
  String get phone => _phone;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> loadIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    _rollNumber = prefs.getString(_keyRollNumber) ?? '23CE045';
    _name = prefs.getString(_keyName) ?? 'Aditi Sharma';
    _section = prefs.getString(_keySection) ?? 'CS-A';
    _email = prefs.getString(_keyEmail) ?? '';
    _phone = prefs.getString(_keyPhone) ?? '';
    _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    notifyListeners();
  }

  Future<void> updateIdentity({
    required String newRollNumber,
    required String newName,
    String? newSection,
    String? newEmail,
    String? newPhone,
  }) async {
    _rollNumber = newRollNumber.trim().toUpperCase();
    _name = newName.trim();
    if (newSection != null) _section = newSection.trim();
    if (newEmail != null) _email = newEmail.trim();
    if (newPhone != null) _phone = newPhone.trim();
    _isLoggedIn = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRollNumber, _rollNumber);
    await prefs.setString(_keyName, _name);
    await prefs.setString(_keySection, _section);
    await prefs.setString(_keyEmail, _email);
    await prefs.setString(_keyPhone, _phone);
    await prefs.setBool(_keyIsLoggedIn, true);

    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _email = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyEmail);
    notifyListeners();
  }
}
