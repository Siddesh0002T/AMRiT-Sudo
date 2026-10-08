import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/env_config.dart';

class RegisteredStudentProfile {
  final String rollNumber;
  final String name;
  final String classSection;
  final String email;
  final String phone;
  final bool isFingerprintRegistered;

  RegisteredStudentProfile({
    required this.rollNumber,
    required this.name,
    required this.classSection,
    this.email = '',
    this.phone = '',
    this.isFingerprintRegistered = true,
  });

  factory RegisteredStudentProfile.fromJson(String roll, Map<dynamic, dynamic> json) {
    return RegisteredStudentProfile(
      rollNumber: (json['roll_number'] ?? json['rollNumber'] ?? roll).toString(),
      name: (json['name'] ?? 'Student').toString(),
      classSection: (json['class_section'] ?? json['classSection'] ?? 'A').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      isFingerprintRegistered: json['is_fingerprint_registered'] == 1 || json['isFingerprintRegistered'] == true,
    );
  }
}

class MySqlApiService {
  static final MySqlApiService instance = MySqlApiService._();
  MySqlApiService._();

  String get _endpoint => EnvConfig.instance.serverBaseUrl.trim();

  // ==========================================
  // STUDENT SERVICES
  // ==========================================

  Future<List<RegisteredStudentProfile>> fetchAllStudents() async {
    try {
      final uri = Uri.parse('$_endpoint?action=get_students');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['students'] is List) {
          final List<RegisteredStudentProfile> list = [];
          for (final item in data['students']) {
            list.add(RegisteredStudentProfile(
              rollNumber: (item['roll_number'] ?? '').toString().toUpperCase(),
              name: (item['name'] ?? 'Student').toString(),
              classSection: (item['class_section'] ?? 'A').toString(),
              email: (item['email'] ?? '').toString(),
              phone: (item['phone'] ?? '').toString(),
              isFingerprintRegistered: (item['is_fingerprint_registered'] ?? 1) == 1,
            ));
          }
          await _cacheStudents(list);
          return list;
        }
      }
    } catch (e) {
      debugPrint('MySQL fetchStudents error in blueband: $e');
    }

    return await _getCachedStudents();
  }

  Future<RegisteredStudentProfile?> findStudentByEmailOrRoll(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return null;

    final all = await fetchAllStudents();
    for (final s in all) {
      if (s.email.trim().toLowerCase() == clean || s.rollNumber.trim().toLowerCase() == clean) {
        return s;
      }
    }
    return null;
  }

  // ==========================================
  // GUARD LOGIN & PATROL EXPLORE ZONES
  // ==========================================

  Future<Map<String, dynamic>> guardLogin({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$_endpoint?action=guard_login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim(),
        'password': password.trim(),
      }),
    ).timeout(const Duration(seconds: 7));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'Invalid guard credentials');
  }

  Future<List<Map<String, dynamic>>> fetchZones() async {
    try {
      final uri = Uri.parse('$_endpoint?action=get_zones');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['zones'] is List) {
          return List<Map<String, dynamic>>.from(data['zones']);
        }
      }
    } catch (_) {}
    return [
      {'zone_code': 'ZONE-A', 'name': 'Zone A: Main Gate & Campus Perimeter'},
      {'zone_code': 'ZONE-B', 'name': 'Zone B: Academic Block & Science Labs'},
      {'zone_code': 'ZONE-C', 'name': 'Zone C: Sports Complex & Cafeteria'},
      {'zone_code': 'ZONE-D', 'name': 'Zone D: Student Hostels & Night Corridors'},
    ];
  }

  Future<Map<String, dynamic>> sendGuardPatrolPing({
    required String username,
    required String currentZone,
    required String status,
    required bool isInZone,
    int battery = 100,
    int rssi = -65,
    String message = '',
  }) async {
    try {
      final uri = Uri.parse('$_endpoint?action=guard_patrol_ping');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'current_zone': currentZone,
          'status': status,
          'is_in_zone': isInZone,
          'battery': battery,
          'rssi': rssi,
          'message': message,
        }),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error sending guard patrol ping: $e');
    }
    return {'success': false};
  }

  // ==========================================
  // STUDENT IN/OUT EVENT DISPATCH
  // ==========================================

  Future<void> sendStudentPresenceAlert({
    required String rollNumber,
    required String alertType, // 'STUDENT_IN' or 'STUDENT_OUT' or 'EARLY_QUIT'
  }) async {
    try {
      final uri = Uri.parse('$_endpoint?action=log_student_alert');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'roll_number': rollNumber,
          'alert_type': alertType,
          'message': 'Dispatched via BlueBand wristband node.',
        }),
      ).timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('Error sending presence alert from band: $e');
    }
  }

  // ==========================================
  // LOCAL CACHE
  // ==========================================

  Future<void> _cacheStudents(List<RegisteredStudentProfile> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.map((s) => {
        'rollNumber': s.rollNumber,
        'name': s.name,
        'classSection': s.classSection,
        'email': s.email,
        'phone': s.phone,
        'isFingerprintRegistered': s.isFingerprintRegistered,
      }).toList();
      await prefs.setString('cached_student_profiles_mysql', jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<List<RegisteredStudentProfile>> _getCachedStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('cached_student_profiles_mysql');
      if (str != null) {
        final list = jsonDecode(str);
        if (list is List) {
          return list.map((item) => RegisteredStudentProfile(
            rollNumber: item['rollNumber'] ?? '',
            name: item['name'] ?? '',
            classSection: item['classSection'] ?? 'A',
            email: item['email'] ?? '',
            phone: item['phone'] ?? '',
            isFingerprintRegistered: item['isFingerprintRegistered'] ?? true,
          )).toList();
        }
      }
    } catch (_) {}

    return [
      RegisteredStudentProfile(rollNumber: '23CE001', name: 'Aarav Sharma', classSection: 'CS-A', email: 'aarav@student.edu'),
      RegisteredStudentProfile(rollNumber: '23CE002', name: 'Aditi Verma', classSection: 'CS-A', email: 'aditi@student.edu'),
      RegisteredStudentProfile(rollNumber: '23CE003', name: 'Rohan Mehta', classSection: 'CS-B', email: 'rohan@student.edu'),
    ];
  }
}
