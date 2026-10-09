import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/mysql_api_service.dart';
import '../../widgets/server_config_dialog.dart';

class GuardPatrolMonitorScreen extends StatefulWidget {
  const GuardPatrolMonitorScreen({super.key});

  @override
  State<GuardPatrolMonitorScreen> createState() => _GuardPatrolMonitorScreenState();
}

class _GuardPatrolMonitorScreenState extends State<GuardPatrolMonitorScreen> with SingleTickerProviderStateMixin {
  final MySqlApiService _apiService = MySqlApiService.instance;
  List<Map<String, dynamic>> _guards = [];
  List<Map<String, dynamic>> _zones = [];
  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _beacons = [];
  List<Map<String, dynamic>> _visits = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    // Auto refresh every 5 seconds for live patrol tracking
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadData(showSpinner: false));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _isLoading = true);
    try {
      final guards = await _apiService.fetchGuards();
      final zones = await _apiService.fetchZones();
      final logs = await _apiService.fetchGuardPatrolLogs();
      final beacons = await _apiService.fetchPatrolBeacons();
      final visits = await _apiService.fetchPatrolVisits();

      if (mounted) {
        setState(() {
          _guards = guards;
          _zones = zones;
          _logs = logs;
          _beacons = beacons;
          _visits = visits;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && showSpinner) setState(() => _isLoading = false);
    }
  }

  void _showAddGuardDialog() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedZone = 'ZONE-A';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.orangeAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Register Security Guard',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Guard will login on the BlueBand app to transmit live patrol telemetry.',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: userCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Guard Username * (e.g. guard1)', Icons.person_outline),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter username' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Guard Password *', Icons.lock_outline),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter password' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Full Name * (e.g. Officer Vikram)', Icons.badge_outlined),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Contact Phone', Icons.phone_outlined),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedZone,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Assigned Patrol Zone', Icons.map_outlined),
                    items: [
                      const DropdownMenuItem(value: 'ZONE-A', child: Text('ZONE-A (Main Gate & Perimeter)')),
                      const DropdownMenuItem(value: 'ZONE-B', child: Text('ZONE-B (Academic Block & Labs)')),
                      const DropdownMenuItem(value: 'ZONE-C', child: Text('ZONE-C (Sports Complex & Cafeteria)')),
                      const DropdownMenuItem(value: 'ZONE-D', child: Text('ZONE-D (Student Hostels)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedZone = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await _apiService.createGuard(
                      username: userCtrl.text.trim(),
                      password: passCtrl.text.trim(),
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      assignedZone: selectedZone,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Guard registered in MySQL!'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                }
              },
              child: const Text('Register', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.orangeAccent, size: 20),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.orangeAccent, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Guard Patrol & Anti-Cheat Monitor',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Server Settings',
            icon: const Icon(Icons.wifi_tethering_rounded, color: Color(0xFF38BDF8)),
            onPressed: () => ServerConfigDialog.show(context),
          ),
          IconButton(
            tooltip: 'Add Guard',
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.orangeAccent),
            onPressed: _showAddGuardDialog,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => _loadData(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orangeAccent,
          labelColor: Colors.orangeAccent,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              icon: const Icon(Icons.verified_user_rounded, size: 18),
              text: 'Beacon Visits (${_visits.length})',
            ),
            Tab(
              icon: const Icon(Icons.shield_rounded, size: 18),
              text: 'Active Guards (${_guards.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBeaconVisitsTab(),
                _buildGuardsAndTelemetryTab(),
              ],
            ),
    );
  }

  // ── TAB 1: CAMPUS BEACON VISITS & ANTI-CHEAT AUDIT ──
  Widget _buildBeaconVisitsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header summary cards
          Row(
            children: [
              _buildSummaryCard('Verified Visits', '${_visits.length}', Icons.check_circle_rounded, const Color(0xFF10B981)),
              const SizedBox(width: 12),
              _buildSummaryCard('Campus Beacons', '${_beacons.length}', Icons.bluetooth_searching_rounded, const Color(0xFF38BDF8)),
            ],
          ),
          const SizedBox(height: 18),

          // Anti-Cheat Info Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anti-Cheat Physical Verification Active',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Guards must be physically within Bluetooth RSSI proximity of campus beacons to record checkpoint visits.',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Campus Physical Checkpoints List
          const Text(
            'Campus Checkpoint Beacons:',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _beacons.map((b) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bluetooth, color: Color(0xFF38BDF8), size: 15),
                  const SizedBox(width: 6),
                  Text(
                    '${b['beacon_code']}: ${b['checkpoint_name']}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(height: 22),

          // Live Beacon Visits Timeline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Verified Checkpoint Visit Timeline',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_visits.length} Logs',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_visits.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'No checkpoint visits logged yet.\nWhen guards approach beacons on the BlueBand app, physical visits will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _visits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _buildVisitItem(_visits[i]),
            ),
        ],
      ),
    );
  }

  // ── TAB 2: ACTIVE GUARDS & BOUNDARY TELEMETRY ──
  Widget _buildGuardsAndTelemetryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSummaryCard('Active Guards', '${_guards.length}', Icons.security, Colors.orangeAccent),
              const SizedBox(width: 12),
              _buildSummaryCard('Explore Zones', '${_zones.length}', Icons.map_rounded, const Color(0xFF38BDF8)),
            ],
          ),
          const SizedBox(height: 18),

          // Active Guards Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Security Guards Status',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 16, color: Colors.black),
                label: const Text('Add Guard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: _showAddGuardDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_guards.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('No guards registered yet.', style: TextStyle(color: Colors.white38)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _guards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _buildGuardCard(_guards[i]),
            ),
          const SizedBox(height: 24),

          // Live Boundary & Deviation Warning Log
          const Text(
            'Patrol Telemetry & Boundary Warnings',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          if (_logs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('No telemetry pings received yet.', style: TextStyle(color: Colors.white38)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _buildLogItem(_logs[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitItem(Map<String, dynamic> v) {
    final checkpoint = (v['checkpoint_name'] ?? 'Checkpoint').toString();
    final beaconCode = (v['beacon_code'] ?? '').toString();
    final guard = (v['guard_username'] ?? 'guard').toString();
    final zone = (v['zone_code'] ?? '').toString();
    final rssi = v['rssi'] ?? -65;
    final time = (v['visited_at'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, color: Color(0xFF10B981), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        checkpoint,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$rssi dBm',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Guard: $guard • Zone: $zone • Beacon: $beaconCode',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Time: $time',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardCard(Map<String, dynamic> g) {
    final status = (g['status'] ?? 'idle').toString();
    final isWarning = status.contains('warning');
    final isPatrolling = status == 'patrolling';

    final color = isWarning
        ? Colors.redAccent
        : (isPatrolling ? const Color(0xFF10B981) : Colors.orangeAccent);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: isWarning ? 1.5 : 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(Icons.shield, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g['name'] ?? 'Guard',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Assigned: ${g['assigned_zone']} • Username: ${g['username']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 9),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Battery: ${g['battery_pct'] ?? 100}%',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final isWarning = log['is_warning'] == 1 || log['is_warning'] == true;
    final color = isWarning ? Colors.redAccent : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isWarning ? Icons.warning_amber_rounded : Icons.radio_button_checked, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['message'] ?? 'Guard activity logged',
                  style: TextStyle(color: isWarning ? Colors.redAccent : Colors.white, fontSize: 12, fontWeight: isWarning ? FontWeight.bold : FontWeight.normal),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Guard: ${log['guard_username']} • Zone: ${log['zone_code']} • ${log['timestamp']}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
