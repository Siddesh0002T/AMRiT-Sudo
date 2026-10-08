import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/attendance_service.dart';
import 'network_visualizer_screen.dart';

class StartSessionDialog extends StatefulWidget {
  const StartSessionDialog({super.key});

  @override
  State<StartSessionDialog> createState() => _StartSessionDialogState();
}

class _StartSessionDialogState extends State<StartSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'CS-101 Morning Session');
  int _heartbeatSec = 15;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text(
        'Start Attendance Session',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Session Name',
                labelStyle: TextStyle(color: Colors.grey),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Heartbeat Interval: $_heartbeatSec seconds',
              style: TextStyle(color: Colors.grey[300], fontSize: 13),
            ),
            Slider(
              value: _heartbeatSec.toDouble(),
              min: 5,
              max: 30,
              divisions: 5,
              activeColor: const Color(0xFF3B82F6),
              inactiveColor: Colors.white12,
              onChanged: (v) => setState(() => _heartbeatSec = v.toInt()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isLoading = true);

                  try {
                    final attendanceService = Provider.of<AttendanceService>(context, listen: false);
                    final sessionName = _nameController.text.trim();

                    await attendanceService.startSession(
                      sessionName: sessionName,
                      heartbeatIntervalMs: _heartbeatSec * 1000,
                    );

                    if (mounted) {
                      Navigator.pop(context); // Close dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NetworkVisualizerScreen(sessionName: sessionName),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          child: const Text('Start Host', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
