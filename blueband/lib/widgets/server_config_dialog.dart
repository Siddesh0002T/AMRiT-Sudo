import 'package:flutter/material.dart';
import '../core/config/env_config.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: EnvConfig.instance.serverBaseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _applyQuickPreset(String host) {
    setState(() {
      _urlController.text = 'http://$host:8000/api.php';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.wifi_tethering_rounded, color: Color(0xFF38BDF8), size: 26),
          SizedBox(width: 10),
          Text('MySQL Server IP / Hotspot',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your laptop IP running the MySQL / phpMyAdmin API server:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                hintText: 'http://192.168.137.1:8000/api.php',
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon: const Icon(Icons.link, color: Color(0xFF38BDF8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Quick Presets:',
              style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip('Laptop Hotspot (192.168.137.1)', '192.168.137.1'),
                _buildPresetChip('Local Wi-Fi (192.168.0.170)', '192.168.0.170'),
                _buildPresetChip('Localhost (Emulator: 10.0.2.2)', '10.0.2.2'),
                _buildPresetChip('Localhost (PC)', '127.0.0.1'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            final url = _urlController.text.trim();
            if (url.isNotEmpty) {
              await EnvConfig.instance.setServerBaseUrl(url);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Server URL set to: ${EnvConfig.instance.serverBaseUrl}'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            }
          },
          child: const Text('Save & Connect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, String ip) {
    return InkWell(
      onTap: () => _applyQuickPreset(ip),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 11),
        ),
      ),
    );
  }
}
