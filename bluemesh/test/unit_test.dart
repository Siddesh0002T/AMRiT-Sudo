import 'package:flutter_test/flutter_test.dart';
import 'package:bluemesh/models/ble_packet.dart';
import 'package:bluemesh/models/network_node.dart';

void main() {
  group('BLE Protocol Packet Tests', () {
    test('BlePacket JSON UTF-8 encoding and decoding', () {
      final now = DateTime.now();
      final packet = BlePacket(
        rollNumber: '23CE045',
        name: 'Aditi Sharma',
        verified: true,
        timestamp: now,
        packetType: PacketType.heartbeat,
      );

      final bytes = packet.toBytes();
      expect(bytes, isNotEmpty);

      final decoded = BlePacket.fromBytes(bytes);
      expect(decoded.rollNumber, equals('23CE045'));
      expect(decoded.name, equals('Aditi Sharma'));
      expect(decoded.verified, isTrue);
      expect(decoded.packetType, equals(PacketType.heartbeat));
    });
  });

  group('Network Node Status Tests', () {
    test('Node status updates correctly from packet', () {
      final node = NetworkNode(
        rollNumber: '23CE045',
        name: 'Aditi Sharma',
        verified: false,
        firstSeenAt: DateTime.now().subtract(const Duration(minutes: 1)),
        lastSeenAt: DateTime.now().subtract(const Duration(minutes: 1)),
        status: NodeStatus.unverifiedYellow,
      );

      expect(node.status, equals(NodeStatus.unverifiedYellow));

      node.updateFromPacket(isVerified: true, newName: 'Aditi Sharma');

      expect(node.verified, isTrue);
      expect(node.status, equals(NodeStatus.verifiedGreen));
      expect(node.missedCount, equals(0));
      expect(node.pingCount, equals(2));
    });
  });
}
