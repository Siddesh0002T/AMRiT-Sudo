import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/ble_constants.dart';
import '../models/ble_packet.dart';

enum BandConnectionStatus { disconnectedRed, connectingYellow, connectedGreen }

class SentPacketLog {
  final DateTime timestamp;
  final String packetType;
  final String payload;
  final bool success;

  SentPacketLog({
    required this.timestamp,
    required this.packetType,
    required this.payload,
    required this.success,
  });
}

class BleClientService extends ChangeNotifier {
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  BandConnectionStatus _status = BandConnectionStatus.disconnectedRed;
  BandConnectionStatus get status => _status;

  Timer? _heartbeatTimer;
  Timer? _staffWatchdogTimer;

  /// Tracks the last time the staff host beacon was seen. Initialized to
  /// `now` when `connectToStaffHost` is called so the watchdog never fires
  /// immediately on first connect.
  DateTime? _lastStaffSeenAt;

  DateTime? _lastSignalSentAt;
  DateTime? get lastSignalSentAt => _lastSignalSentAt;

  /// Total attended seconds tracked locally on the band side.
  int _sessionSeconds = 0;
  int get sessionSeconds => _sessionSeconds;

  Timer? _sessionTimer;

  int _totalPingsSent = 0;
  int get totalPingsSent => _totalPingsSent;

  String? _sessionHostName;
  String? get sessionHostName => _sessionHostName;

  final List<SentPacketLog> _packetLogs = [];
  List<SentPacketLog> get packetLogs => List.unmodifiable(_packetLogs);

  String _currentRollNumber = '';
  String _currentStudentName = '';
  bool _currentVerified = false;

  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;

    try {
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      bool allGranted = true;
      statuses.forEach((p, s) {
        if (s.isDenied || s.isPermanentlyDenied) allGranted = false;
      });
      return allGranted;
    } catch (e) {
      debugPrint('Permission error: $e');
      return false;
    }
  }

  Future<void> connectToStaffHost({
    required String rollNumber,
    required String studentName,
    required bool verified,
  }) async {
    _currentRollNumber = rollNumber;
    _currentStudentName = studentName;
    _currentVerified = verified;
    _sessionSeconds = 0;

    _status = BandConnectionStatus.connectingYellow;
    notifyListeners();

    await requestPermissions();

    // Initialize the watchdog timestamp NOW so the watchdog never triggers
    // immediately after connecting (Bug fix: was null at startup).
    _lastStaffSeenAt = DateTime.now();

    // 1. Start Peripheral Broadcast with initial JOIN packet
    await _broadcastPacket(
      rollNumber: rollNumber,
      studentName: studentName,
      verified: verified,
      packetType: PacketType.join,
    );

    // 2. Start Scanning for Staff Host
    await _startStaffScan();

    // 3. Start Heartbeat Timer
    _startHeartbeatTimer();

    // 4. Staff Watchdog Timer (poll every 2s for faster detection)
    _startStaffWatchdog();

    // 5. Local session timer
    _startSessionTimer();

    notifyListeners();
  }

  Future<void> _startStaffScan() async {
    try {
      if (await FlutterBluePlus.isSupported) {
        await _scanSubscription?.cancel();

        _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
          for (final r in results) {
            final adv = r.advertisementData;
            final name = r.device.platformName.isNotEmpty
                ? r.device.platformName
                : adv.advName;

            final hasService =
                adv.serviceUuids.contains(Guid(BleConstants.serviceUuid));
            final isStaffName =
                name.contains('BlueMesh') || name.contains('Staff');

            if (hasService || isStaffName) {
              _lastStaffSeenAt = DateTime.now();
              _sessionHostName =
                  name.isNotEmpty ? name : 'BlueMesh Staff Host';
              if (_status != BandConnectionStatus.connectedGreen) {
                _status = BandConnectionStatus.connectedGreen;
                notifyListeners();
              }
              break;
            }
          }
        }, onError: (err) {
          debugPrint('Band BLE Scan error: $err');
        });

        await FlutterBluePlus.startScan(
          androidUsesFineLocation: true,
          continuousUpdates: true,
        );
      }
    } catch (e) {
      debugPrint('Band scan start error: $e');
    }
  }

  void _startStaffWatchdog() {
    _staffWatchdogTimer?.cancel();
    // Poll every 2 seconds for faster host-loss detection (was 4s).
    _staffWatchdogTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_lastStaffSeenAt != null) {
        final diff = DateTime.now().difference(_lastStaffSeenAt!).inSeconds;
        // Use the same timeout as the host — 3× heartbeat interval.
        const timeout = BleConstants.defaultHeartbeatIntervalSec *
            BleConstants.missedHeartbeatThreshold;
        if (diff > timeout) {
          if (_status != BandConnectionStatus.disconnectedRed) {
            _status = BandConnectionStatus.disconnectedRed;
            _sessionHostName = null;
            notifyListeners();
          }
        }
      }
    });
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_status == BandConnectionStatus.connectedGreen) {
        _sessionSeconds += 1;
        notifyListeners();
      }
    });
  }

  String get formattedSessionTime {
    final m = _sessionSeconds ~/ 60;
    final s = _sessionSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _broadcastPacket({
    required String rollNumber,
    required String studentName,
    required bool verified,
    required PacketType packetType,
  }) async {
    final packet = BlePacket(
      rollNumber: rollNumber,
      name: studentName,
      verified: verified,
      timestamp: DateTime.now(),
      packetType: packetType,
    );

    final payloadBytes = packet.toCompactBytes();
    final advName = 'BB_${rollNumber}_${verified ? "V1" : "V0"}';

    bool success = false;

    try {
      final isSupported = await _blePeripheral.isSupported;
      if (isSupported) {
        // Stop previous advertisement if running
        if (await _blePeripheral.isAdvertising) {
          await _blePeripheral.stop();
        }

        final AdvertiseData advData = AdvertiseData(
          serviceUuid: BleConstants.serviceUuid,
          localName: advName,
          includeDeviceName: true,
          manufacturerId: 0xFFFF,
          manufacturerData: payloadBytes,
        );

        await _blePeripheral.start(advertiseData: advData);
        success = true;
      }
    } catch (e) {
      debugPrint('Band Broadcast Error: $e');
    }

    _lastSignalSentAt = DateTime.now();
    _totalPingsSent += 1;

    _packetLogs.insert(
      0,
      SentPacketLog(
        timestamp: _lastSignalSentAt!,
        packetType: packetType.name.toUpperCase(),
        payload: packet.toCompactString(),
        success: success,
      ),
    );

    if (_packetLogs.length > 30) _packetLogs.removeLast();
    notifyListeners();
  }

  Future<void> sendPacket({
    required String rollNumber,
    required String studentName,
    required bool verified,
    required PacketType packetType,
  }) async {
    _currentRollNumber = rollNumber;
    _currentStudentName = studentName;
    _currentVerified = verified;

    await _broadcastPacket(
      rollNumber: rollNumber,
      studentName: studentName,
      verified: verified,
      packetType: packetType,
    );
  }

  void updateVerification(bool verified) {
    _currentVerified = verified;
    if (_currentRollNumber.isNotEmpty) {
      sendPacket(
        rollNumber: _currentRollNumber,
        studentName: _currentStudentName,
        verified: _currentVerified,
        packetType: PacketType.heartbeat,
      );
    }
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: BleConstants.defaultHeartbeatIntervalSec),
      (_) async {
        if (_currentRollNumber.isNotEmpty) {
          await sendPacket(
            rollNumber: _currentRollNumber,
            studentName: _currentStudentName,
            verified: _currentVerified,
            packetType: PacketType.heartbeat,
          );
        }
      },
    );
  }

  Future<void> disconnect() async {
    // Broadcast a LEAVE packet first so the host can react immediately
    // instead of waiting for the missed-heartbeat timeout.
    if (_currentRollNumber.isNotEmpty) {
      try {
        await _broadcastPacket(
          rollNumber: _currentRollNumber,
          studentName: _currentStudentName,
          verified: _currentVerified,
          packetType: PacketType.leave,
        );
        // Brief delay to allow the packet to be picked up by nearby host scanner
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (_) {}
    }

    _heartbeatTimer?.cancel();
    _staffWatchdogTimer?.cancel();
    _sessionTimer?.cancel();
    _scanSubscription?.cancel();
    _scanSubscription = null;

    try {
      await _blePeripheral.stop();
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('Disconnect error: $e');
    }

    _status = BandConnectionStatus.disconnectedRed;
    _sessionHostName = null;
    _sessionSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _staffWatchdogTimer?.cancel();
    _sessionTimer?.cancel();
    _scanSubscription?.cancel();
    _blePeripheral.stop();
    super.dispose();
  }
}

