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

  List<String> get _candidateUrls {
    final current = _endpoint;
    final candidates = [
      current,
      'http://localhost:8000/api.php',
      'http://127.0.0.1:8000/api.php',
      'http://localhost/bluemesh_api/api.php',
      'http://127.0.0.1/bluemesh_api/api.php',
      'http://10.0.2.2:8000/api.php',
      'http://10.0.2.2/bluemesh_api/api.php',
      'http://192.168.0.170:8000/api.php',
      'http://192.168.0.170/bluemesh_api/api.php',
      'http://192.168.137.1:8000/api.php',
      'http://192.168.137.1/bluemesh_api/api.php',
    ];
    return candidates.toSet().toList();
  }

  Future<http.Response> _postWithFallback(String action, Map<String, dynamic> body) async {
    for (final base in _candidateUrls) {
      try {
        final uri = Uri.parse('$base?action=$action');
        final res = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 4));

        if (base != _endpoint) {
          EnvConfig.instance.setServerBaseUrl(base);
        }
        return res;
      } catch (_) {}
    }
    throw Exception('Could not connect to MySQL server.');
  }

  Future<http.Response> _getWithFallback(String actionQuery) async {
    for (final base in _candidateUrls) {
      try {
        final uri = Uri.parse('$base?action=$actionQuery');
        final res = await http.get(uri).timeout(const Duration(seconds: 4));
        if (base != _endpoint) {
          EnvConfig.instance.setServerBaseUrl(base);
        }
        return res;
      } catch (_) {}
    }
    throw Exception('Could not connect to MySQL server.');
  }

  // ==========================================
  // STUDENT SERVICES
  // ==========================================

  Future<List<RegisteredStudentProfile>> fetchAllStudents() async {
    try {
      final response = await _getWithFallback('get_students');
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
    final response = await _postWithFallback('guard_login', {
      'username': username.trim(),
      'password': password.trim(),
    });

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'Invalid guard credentials');
  }

  Future<List<Map<String, dynamic>>> fetchZones() async {
    try {
      final res = await _getWithFallback('get_zones');
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
      final res = await _postWithFallback('guard_patrol_ping', {
        'username': username,
        'current_zone': currentZone,
        'status': status,
        'is_in_zone': isInZone,
        'battery': battery,
        'rssi': rssi,
        'message': message,
      });

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error sending guard patrol ping: $e');
    }
    return {'success': false};
  }

  // ==========================================
  // CAMPUS BLE PATROL BEACONS & ANTI-CHEAT
  // ==========================================

  Future<List<Map<String, dynamic>>> fetchPatrolBeacons({String? zoneCode}) async {
    try {
      final query = (zoneCode != null && zoneCode.isNotEmpty) ? '&zone_code=$zoneCode' : '';
      final res = await _getWithFallback('get_patrol_beacons$query');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['beacons'] is List) {
          return List<Map<String, dynamic>>.from(data['beacons']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching patrol beacons: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> verifyBeaconCheckpoint({
    required String guardUsername,
    required String beaconCode,
    required String zoneCode,
    required int rssi,
    String checkpointName = '',
  }) async {
    try {
      final res = await _postWithFallback('verify_beacon_checkpoint', {
        'guard_username': guardUsername.trim(),
        'beacon_code': beaconCode.trim(),
        'zone_code': zoneCode.trim(),
        'rssi': rssi,
        'checkpoint_name': checkpointName.trim(),
      });

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error verifying beacon checkpoint: $e');
    }
    return {'success': false, 'error': 'Network connection error'};
  }

  Future<Map<String, dynamic>> fetchGuardPatrolSummary(String guardUsername) async {
    try {
      final res = await _getWithFallback('get_guard_patrol_summary&guard_username=$guardUsername');
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error fetching guard patrol summary: $e');
    }
    return {'success': false};
  }

  // ==========================================
  // STUDENT IN/OUT EVENT DISPATCH
  // ==========================================

  Future<void> sendStudentPresenceAlert({
    required String rollNumber,
    required String alertType,
  }) async {
    try {
      await _postWithFallback('log_student_alert', {
        'roll_number': rollNumber,
        'alert_type': alertType,
        'message': 'Dispatched via BlueBand wristband node.',
      });
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
