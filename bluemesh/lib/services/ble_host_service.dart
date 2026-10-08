import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/ble_constants.dart';
import '../models/ble_packet.dart';
import '../models/network_node.dart';
import 'student_service.dart';

class BleHostService extends ChangeNotifier {
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  final StudentService _studentService = StudentService();
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  bool _isAdvertising = false;
  bool get isAdvertising => _isAdvertising;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  final Map<String, NetworkNode> _nodes = {};
  Map<String, NetworkNode> get nodes => Map.unmodifiable(_nodes);

  Timer? _tickerTimer;
  int _heartbeatIntervalSec = BleConstants.defaultHeartbeatIntervalSec;
  DateTime? _sessionStartTime;
  DateTime? get sessionStartTime => _sessionStartTime;

  /// Fires whenever a brand-new student node appears that is NOT yet verified.
  /// The UI listens to this to show a teacher alert/snackbar.
  final StreamController<NetworkNode> _newUnverifiedStudentController =
      StreamController<NetworkNode>.broadcast();
  Stream<NetworkNode> get onNewUnverifiedStudent =>
      _newUnverifiedStudentController.stream;

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
      statuses.forEach((permission, status) {
        if (status.isDenied || status.isPermanentlyDenied) {
          allGranted = false;
        }
      });
      return allGranted;
    } catch (e) {
      debugPrint('Permission request error: $e');
      return false;
    }
  }

  Future<void> startAdvertising(
      {int heartbeatIntervalSec =
          BleConstants.defaultHeartbeatIntervalSec}) async {
    _heartbeatIntervalSec = heartbeatIntervalSec;
    _sessionStartTime = DateTime.now();
    await requestPermissions();

    // 1. Start Peripheral Beacon so student bands detect staff
    final AdvertiseData advertiseData = AdvertiseData(
      serviceUuid: BleConstants.serviceUuid,
      localName: 'BlueMesh_Staff',
      includeDeviceName: true,
    );

    try {
      final isSupported = await _blePeripheral.isSupported;
      if (isSupported) {
        if (await _blePeripheral.isAdvertising) {
          await _blePeripheral.stop();
        }
        await _blePeripheral.start(advertiseData: advertiseData);
        _isAdvertising = true;
      }
    } catch (e) {
      debugPrint('BLE Host Advertising Error: $e');
    }

    // 2. Start Central BLE Scanning to receive student band packets
    await _startContinuousScan();

    // 3. Start 1-second Presence Watchdog & Time Accumulator
    _startPresenceTracker();

    notifyListeners();
  }

  Future<void> _startContinuousScan() async {
    try {
      if (await FlutterBluePlus.isSupported) {
        await _scanSubscription?.cancel();

        _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
          for (final result in results) {
            _parseAndProcessScanResult(result);
          }
        }, onError: (err) {
          debugPrint('BLE Scan Stream error: $err');
        });

        await FlutterBluePlus.startScan(
          androidUsesFineLocation: true,
          continuousUpdates: true,
        );
        _isScanning = true;
      }
    } catch (e) {
      debugPrint('Error starting BLE scanner: $e');
    }
  }

  void _parseAndProcessScanResult(ScanResult result) {
    final adv = result.advertisementData;
    final devName = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : adv.advName;
    final rssi = result.rssi;

    BlePacket? packet;

    // 1. Try Manufacturer Data (e.g. 0xFFFF or any ID)
    if (adv.manufacturerData.isNotEmpty) {
      for (final bytes in adv.manufacturerData.values) {
        packet = BlePacket.tryParse(bytes);
        if (packet != null) break;
      }
    }

    // 2. Try Service Data
    if (packet == null && adv.serviceData.isNotEmpty) {
      for (final bytes in adv.serviceData.values) {
        packet = BlePacket.tryParse(bytes);
        if (packet != null) break;
      }
    }

    // 3. Try Device / Advertisement Name format (BB_23CE045_V1)
    if (packet == null && devName.isNotEmpty) {
      packet = BlePacket.fromAdvName(devName);
    }

    if (packet != null) {
      // Ignore LEAVE packets from bands that gracefully disconnected —
      // mark them disconnected immediately so the host reacts within 1 timer tick.
      if (packet.packetType == PacketType.leave) {
        final roll = packet.rollNumber.trim().toUpperCase();
        if (_nodes.containsKey(roll)) {
          _nodes[roll]!.markDisconnected();
          notifyListeners();
        }
        return;
      }

      processIncomingPacket(packet, rssi: rssi);
    }
  }

  Future<void> stopAdvertising() async {
    try {
      await _blePeripheral.stop();
    } catch (e) {
      debugPrint('BLE Stop Error: $e');
    }
    _isAdvertising = false;

    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    } catch (e) {
      debugPrint('BLE Stop Scan Error: $e');
    }
    _isScanning = false;

    _tickerTimer?.cancel();
    notifyListeners();
  }

  Future<void> processIncomingPacket(BlePacket packet,
      {int rssi = -60}) async {
    final roll = packet.rollNumber.trim().toUpperCase();
    if (roll.isEmpty || roll == 'UNKNOWN') return;

    // Check DB for registered student name
    String resolvedName = packet.name;
    final registeredStudent = await _studentService.getStudentByRoll(roll);
    if (registeredStudent != null && registeredStudent.name.isNotEmpty) {
      resolvedName = registeredStudent.name;
    }

    if (_nodes.containsKey(roll)) {
      final wasDisconnected = !_nodes[roll]!.isConnected;
      _nodes[roll]!.updateFromPacket(
        isVerified: packet.verified,
        newName: resolvedName,
        newRssi: rssi,
      );
      // If student just reconnected and is still unverified, notify teacher
      if (wasDisconnected && !packet.verified) {
        _newUnverifiedStudentController.add(_nodes[roll]!);
      }
    } else {
      // Calculate dynamic initial position on tree layout
      final angle =
          (_nodes.length * (2 * pi / 8)) + (Random().nextDouble() * 0.2);
      final radius = 150.0 + ((_nodes.length % 3) * 45.0);
      final initialX = radius * cos(angle);
      final initialY = radius * sin(angle);

      final node = NetworkNode(
        rollNumber: roll,
        name: resolvedName,
        verified: packet.verified,
        firstSeenAt: DateTime.now(),
        lastSeenAt: DateTime.now(),
        rssi: rssi,
        totalAttendedSeconds: 1,
        status: packet.verified
            ? NodeStatus.verifiedGreen
            : NodeStatus.unverifiedYellow,
        x: initialX,
        y: initialY,
      );
      _nodes[roll] = node;

      // Notify teacher of new unverified student joining
      if (!packet.verified) {
        _newUnverifiedStudentController.add(node);
      }
    }

    notifyListeners();
  }

  void _startPresenceTracker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      bool changed = false;
      final List<String> toRemove = [];

      _nodes.forEach((roll, node) {
        // Accumulate attendance time if connected
        if (node.isConnected) {
          node.accumulateAttendedTime(1);
          changed = true;
        }

        // Check if heartbeat is lost
        final secondsSinceLastSeen = now.difference(node.lastSeenAt).inSeconds;
        final timeout =
            _heartbeatIntervalSec * BleConstants.missedHeartbeatThreshold;
        if (secondsSinceLastSeen > timeout) {
          if (node.status != NodeStatus.disconnectedRed) {
            node.markDisconnected();
            changed = true;
          }
        }

        // --- Ghost Node Removal ---
        // If the node has been disconnected long enough, remove it from the map.
        if (node.status == NodeStatus.disconnectedRed &&
            node.disconnectedSince != null) {
          final secondsDisconnected =
              now.difference(node.disconnectedSince!).inSeconds;
          if (secondsDisconnected >= BleConstants.ghostRemovalTimeoutSec) {
            toRemove.add(roll);
            changed = true;
          }
        }
      });

      for (final roll in toRemove) {
        _nodes.remove(roll);
        debugPrint('BlueMesh: Ghost node removed → $roll');
      }

      if (changed) {
        notifyListeners();
      }
    });
  }

  void resetNodes() {
    _nodes.clear();
    _sessionStartTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _scanSubscription?.cancel();
    _newUnverifiedStudentController.close();
    stopAdvertising();
    super.dispose();
  }
}

