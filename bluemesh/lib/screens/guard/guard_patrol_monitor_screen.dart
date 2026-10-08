import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/mysql_api_service.dart';
import '../../widgets/server_config_dialog.dart';

class GuardPatrolMonitorScreen extends StatefulWidget {
  const GuardPatrolMonitorScreen({super.key});

  @override
  State<GuardPatrolMonitorScreen> createState() => _GuardPatrolMonitorScreenState();
}

class _GuardPatrolMonitorScreenState extends State<GuardPatrolMonitorScreen> {
  final MySqlApiService _apiService = MySqlApiService.instance;
  List<Map<String, dynamic>> _guards = [];
  List<Map<String, dynamic>> _zones = [];
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto refresh every 5 seconds for live patrol tracking
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadData(showSpinner: false));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _isLoading = true);
    try {
      final guards = await _apiService.fetchGuards();
      final zones = await _apiService.fetchZones();
      final logs = await _apiService.fetchGuardPatrolLogs();
      if (mounted) {
        setState(() {
          _guards = guards;
          _zones = zones;
          _logs = logs;
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
              Text('Register Security Guard', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
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
                    decoration: _inputDeco('Officer Name *', Icons.badge_outlined),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Contact Phone', Icons.phone_outlined),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedZone,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Assigned Explore Zone', Icons.explore_outlined),
                    items: const [
                      DropdownMenuItem(value: 'ZONE-A', child: Text('Zone A: Main Gate & Perimeter')),
                      DropdownMenuItem(value: 'ZONE-B', child: Text('Zone B: Academic Block & Labs')),
                      DropdownMenuItem(value: 'ZONE-C', child: Text('Zone C: Sports Complex & Food Court')),
                      DropdownMenuItem(value: 'ZONE-D', child: Text('Zone D: Student Hostels')),
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
                if (!formKey.currentState!.validate()) return;
                try {
                  await _apiService.createGuard(
                    username: userCtrl.text.trim(),
                    password: passCtrl.text.trim(),
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    assignedZone: selectedZone,
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Guard registered successfully!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              },
              child: const Text('Register Guard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
            Icon(Icons.shield_rounded, color: Colors.orangeAccent, size: 22),
            SizedBox(width: 8),
            Text('Guard Patrol & Explore Zones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header stats
                  Row(
                    children: [
                      _buildSummaryCard('Active Guards', '${_guards.length}', Icons.security, Colors.orangeAccent),
                      const SizedBox(width: 12),
                      _buildSummaryCard('Explore Zones', '${_zones.length}', Icons.map_rounded, const Color(0xFF38BDF8)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Explore Zones Map Status
                  const Text('Campus Explore Zones:',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _zones.map((z) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place, color: Colors.orangeAccent, size: 16),
                          const SizedBox(width: 6),
                          Text('${z['zone_code']}: ${z['name']}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Active Guards Section
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Security Guards Status',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Live Patrol Telemetry', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
                        child: Text('No guards registered yet. Click "+" in app bar to add one.',
                            style: TextStyle(color: Colors.white38)),
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

                  // Live Warning & Patrol Activity Log
                  const Text('Recent Patrol Activity & Boundary Warnings',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (_logs.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('No patrol pings logged yet today.', style: TextStyle(color: Colors.white38)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _logs.take(15).length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _buildLogItem(_logs[i]),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: isWarning ? 1.5 : 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(Icons.shield, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g['name'] ?? 'Guard',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                Text('Assigned: ${g['assigned_zone']} • Username: ${g['username']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Battery: ${g['battery_pct'] ?? 100}%',
                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isWarning ? Icons.warning_rounded : Icons.radar_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${log['guard_username']} in ${log['zone_code']}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(log['message'] ?? 'Patrol heartbeat registered',
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          Text(log['timestamp'] != null ? log['timestamp'].toString().split(' ').last : '',
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}
