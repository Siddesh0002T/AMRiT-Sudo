import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentIdentityService extends ChangeNotifier {
  static const String _keyRollNumber = 'student_roll_number';
  static const String _keyName = 'student_name';

  String _rollNumber = '23CE045';
  String get rollNumber => _rollNumber;

  String _name = 'Aditi Sharma';
  String get name => _name;

  Future<void> loadIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    _rollNumber = prefs.getString(_keyRollNumber) ?? '23CE045';
    _name = prefs.getString(_keyName) ?? 'Aditi Sharma';
    notifyListeners();
  }

  Future<void> updateIdentity(String newRollNumber, String newName) async {
    _rollNumber = newRollNumber.trim().toUpperCase();
    _name = newName.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRollNumber, _rollNumber);
    await prefs.setString(_keyName, _name);

    notifyListeners();
  }
}
