import 'dart:async';
import 'dart:math';
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
  Timer? _summaryTimer;

  bool _isZoneDeviationWarning = false;
  bool _isInactivityWarning = false;
  String _warningMessage = '';
  int _batteryPct = 94;

  // Campus BLE Checkpoints & Anti-Cheat State
  List<Map<String, dynamic>> _requiredBeacons = [];
  Set<String> _visitedBeaconCodes = {};
  List<Map<String, dynamic>> _recentVisits = [];
  bool _isLoadingBeacons = true;
  String _antiCheatStatus = 'PATROL_IN_PROGRESS';
  String? _cheatAlert;
  int _completionPercentage = 0;
  bool _isScanningBle = false;

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

    _loadBeaconsAndSummary();

    // Auto refresh checkpoint summary every 8 seconds
    _summaryTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_isPatrolling) {
        _loadBeaconsAndSummary(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _patrolTimer?.cancel();
    _pingTimer?.cancel();
    _summaryTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadBeaconsAndSummary({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingBeacons = true);
    try {
      final summary = await MySqlApiService.instance.fetchGuardPatrolSummary(_username);
      if (mounted && summary['success'] == true) {
        setState(() {
          _requiredBeacons = List<Map<String, dynamic>>.from(summary['required_beacons'] ?? []);
          _visitedBeaconCodes = Set<String>.from((summary['visited_beacon_codes'] as List? ?? []).map((e) => e.toString()));
          _recentVisits = List<Map<String, dynamic>>.from(summary['recent_visits'] ?? []);
          _completionPercentage = (summary['completion_percentage'] is num)
              ? (summary['completion_percentage'] as num).toInt()
              : 0;
          _antiCheatStatus = summary['anti_cheat_status'] ?? 'PATROL_IN_PROGRESS';
          _cheatAlert = summary['cheat_alert'];
          _isLoadingBeacons = false;
        });
        return;
      }

      // Fallback: fetch beacons directly by zone
      final beacons = await MySqlApiService.instance.fetchPatrolBeacons(zoneCode: _assignedZone);
      if (mounted) {
        setState(() {
          _requiredBeacons = beacons;
          _isLoadingBeacons = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) setState(() => _isLoadingBeacons = false);
    }
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

      _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _sendTelemetry();
      });

      _sendTelemetry(customMsg: 'Patrol session activated');
      _loadBeaconsAndSummary();
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
    final curStatus = status ??
        (_isZoneDeviationWarning
            ? 'warning_deviation'
            : (_isInactivityWarning ? 'warning_inactive' : 'patrolling'));
    final isInZone = inZone ?? !_isZoneDeviationWarning;

    final res = await MySqlApiService.instance.sendGuardPatrolPing(
      username: _username,
      currentZone: _currentZone,
      status: curStatus,
      isInZone: isInZone,
      battery: _batteryPct,
      rssi: -58,
      message: customMsg.isNotEmpty
          ? customMsg
          : (_isZoneDeviationWarning ? _warningMessage : 'Normal patrol in $_currentZone'),
    );

    if (mounted && res['is_warning'] == true) {
      setState(() {
        _isZoneDeviationWarning = true;
        _warningMessage = res['warning_message'] ?? '⚠️ Zone deviation detected!';
      });
      HapticFeedback.vibrate();
    }
  }

  // ==========================================
  // BLUETOOTH BEACON CHECKPOINT VERIFICATION (ANTI-CHEAT)
  // ==========================================
  Future<void> _verifyCheckpointPresence(Map<String, dynamic> beacon) async {
    HapticFeedback.mediumImpact();
    setState(() => _isScanningBle = true);

    // Simulate real Bluetooth discovery & RSSI measurement:
    // When physically near beacon, RSSI is between -55 dBm and -72 dBm
    final simulatedRssi = -55 - Random().nextInt(18);

    await Future.delayed(const Duration(milliseconds: 700));

    final beaconCode = beacon['beacon_code'] ?? '';
    final checkpointName = beacon['checkpoint_name'] ?? 'Checkpoint';
    final zoneCode = beacon['zone_code'] ?? _assignedZone;

    final res = await MySqlApiService.instance.verifyBeaconCheckpoint(
      guardUsername: _username,
      beaconCode: beaconCode,
      zoneCode: zoneCode,
      rssi: simulatedRssi,
      checkpointName: checkpointName,
    );

    if (mounted) {
      setState(() => _isScanningBle = false);

      if (res['success'] == true) {
        HapticFeedback.heavyImpact();
        await _loadBeaconsAndSummary(silent: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF10B981),
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'VERIFIED: $checkpointName ($simulatedRssi dBm) logged in MySQL anti-cheat!',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text(res['error'] ?? 'Verification failed'),
            ),
          );
        }
      }
    }
  }

  void _triggerZoneDeviation() {
    HapticFeedback.vibrate();
    setState(() {
      _isZoneDeviationWarning = true;
      _isInactivityWarning = false;
      _currentZone = _assignedZone == 'ZONE-A' ? 'ZONE-C' : 'ZONE-A';
      _warningMessage =
          '⚠️ ZONE VIOLATION: You left $_assignedZone and entered $_currentZone! Return to assigned boundary immediately.';
    });
    _sendTelemetry(status: 'warning_deviation', inZone: false, customMsg: _warningMessage);
  }

  void _triggerInactivityWarning() {
    HapticFeedback.vibrate();
    setState(() {
      _isInactivityWarning = true;
      _isZoneDeviationWarning = false;
      _warningMessage =
          '⚠️ INACTIVITY WARNING: Station stationary limit exceeded! Please continue active patrol sweep.';
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guard Info Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.orangeAccent.withOpacity(0.2),
                    child: const Icon(Icons.security, color: Colors.orangeAccent, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _guardName,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'ID: $_username • Assigned Zone: $_assignedZone',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 10,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.battery_charging_full_rounded, color: Color(0xFF00FF88), size: 15),
                                const SizedBox(width: 4),
                                Text('Battery: $_batteryPct%', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bluetooth_searching_rounded, color: Color(0xFF38BDF8), size: 15),
                                SizedBox(width: 4),
                                Text('BLE Beacon Check Active', style: TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ⚠️ WARNING BANNER (If guard deviates or is inactive)
            if (hasWarning)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (ctx, child) => Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2 + (_pulseController.value * 0.15)),
                    borderRadius: BorderRadius.circular(14),
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
                          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'PATROL VIOLATION WARNING',
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _warningMessage,
                        style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                          icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                          label: const Text('Return to Designated Zone (Clear Warning)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: _resolveWarnings,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Patrol Timer & Anti-Cheat Progress
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isPatrolling ? const Color(0xFF10B981).withOpacity(0.5) : Colors.white10,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isPatrolling ? 'ACTIVE PATROL SESSION' : 'PATROL STANDBY',
                        style: TextStyle(
                          color: _isPatrolling ? const Color(0xFF10B981) : Colors.white38,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontSize: 11,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (_completionPercentage == 100
                                  ? const Color(0xFF10B981)
                                  : Colors.orangeAccent)
                              .withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _completionPercentage == 100
                                ? const Color(0xFF10B981)
                                : Colors.orangeAccent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _completionPercentage == 100
                                  ? Icons.verified_user_rounded
                                  : Icons.pending_actions_rounded,
                              color: _completionPercentage == 100
                                  ? const Color(0xFF10B981)
                                  : Colors.orangeAccent,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _antiCheatStatus == 'ALL_CHECKPOINTS_VERIFIED'
                                  ? 'ANTI-CHEAT 100%'
                                  : _antiCheatStatus.replaceAll('_', ' '),
                              style: TextStyle(
                                color: _completionPercentage == 100
                                    ? const Color(0xFF10B981)
                                    : Colors.orangeAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_cheatAlert != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _cheatAlert!,
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_patrolSeconds),
                    style: TextStyle(
                      color: _isPatrolling ? Colors.white : Colors.white54,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress Bar for Checkpoint visits
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _requiredBeacons.isNotEmpty
                          ? (_visitedBeaconCodes.length / _requiredBeacons.length).clamp(0.0, 1.0)
                          : 0.0,
                      minHeight: 8,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _completionPercentage == 100 ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Verified Checkpoints: ${_visitedBeaconCodes.length} / ${_requiredBeacons.length}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '$_completionPercentage% Verified',
                        style: TextStyle(
                          color: _completionPercentage == 100 ? const Color(0xFF10B981) : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // START / STOP PATROL BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPatrolling ? Colors.redAccent : const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(_isPatrolling ? Icons.pause_circle_filled : Icons.play_arrow_rounded,
                          color: Colors.white, size: 24),
                      label: Text(
                        _isPatrolling ? 'PAUSE PATROL' : 'START PATROL',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _togglePatrol,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── CAMPUS BLE BEACON CHECKPOINTS SECTION (ANTI-CHEAT) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campus BLE Checkpoint Beacons',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Bluetooth proximity physical proof — no cheating allowed',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh Beacons',
                  icon: const Icon(Icons.refresh, color: Color(0xFF38BDF8), size: 20),
                  onPressed: () => _loadBeaconsAndSummary(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoadingBeacons)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_requiredBeacons.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('No BLE checkpoints registered for this zone.',
                      style: TextStyle(color: Colors.white38)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _requiredBeacons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final b = _requiredBeacons[i];
                  final code = (b['beacon_code'] ?? '').toString();
                  final name = (b['checkpoint_name'] ?? 'Checkpoint').toString();
                  final desc = (b['location_desc'] ?? '').toString();
                  final isVisited = _visitedBeaconCodes.contains(code);

                  // Find latest visit timestamp if any
                  String? visitedAt;
                  int? visitRssi;
                  for (final v in _recentVisits) {
                    if (v['beacon_code'] == code) {
                      visitedAt = v['visited_at'];
                      visitRssi = v['rssi'];
                      break;
                    }
                  }

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isVisited
                            ? const Color(0xFF10B981).withOpacity(0.5)
                            : Colors.white12,
                        width: isVisited ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isVisited ? const Color(0xFF10B981) : Colors.orangeAccent)
                                    .withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isVisited ? Icons.check_circle_rounded : Icons.bluetooth_rounded,
                                color: isVisited ? const Color(0xFF10B981) : Colors.orangeAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Code: $code • Zone: ${b['zone_code']}',
                                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isVisited ? const Color(0xFF10B981) : Colors.grey)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isVisited ? 'VERIFIED' : 'PENDING',
                                style: TextStyle(
                                  color: isVisited ? const Color(0xFF10B981) : Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            desc,
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 10),

                        // Status / Action Bar
                        if (isVisited) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified, color: Color(0xFF10B981), size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Verified at ${visitedAt ?? 'Recently'} | RSSI: ${visitRssi ?? -65} dBm',
                                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF38BDF8),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: _isScanningBle
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.bluetooth_searching, color: Colors.black, size: 16),
                              label: const Text(
                                'Approach & Verify Checkpoint (Bluetooth Connect)',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              onPressed: _isScanningBle ? null : () => _verifyCheckpointPresence(b),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),

            // Boundary & Deviation Test Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Audit & Anti-Cheat Simulation:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Test how the mesh system flags skipping checkpoints or leaving zones:',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.wrong_location, color: Colors.redAccent, size: 16),
                          label: const Text('Test Zone Deviation',
                              style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: _triggerZoneDeviation,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.amber),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.timer_off_outlined, color: Colors.amber, size: 16),
                          label: const Text('Test Inactivity Cheat',
                              style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
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
