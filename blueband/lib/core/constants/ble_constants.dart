// Shared BLE Constants between BlueMesh and BlueBand apps

class BleConstants {
  static const String serviceUuid = "0000AAA1-0000-1000-8000-00805F9B34FB";
  static const String writeCharUuid = "0000AAA2-0000-1000-8000-00805F9B34FB";
  static const String notifyCharUuid = "0000AAA3-0000-1000-8000-00805F9B34FB";

  static const int defaultHeartbeatIntervalSec = 15;
  static const int missedHeartbeatThreshold = 3;
}
