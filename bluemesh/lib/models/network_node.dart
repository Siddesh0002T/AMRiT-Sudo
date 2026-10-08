enum NodeStatus {
  verifiedGreen, // Connected + Fingerprint Verified (Active)
  unverifiedYellow, // Connected + Not Verified (Requires Fingerprint)
  disconnectedRed, // Disconnected / Bluetooth Off / Out of Range
}

class NetworkNode {
  final String rollNumber;
  String name;
  bool verified;
  DateTime firstSeenAt;
  DateTime lastSeenAt;
  int pingCount;
  int missedCount;
  int disconnectCount;
  int rssi; // Signal Strength in dBm (e.g. -50 to -95)
  int totalAttendedSeconds;
  NodeStatus status;

  /// Set when the node transitions to disconnectedRed.
  /// Used by the presence tracker to purge ghost nodes after [BleConstants.ghostRemovalTimeoutSec].
  DateTime? disconnectedSince;

  // Visual layout coordinates for interactive tree canvas
  double x;
  double y;
  double vx;
  double vy;

  NetworkNode({
    required this.rollNumber,
    required this.name,
    required this.verified,
    required this.firstSeenAt,
    required this.lastSeenAt,
    this.pingCount = 1,
    this.missedCount = 0,
    this.disconnectCount = 0,
    this.rssi = -60,
    this.totalAttendedSeconds = 0,
    required this.status,
    this.disconnectedSince,
    this.x = 0.0,
    this.y = 0.0,
    this.vx = 0.0,
    this.vy = 0.0,
  });

  bool get isConnected => status != NodeStatus.disconnectedRed;

  String get displayName =>
      name.isNotEmpty && name != 'Student' ? name : 'Student $rollNumber';
  String get fullIdentifier => '$rollNumber • $displayName';

  String get signalQuality {
    if (rssi >= -60) return 'Excellent';
    if (rssi >= -75) return 'Good';
    if (rssi >= -85) return 'Fair';
    return 'Weak';
  }

  String formatAttendedDuration() {
    final minutes = totalAttendedSeconds ~/ 60;
    final seconds = totalAttendedSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  void updateFromPacket({
    required bool isVerified,
    required String newName,
    int? newRssi,
  }) {
    if (newName.isNotEmpty && newName != 'Student') {
      name = newName;
    }
    verified = isVerified;
    lastSeenAt = DateTime.now();
    pingCount += 1;
    missedCount = 0;
    disconnectedSince = null; // Clear ghost timer on reconnect
    if (newRssi != null && newRssi != 0) {
      rssi = newRssi;
    }

    status = isVerified ? NodeStatus.verifiedGreen : NodeStatus.unverifiedYellow;
  }

  void markDisconnected() {
    if (status != NodeStatus.disconnectedRed) {
      status = NodeStatus.disconnectedRed;
      disconnectCount += 1;
      missedCount += 1;
      disconnectedSince = DateTime.now();
    }
  }

  void accumulateAttendedTime(int seconds) {
    if (status != NodeStatus.disconnectedRed) {
      totalAttendedSeconds += seconds;
    }
  }
}
