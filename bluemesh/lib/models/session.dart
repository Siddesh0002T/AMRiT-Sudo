class AttendanceSession {
  final int? id;
  final String sessionName;
  final DateTime startTime;
  final DateTime? endTime;
  final int heartbeatIntervalMs;

  AttendanceSession({
    this.id,
    required this.sessionName,
    required this.startTime,
    this.endTime,
    required this.heartbeatIntervalMs,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_name': sessionName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'heartbeat_interval_ms': heartbeatIntervalMs,
    };
  }

  factory AttendanceSession.fromMap(Map<String, dynamic> map) {
    return AttendanceSession(
      id: map['id'] as int?,
      sessionName: map['session_name'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      heartbeatIntervalMs: map['heartbeat_interval_ms'] as int? ?? 15000,
    );
  }
}
