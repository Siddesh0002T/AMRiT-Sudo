// Shared BLE Constants between BlueMesh and BlueBand apps

class BleConstants {
  static const String serviceUuid = "0000AAA1-0000-1000-8000-00805F9B34FB";
  static const String writeCharUuid = "0000AAA2-0000-1000-8000-00805F9B34FB";
  static const String notifyCharUuid = "0000AAA3-0000-1000-8000-00805F9B34FB";

  static const int defaultHeartbeatIntervalSec = 15;
  static const int missedHeartbeatThreshold = 3;

  /// Seconds a node stays in disconnectedRed state before being purged from the
  /// live network map. Set to 2× the missed-heartbeat window so the teacher
  /// can still see it briefly before removal.
  static const int ghostRemovalTimeoutSec =
      defaultHeartbeatIntervalSec * missedHeartbeatThreshold * 2;
}
