import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/db/database_helper.dart';
import '../models/attendance_record.dart';
import '../models/network_node.dart';
import '../models/session.dart';
import 'mysql_api_service.dart';
import 'student_service.dart';

class AttendanceService extends ChangeNotifier {
  AttendanceSession? _activeSession;
  AttendanceSession? get activeSession => _activeSession;

  final StudentService _studentService = StudentService();

  Future<AttendanceSession> startSession({
    required String sessionName,
    int heartbeatIntervalMs = 15000,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final session = AttendanceSession(
      sessionName: sessionName,
      startTime: DateTime.now(),
      heartbeatIntervalMs: heartbeatIntervalMs,
    );

    final id = await db.insert('sessions', session.toMap());
    _activeSession = AttendanceSession(
      id: id,
      sessionName: session.sessionName,
      startTime: session.startTime,
      heartbeatIntervalMs: session.heartbeatIntervalMs,
    );

    notifyListeners();
    return _activeSession!;
  }

  Future<List<AttendanceRecord>> endSession(Map<String, NetworkNode> liveNodes) async {
    if (_activeSession == null || _activeSession!.id == null) {
      throw Exception('No active session to end');
    }

    final db = await DatabaseHelper.instance.database;
    final endTime = DateTime.now();
    final startTime = _activeSession!.startTime;

    // Calculate total session length in seconds (min 1 second)
    int sessionTotalSeconds = endTime.difference(startTime).inSeconds;
    if (sessionTotalSeconds < 1) sessionTotalSeconds = 1;

    await db.update(
      'sessions',
      {'end_time': endTime.toIso8601String()},
      where: 'id = ?',
      whereArgs: [_activeSession!.id],
    );

    final allStudents = await _studentService.getAllStudents();
    final Map<String, AttendanceRecord> recordMap = {};

    // 1. Process all students from official database roster
    for (var student in allStudents) {
      final roll = student.rollNumber.toUpperCase();
      final node = liveNodes[roll];

      String status = 'absent';
      bool isVerified = false;
      DateTime firstSeen = startTime;
      DateTime lastSeen = startTime;
      int attendedSeconds = 0;
      int pingCount = 0;
      int missedCount = 0;
      int rssi = -99;
      double percentage = 0.0;

      if (node != null) {
        isVerified = node.verified;
        firstSeen = node.firstSeenAt;
        lastSeen = node.lastSeenAt;
        attendedSeconds = node.totalAttendedSeconds;
        pingCount = node.pingCount;
        missedCount = node.missedCount;
        rssi = node.rssi;

        // Calculate attendance %
        percentage = (attendedSeconds / sessionTotalSeconds) * 100.0;
        if (percentage > 100.0) percentage = 100.0;

        // Strict Attendance Evaluation Algorithm:
        if (!node.verified) {
          // Connected without biometric token -> Absent
          status = 'absent';
        } else if (node.status == NodeStatus.disconnectedRed && percentage < 70.0) {
          // Disconnected before completion and attended < 70% -> Incomplete / Left Early
          status = 'incomplete';
        } else if (percentage >= 70.0 && node.verified) {
          // Verified and attended >= 70% of the session -> Present
          status = 'present';
        } else {
          status = 'incomplete';
        }
      }

      final record = AttendanceRecord(
        sessionId: _activeSession!.id!,
        rollNumber: roll,
        status: status,
        fingerprintVerified: isVerified,
        firstSeenAt: firstSeen,
        lastSeenAt: lastSeen,
        attendedSeconds: attendedSeconds,
        sessionTotalSeconds: sessionTotalSeconds,
        attendancePercentage: double.parse(percentage.toStringAsFixed(1)),
        pingCount: pingCount,
        missedCount: missedCount,
        rssi: rssi,
        studentName: student.name,
      );

      await db.insert('attendance', record.toMap());
      recordMap[roll] = record;
    }

    // 2. Process any live band devices that broadcasted but weren't in roster yet
    for (var entry in liveNodes.entries) {
      final roll = entry.key.toUpperCase();
      if (!recordMap.containsKey(roll)) {
        final node = entry.value;
        final attended = node.totalAttendedSeconds;
        double percentage = (attended / sessionTotalSeconds) * 100.0;
        if (percentage > 100.0) percentage = 100.0;

        String status = 'absent';
        if (node.verified && percentage >= 70.0) {
          status = 'present';
        } else if (node.verified) {
          status = 'incomplete';
        }

        final record = AttendanceRecord(
          sessionId: _activeSession!.id!,
          rollNumber: roll,
          status: status,
          fingerprintVerified: node.verified,
          firstSeenAt: node.firstSeenAt,
          lastSeenAt: node.lastSeenAt,
          attendedSeconds: attended,
          sessionTotalSeconds: sessionTotalSeconds,
          attendancePercentage: double.parse(percentage.toStringAsFixed(1)),
          pingCount: node.pingCount,
          missedCount: node.missedCount,
          rssi: node.rssi,
          studentName: node.name,
        );

        await db.insert('attendance', record.toMap());
        recordMap[roll] = record;
      }
    }

    // 3. Sync to MySQL Database and trigger Early Quit parent alerts
    try {
      final recordsJson = recordMap.values.map((r) => {
        'roll_number': r.rollNumber,
        'student_name': r.studentName,
        'status': r.status == 'incomplete' ? 'early_quit' : r.status,
        'attended_seconds': r.attendedSeconds,
        'percentage': r.attendancePercentage,
        'verified': r.fingerprintVerified,
      }).toList();

      await MySqlApiService.instance.saveAttendanceSession(
        sessionName: _activeSession!.sessionName,
        staffUsername: 'staff',
        startTime: startTime,
        endTime: endTime,
        records: recordsJson,
      );
    } catch (e) {
      debugPrint('MySQL session sync background warning: $e');
    }

    _activeSession = null;
    notifyListeners();
    return recordMap.values.toList();
  }

  Future<List<AttendanceSession>> getAllSessions() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('sessions', orderBy: 'start_time DESC');
    return maps.map((m) => AttendanceSession.fromMap(m)).toList();
  }

  Future<List<AttendanceRecord>> getSessionRecords(int sessionId) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'attendance',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'roll_number ASC',
    );

    final students = await _studentService.getAllStudents();
    final studentNameMap = {for (var s in students) s.rollNumber.toUpperCase(): s.name};

    return maps.map((m) {
      final roll = (m['roll_number'] as String).toUpperCase();
      return AttendanceRecord.fromMap(m, studentName: studentNameMap[roll]);
    }).toList();
  }

  Future<String> exportSessionToCSV(int sessionId) async {
    final db = await DatabaseHelper.instance.database;
    final sessionMaps = await db.query('sessions', where: 'id = ?', whereArgs: [sessionId]);
    if (sessionMaps.isEmpty) throw Exception('Session not found');

    final session = AttendanceSession.fromMap(sessionMaps.first);
    final records = await getSessionRecords(sessionId);

    final header = 'Roll Number,Student Name,Status,Fingerprint Verified,Attended Duration,Attendance %,Signal (RSSI),Last Seen\n';
    final rows = records.map((r) =>
      '"${r.rollNumber}","${r.displayName}","${r.status.toUpperCase()}","${r.fingerprintVerified ? 'YES' : 'NO'}","${r.formatAttendedDuration()}","${r.attendancePercentage}%","${r.rssi} dBm","${r.lastSeenAt.toIso8601String()}"'
    ).join('\n');

    final csvString = '# Session: ${session.sessionName}\n# Started: ${session.startTime.toIso8601String()}\n# Ended: ${session.endTime?.toIso8601String() ?? 'Active'}\n$header$rows';

    if (!kIsWeb) {
      final directory = await getApplicationDocumentsDirectory();
      final cleanName = session.sessionName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final path = '${directory.path}/${cleanName}_Attendance_Report.csv';
      final file = File(path);
      await file.writeAsString(csvString);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: 'Attendance Report for ${session.sessionName}'),
      );
      return path;
    }

    return csvString;
  }
}
