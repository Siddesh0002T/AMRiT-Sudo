class AttendanceRecord {
  final int? id;
  final int sessionId;
  final String rollNumber;
  final String status; // 'present' | 'incomplete' | 'absent'
  final bool fingerprintVerified;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final int attendedSeconds;
  final int sessionTotalSeconds;
  final double attendancePercentage;
  final int pingCount;
  final int missedCount;
  final int rssi;
  final String? studentName;

  AttendanceRecord({
    this.id,
    required this.sessionId,
    required this.rollNumber,
    required this.status,
    required this.fingerprintVerified,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.attendedSeconds,
    required this.sessionTotalSeconds,
    required this.attendancePercentage,
    required this.pingCount,
    required this.missedCount,
    this.rssi = -60,
    this.studentName,
  });

  String get displayName => studentName ?? 'Student $rollNumber';

  String formatAttendedDuration() {
    final m = attendedSeconds ~/ 60;
    final s = attendedSeconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String formatTotalSessionDuration() {
    final m = sessionTotalSeconds ~/ 60;
    final s = sessionTotalSeconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'roll_number': rollNumber,
      'status': status,
      'fingerprint_verified': fingerprintVerified ? 1 : 0,
      'first_seen_at': firstSeenAt.toIso8601String(),
      'last_seen_at': lastSeenAt.toIso8601String(),
      'attended_seconds': attendedSeconds,
      'session_total_seconds': sessionTotalSeconds,
      'attendance_percentage': attendancePercentage,
      'ping_count': pingCount,
      'missed_count': missedCount,
      'rssi': rssi,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, {String? studentName}) {
    DateTime firstSeen = DateTime.now();
    if (map['first_seen_at'] != null) {
      firstSeen = DateTime.tryParse(map['first_seen_at'] as String) ?? DateTime.now();
    }

    DateTime lastSeen = DateTime.now();
    if (map['last_seen_at'] != null) {
      lastSeen = DateTime.tryParse(map['last_seen_at'] as String) ?? DateTime.now();
    }

    return AttendanceRecord(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      rollNumber: map['roll_number'] as String,
      status: map['status'] as String? ?? 'absent',
      fingerprintVerified: (map['fingerprint_verified'] as int? ?? 0) == 1,
      firstSeenAt: firstSeen,
      lastSeenAt: lastSeen,
      attendedSeconds: map['attended_seconds'] as int? ?? 0,
      sessionTotalSeconds: map['session_total_seconds'] as int? ?? 0,
      attendancePercentage: (map['attendance_percentage'] as num? ?? 0.0).toDouble(),
      pingCount: map['ping_count'] as int? ?? 0,
      missedCount: map['missed_count'] as int? ?? 0,
      rssi: map['rssi'] as int? ?? -60,
      studentName: studentName,
    );
  }
}
