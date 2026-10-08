import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/mysql_api_service.dart';
import '../widgets/server_config_dialog.dart';

class GuardPatrolScreen extends StatefulWidget {
  final Map<String, dynamic> guardData;

  const GuardPatrolScreen({super.key, required this.guardData});

  @override
  State<GuardPatrolScreen> createState() => _GuardPatrolScreenState();
}

class _GuardPatrolScreenState extends State<GuardPatrolScreen> with SingleTickerProviderStateMixin {
  late String _assignedZone;
  late String _currentZone;
  late String _guardName;
  late String _username;

  bool _isPatrolling = false;
  int _patrolSeconds = 0;
  Timer? _patrolTimer;
  Timer? _pingTimer;

  bool _isZoneDeviationWarning = false;
  bool _isInactivityWarning = false;
  String _warningMessage = '';
  int _batteryPct = 94;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _guardName = widget.guardData['name'] ?? 'Officer';
    _username = widget.guardData['username'] ?? 'guard';
    _assignedZone = widget.guardData['assigned_zone'] ?? 'ZONE-A';
    _currentZone = _assignedZone;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _patrolTimer?.cancel();
    _pingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _togglePatrol() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isPatrolling = !_isPatrolling;
    });

    if (_isPatrolling) {
      _patrolTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _patrolSeconds++);
      });

      // Periodic ping every 10 seconds to backend
      _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _sendTelemetry();
      });

      _sendTelemetry(customMsg: 'Patrol shift started');
    } else {
      _patrolTimer?.cancel();
      _pingTimer?.cancel();
      _sendTelemetry(status: 'idle', customMsg: 'Patrol shift paused');
    }
  }

  Future<void> _sendTelemetry({
    String? status,
    bool? inZone,
    String customMsg = '',
  }) async {
    final curStatus = status ?? (_isZoneDeviationWarning ? 'warning_deviation' : (_isInactivityWarning ? 'warning_inactive' : 'patrolling'));
    final isInZone = inZone ?? !_isZoneDeviationWarning;

    final res = await MySqlApiService.instance.sendGuardPatrolPing(
      username: _username,
      currentZone: _currentZone,
      status: curStatus,
      isInZone: isInZone,
      battery: _batteryPct,
      rssi: -58,
      message: customMsg.isNotEmpty ? customMsg : (_isZoneDeviationWarning ? _warningMessage : 'Normal patrol in $_currentZone'),
    );

    if (mounted && res['is_warning'] == true) {
      setState(() {
        _isZoneDeviationWarning = true;
        _warningMessage = res['warning_message'] ?? '⚠️ Zone deviation detected!';
      });
      HapticFeedback.vibrate();
    }
  }

  void _triggerZoneDeviation() {
    HapticFeedback.vibrate();
    setState(() {
      _isZoneDeviationWarning = true;
      _isInactivityWarning = false;
      _currentZone = _assignedZone == 'ZONE-A' ? 'ZONE-C' : 'ZONE-A';
      _warningMessage = '⚠️ ZONE VIOLATION: You left $_assignedZone and entered $_currentZone! Return to assigned boundary immediately.';
    });
    _sendTelemetry(status: 'warning_deviation', inZone: false, customMsg: _warningMessage);
  }

  void _triggerInactivityWarning() {
    HapticFeedback.vibrate();
    setState(() {
      _isInactivityWarning = true;
      _isZoneDeviationWarning = false;
      _warningMessage = '⚠️ INACTIVITY WARNING: Station stationary limit exceeded! Please continue active patrol sweep.';
    });
    _sendTelemetry(status: 'warning_inactive', customMsg: _warningMessage);
  }

  void _resolveWarnings() {
    setState(() {
      _isZoneDeviationWarning = false;
      _isInactivityWarning = false;
      _currentZone = _assignedZone;
      _warningMessage = '';
    });
    _sendTelemetry(status: 'patrolling', inZone: true, customMsg: 'Guard returned to assigned patrol route.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Patrol normalized. Warning cleared.'), backgroundColor: Colors.green),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasWarning = _isZoneDeviationWarning || _isInactivityWarning;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Colors.orangeAccent, size: 22),
            SizedBox(width: 8),
            Text('Guard Patrol System', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Server Settings',
            icon: const Icon(Icons.wifi_tethering_rounded, color: Color(0xFF38BDF8)),
            onPressed: () => ServerConfigDialog.show(context),
          ),
          IconButton(
            tooltip: 'Exit Patrol',
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Guard Info Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.orangeAccent.withOpacity(0.2),
                    child: const Icon(Icons.security, color: Colors.orangeAccent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_guardName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('User: $_username • Assigned: $_assignedZone',
                            style: const TextStyle(color: Colors.white60, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.battery_charging_full_rounded, color: Color(0xFF00FF88), size: 16),
                            const SizedBox(width: 4),
                            Text('Battery: $_batteryPct%', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.wifi_rounded, color: Color(0xFF38BDF8), size: 16),
                            const SizedBox(width: 4),
                            const Text('BLE Mesh Active', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ⚠️ WARNING BANNER (If guard deviates or is inactive)
            if (hasWarning)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (ctx, child) => Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2 + (_pulseController.value * 0.15)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.3 * _pulseController.value),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                          SizedBox(width: 10),
                          Text(
                            'PATROL VIOLATION WARNING',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _warningMessage,
                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                          icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                          label: const Text('Return to Designated Zone (Clear Warning)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: _resolveWarnings,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Patrol Timer & Live Zone Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isPatrolling ? const Color(0xFF10B981).withOpacity(0.5) : Colors.white10,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _isPatrolling ? 'ACTIVE PATROL IN PROGRESS' : 'PATROL IDLE / STANDBY',
                    style: TextStyle(
                      color: _isPatrolling ? const Color(0xFF10B981) : Colors.white38,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_patrolSeconds),
                    style: TextStyle(
                      color: _isPatrolling ? Colors.white : Colors.white54,
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place, color: Colors.orangeAccent, size: 16),
                        const SizedBox(width: 6),
                        Text('Current Explore Zone: $_currentZone',
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // START / STOP PATROL BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPatrolling ? Colors.redAccent : const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: Icon(_isPatrolling ? Icons.pause_circle_filled : Icons.play_arrow_rounded,
                          color: Colors.white, size: 26),
                      label: Text(
                        _isPatrolling ? 'PAUSE PATROL' : 'START PATROL',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _togglePatrol,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Boundary & Deviation Test Actions (To demonstrate the warning feature)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Simulate Zone & Patrol Violations:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Test how the mesh system detects deviations and alerts administrators:',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.wrong_location, color: Colors.redAccent, size: 18),
                          label: const Text('Simulate Deviation',
                              style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: _triggerZoneDeviation,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.amber),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.timer_off_outlined, color: Colors.amber, size: 18),
                          label: const Text('Simulate Inactivity',
                              style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: _triggerInactivityWarning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
