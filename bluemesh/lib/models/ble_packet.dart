import 'dart:convert';
import 'dart:typed_data';

enum PacketType { join, heartbeat, leave }

class BlePacket {
  final String rollNumber;
  final String name;
  final bool verified;
  final DateTime timestamp;
  final PacketType packetType;

  BlePacket({
    required this.rollNumber,
    required this.name,
    required this.verified,
    required this.timestamp,
    required this.packetType,
  });

  Map<String, dynamic> toJson() {
    return {
      'r': rollNumber,
      'n': name,
      'v': verified ? 1 : 0,
      't': timestamp.millisecondsSinceEpoch,
      'p': packetType.name[0], // 'j', 'h', 'l'
    };
  }

  factory BlePacket.fromJson(Map<String, dynamic> json) {
    PacketType type = PacketType.heartbeat;
    final typeStr = json['p'] ?? json['packet_type'];
    if (typeStr != null) {
      if (typeStr == 'j' || typeStr == 'join') type = PacketType.join;
      if (typeStr == 'l' || typeStr == 'leave') type = PacketType.leave;
    }

    final rawV = json['v'] ?? json['verified'];
    final bool isVerified = rawV == 1 || rawV == true || rawV == '1' || rawV == 'true';

    DateTime ts = DateTime.now();
    final rawT = json['t'] ?? json['timestamp'];
    if (rawT is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(rawT);
    } else if (rawT is String) {
      ts = DateTime.tryParse(rawT) ?? DateTime.now();
    }

    return BlePacket(
      rollNumber: (json['r'] ?? json['roll_number'] ?? 'UNKNOWN').toString().trim(),
      name: (json['n'] ?? json['name'] ?? 'Student').toString().trim(),
      verified: isVerified,
      timestamp: ts,
      packetType: type,
    );
  }

  /// Compact string format: "BM|ROLL|NAME|V|P|TIMESTAMP"
  /// e.g. "BM|23CE045|Aditi|1|H|1740000000"
  String toCompactString() {
    final v = verified ? '1' : '0';
    final p = packetType == PacketType.join
        ? 'J'
        : (packetType == PacketType.leave ? 'L' : 'H');
    final ts = (timestamp.millisecondsSinceEpoch ~/ 1000).toString();
    return 'BM|$rollNumber|$name|$v|$p|$ts';
  }

  Uint8List toCompactBytes() {
    return Uint8List.fromList(utf8.encode(toCompactString()));
  }

  factory BlePacket.fromBytes(List<int> bytes) {
    return tryParse(bytes) ??
        BlePacket(
          rollNumber: 'UNKNOWN',
          name: 'Student',
          verified: false,
          timestamp: DateTime.now(),
          packetType: PacketType.heartbeat,
        );
  }

  Uint8List toBytes() {
    final jsonString = jsonEncode(toJson());
    return Uint8List.fromList(utf8.encode(jsonString));
  }

  /// Parses bytes from JSON, compact pipe-delimited, or raw UTF8 string
  static BlePacket? tryParse(List<int> bytes) {
    if (bytes.isEmpty) return null;
    try {
      final str = utf8.decode(bytes, allowMalformed: true).trim();
      if (str.isEmpty) return null;

      // Check pipe format: "BM|ROLL|NAME|V|P|TS"
      if (str.startsWith('BM|')) {
        final parts = str.split('|');
        if (parts.length >= 4) {
          final roll = parts[1];
          final name = parts[2];
          final v = parts[3] == '1' || parts[3].toLowerCase() == 'true';
          PacketType type = PacketType.heartbeat;
          if (parts.length >= 5) {
            final p = parts[4].toUpperCase();
            if (p == 'J' || p == 'JOIN') type = PacketType.join;
            if (p == 'L' || p == 'LEAVE') type = PacketType.leave;
          }
          return BlePacket(
            rollNumber: roll,
            name: name,
            verified: v,
            timestamp: DateTime.now(),
            packetType: type,
          );
        }
      }

      // Check JSON format
      if (str.startsWith('{') && str.endsWith('}')) {
        final Map<String, dynamic> decoded = jsonDecode(str);
        return BlePacket.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  /// Parses from broadcast Device Name: "BB_23CE045_V1" or "BB_23CE045_V0"
  static BlePacket? fromAdvName(String advName) {
    if (advName.startsWith('BB_') || advName.startsWith('BAND_')) {
      final parts = advName.split('_');
      if (parts.length >= 2) {
        final roll = parts[1];
        bool verified = false;
        if (parts.length >= 3) {
          verified = parts[2].toUpperCase().contains('V1') || parts[2] == '1';
        }
        return BlePacket(
          rollNumber: roll,
          name: 'Student $roll',
          verified: verified,
          timestamp: DateTime.now(),
          packetType: PacketType.heartbeat,
        );
      }
    }
    return null;
  }
}
