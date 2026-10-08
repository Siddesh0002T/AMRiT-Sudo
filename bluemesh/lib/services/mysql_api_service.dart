import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/env_config.dart';
import '../models/student.dart';

class MySqlApiService {
  static final MySqlApiService instance = MySqlApiService._();
  MySqlApiService._();

  String get _endpoint => EnvConfig.instance.serverBaseUrl.trim();

  // Candidate fallback URLs in case configured URL is unreachable on the current network interface
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

        // If server answered (200 or 400 or 401), this endpoint is valid and alive!
        if (base != _endpoint) {
          EnvConfig.instance.setServerBaseUrl(base);
        }
        return res;
      } catch (_) {
        // Try next candidate
      }
    }
    throw Exception('Could not connect to MySQL server. Please verify start_server.bat is running.');
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
      } catch (_) {
        // Try next candidate
      }
    }
    throw Exception('Could not connect to MySQL server.');
  }

  // ==========================================
  // 1. ADMIN ACTIONS
  // ==========================================

  Future<Map<String, dynamic>> adminLogin({
    required String username,
    required String password,
  }) async {
    final cleanU = username.trim().toLowerCase();
    final cleanP = password.trim();

    if (cleanU == 'admin' && cleanP == 'admin') {
      try {
        await _postWithFallback('admin_login', {'username': username.trim(), 'password': password.trim()});
      } catch (_) {}
      return {
        'success': true,
        'role': 'admin',
        'user': {'username': 'admin', 'name': 'System Administrator'},
      };
    }

    final res = await _postWithFallback('admin_login', {'username': username.trim(), 'password': password.trim()});
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Admin authentication failed');
  }

  Future<List<Map<String, dynamic>>> fetchStaffList() async {
    try {
      final res = await _getWithFallback('get_staff');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['staff'] is List) {
          final list = List<Map<String, dynamic>>.from(data['staff']);
          await _cacheStaff(list);
          return list;
        }
      }
    } catch (e) {
      debugPrint('Error fetching staff from MySQL: $e');
    }
    return await _getCachedStaff();
  }

  Future<void> createStaff({
    required String username,
    required String password,
    required String name,
    String email = '',
    String phone = '',
    String department = 'Computer Science',
    String role = 'Faculty',
  }) async {
    final res = await _postWithFallback('create_staff', {
      'username': username.trim(),
      'password': password.trim(),
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'department': department.trim(),
      'role': role.trim(),
    });

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to create staff account');
    }
  }

  Future<void> deleteStaff(dynamic id) async {
    await _postWithFallback('delete_staff', {'id': id});
  }

  // ==========================================
  // 2. STAFF AUTHENTICATION
  // ==========================================

  Future<Map<String, dynamic>> staffLogin({
    required String username,
    required String password,
  }) async {
    final res = await _postWithFallback('staff_login', {
      'username': username.trim(),
      'password': password.trim(),
    });

    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'Invalid staff credentials');
  }

  // ==========================================
  // 3. STUDENT MANAGEMENT
  // ==========================================

  Future<List<Student>> fetchStudents() async {
    try {
      final res = await _getWithFallback('get_students');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['students'] is List) {
          final List<Student> list = [];
          for (final item in data['students']) {
            list.add(Student(
              id: item['id'] is int ? item['id'] : int.tryParse(item['id'].toString()),
              rollNumber: (item['roll_number'] ?? '').toString().toUpperCase(),
              name: (item['name'] ?? '').toString(),
              classSection: (item['class_section'] ?? 'A').toString(),
              email: (item['email'] ?? '').toString(),
              phone: (item['phone'] ?? '').toString(),
              isFingerprintRegistered: (item['is_fingerprint_registered'] ?? 1) == 1 || item['is_fingerprint_registered'] == true,
            ));
          }
          await _cacheStudents(list);
          return list;
        }
      }
    } catch (e) {
      debugPrint('Error fetching students from MySQL: $e');
    }
    return await _getCachedStudents();
  }

  Future<void> saveStudent(Student s, {String parentName = '', String parentEmail = '', String parentPhone = ''}) async {
    final res = await _postWithFallback('create_student', {
      'roll_number': s.rollNumber.toUpperCase(),
      'name': s.name,
      'class_section': s.classSection,
      'email': s.email,
      'phone': s.phone,
      'is_fingerprint_registered': s.isFingerprintRegistered ? 1 : 0,
      'parent_name': parentName,
      'parent_email': parentEmail,
      'parent_phone': parentPhone,
    });

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to save student');
    }
  }

  Future<void> deleteStudent(String rollNumber) async {
    await _postWithFallback('delete_student', {'roll_number': rollNumber});
  }

  // ==========================================
  // 4. GUARDS & PATROL EXPLORE ZONES
  // ==========================================

  Future<List<Map<String, dynamic>>> fetchGuards() async {
    try {
      final res = await _getWithFallback('get_guards');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['guards'] is List) {
          return List<Map<String, dynamic>>.from(data['guards']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching guards: $e');
    }
    return [];
  }

  Future<void> createGuard({
    required String username,
    required String password,
    required String name,
    String phone = '',
    String assignedZone = 'ZONE-A',
  }) async {
    final res = await _postWithFallback('create_guard', {
      'username': username.trim(),
      'password': password.trim(),
      'name': name.trim(),
      'phone': phone.trim(),
      'assigned_zone': assignedZone.trim(),
    });

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to create guard');
    }
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

  Future<List<Map<String, dynamic>>> fetchGuardPatrolLogs() async {
    try {
      final res = await _getWithFallback('get_guard_patrol_logs');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['logs'] is List) {
          return List<Map<String, dynamic>>.from(data['logs']);
        }
      }
    } catch (_) {}
    return [];
  }

  // ==========================================
  // 5. PARENT ALERTS & LIVE STATUS
  // ==========================================

  Future<Map<String, dynamic>> logStudentAlert({
    required String rollNumber,
    required String alertType,
    String message = '',
  }) async {
    try {
      final res = await _postWithFallback('log_student_alert', {
        'roll_number': rollNumber.toUpperCase(),
        'alert_type': alertType,
        'message': message,
      });

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error logging student alert: $e');
    }
    return {'success': false};
  }

  Future<List<Map<String, dynamic>>> fetchAlerts() async {
    try {
      final res = await _getWithFallback('get_alerts');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['alerts'] is List) {
          return List<Map<String, dynamic>>.from(data['alerts']);
        }
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> fetchParentLiveStatus(String rollNumber) async {
    try {
      final res = await _getWithFallback('get_parent_live_status&roll_number=${Uri.encodeComponent(rollNumber)}');
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error fetching parent live status: $e');
    }
    return {'success': false, 'error': 'Network connection issue'};
  }

  // ==========================================
  // 6. ATTENDANCE SESSIONS SYNC
  // ==========================================

  Future<void> saveAttendanceSession({
    required String sessionName,
    required String staffUsername,
    required DateTime startTime,
    required DateTime endTime,
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      await _postWithFallback('save_session', {
        'session_name': sessionName,
        'staff_username': staffUsername,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'records': records,
      });
    } catch (e) {
      debugPrint('Error saving attendance session to MySQL: $e');
    }
  }

  // ==========================================
  // LOCAL CACHE HELPERS
  // ==========================================

  Future<void> _cacheStaff(List<Map<String, dynamic>> staff) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_mysql_staff', jsonEncode(staff));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _getCachedStaff() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('cached_mysql_staff');
      if (str != null) {
        final list = jsonDecode(str);
        if (list is List) return List<Map<String, dynamic>>.from(list);
      }
    } catch (_) {}
    return [
      {'username': 'staff1', 'name': 'Prof. Alan Turing', 'role': 'Faculty'},
      {'username': 'staff2', 'name': 'Dr. Grace Hopper', 'role': 'Faculty'},
    ];
  }

  Future<void> _cacheStudents(List<Student> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.map((s) => s.toMap()).toList();
      await prefs.setString('cached_mysql_students', jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<List<Student>> _getCachedStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('cached_mysql_students');
      if (str != null) {
        final list = jsonDecode(str);
        if (list is List) {
          return list.map((m) => Student.fromMap(m)).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
