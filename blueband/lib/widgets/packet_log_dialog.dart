import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ble_client_service.dart';

class PacketLogDialog extends StatelessWidget {
  final List<SentPacketLog> logs;

  const PacketLogDialog({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0D131E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BLE Sent Packet History',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white12),
          SizedBox(
            height: 320,
            child: logs.isEmpty
                ? const Center(
                    child: Text('No packets sent yet', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final item = logs[index];
                      final timeStr = DateFormat('hh:mm:ss a').format(item.timestamp);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF162032),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TYPE: ${item.packetType.toUpperCase()}',
                                  style: const TextStyle(
                                    color: Color(0xFF00F0FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(timeStr, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.payload,
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
