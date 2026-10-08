import 'package:flutter/material.dart';
import '../../services/mysql_api_service.dart';
import '../../widgets/server_config_dialog.dart';

class ParentPortalScreen extends StatefulWidget {
  final String? initialRollNumber;

  const ParentPortalScreen({super.key, this.initialRollNumber});

  @override
  State<ParentPortalScreen> createState() => _ParentPortalScreenState();
}

class _ParentPortalScreenState extends State<ParentPortalScreen> {
  final TextEditingController _rollController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _parentData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialRollNumber != null && widget.initialRollNumber!.isNotEmpty) {
      _rollController.text = widget.initialRollNumber!;
      _loadStudentStatus(widget.initialRollNumber!);
    } else {
      _rollController.text = '23CE001';
      _loadStudentStatus('23CE001');
    }
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentStatus(String roll) async {
    final clean = roll.trim().toUpperCase();
    if (clean.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await MySqlApiService.instance.fetchParentLiveStatus(clean);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (data['success'] == true) {
            _parentData = data;
          } else {
            _errorMessage = data['error'] ?? 'Student record not found in MySQL';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _simulateAlert(String type) async {
    final roll = _rollController.text.trim().toUpperCase();
    if (roll.isEmpty) return;

    setState(() => _isLoading = true);
    await MySqlApiService.instance.logStudentAlert(
      rollNumber: roll,
      alertType: type,
      message: type == 'EARLY_QUIT' ? 'Student left class mesh zone prematurely.' : 'Triggered via portal.',
    );

    if (mounted) {
      await _loadStudentStatus(roll);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type alert triggered and parent email dispatched!'),
          backgroundColor: type == 'EARLY_QUIT' ? Colors.redAccent : Colors.teal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = _parentData?['student'];
    final liveStatus = (_parentData?['live_status'] ?? 'OUTSIDE').toString().toUpperCase();
    final alerts = (_parentData?['alerts'] as List?) ?? [];
    final lastSeen = _parentData?['last_seen_at'];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.family_restroom_rounded, color: Color(0xFF38BDF8), size: 22),
            SizedBox(width: 8),
            Text('Parent Live Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Server IP / Hotspot Settings',
            icon: const Icon(Icons.wifi_tethering_rounded, color: Color(0xFF38BDF8)),
            onPressed: () => ServerConfigDialog.show(context),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => _loadStudentStatus(_rollController.text),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search / Roll Number Bar
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
                  const Text(
                    'Track Student Attendance in Real-Time',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Receive live In/Out alerts and Early Quit notifications with email sync:',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rollController,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'Enter Student Roll (e.g. 23CE001)',
                            hintStyle: const TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            prefixIcon: const Icon(Icons.badge, color: Color(0xFF38BDF8)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (v) => _loadStudentStatus(v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : () => _loadStudentStatus(_rollController.text),
                        child: const Text('Track', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent))),
                  ],
                ),
              ),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (student != null) ...[
              // Live Status Header Card
              _buildLiveStatusCard(student, liveStatus, lastSeen),
              const SizedBox(height: 20),

              // Test Simulation Buttons (For quick presentation / testing)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Simulate Live Event & Test Email to Parent:',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                          icon: const Icon(Icons.login, size: 16, color: Colors.white),
                          label: const Text('Student IN (Classroom)', style: TextStyle(color: Colors.white, fontSize: 12)),
                          onPressed: () => _simulateAlert('STUDENT_IN'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          icon: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.white),
                          label: const Text('⚠️ EARLY QUIT ALERT', style: TextStyle(color: Colors.white, fontSize: 12)),
                          onPressed: () => _simulateAlert('EARLY_QUIT'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B)),
                          icon: const Icon(Icons.logout, size: 16, color: Colors.white),
                          label: const Text('Student OUT', style: TextStyle(color: Colors.white, fontSize: 12)),
                          onPressed: () => _simulateAlert('STUDENT_OUT'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Alerts Feed
              Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: Color(0xFF38BDF8), size: 20),
                  const SizedBox(width: 8),
                  const Text('Live Activity & Email Alerts Feed',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${alerts.length} Records', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),

              if (alerts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('No attendance events logged yet today.',
                        style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _buildAlertItem(alerts[i]),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatusCard(Map<String, dynamic> student, String status, dynamic lastSeen) {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    if (status == 'INSIDE') {
      badgeColor = const Color(0xFF10B981);
      badgeIcon = Icons.check_circle_rounded;
      badgeText = 'INSIDE CLASSROOM (ACTIVE)';
    } else if (status == 'EARLY_QUIT') {
      badgeColor = Colors.redAccent;
      badgeIcon = Icons.warning_rounded;
      badgeText = '⚠️ LEFT EARLY (EARLY QUIT ALERT)';
    } else {
      badgeColor = const Color(0xFF64748B);
      badgeIcon = Icons.door_front_door_outlined;
      badgeText = 'OUTSIDE / DISMISSED';
    }

    final parentEmail = (student['parent_email'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF3B82F6),
                child: Text(
                  student['name'] != null && student['name'].toString().isNotEmpty
                      ? student['name'][0].toString().toUpperCase()
                      : 'S',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'] ?? 'Student',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Roll: ${student['roll_number']} • Section: ${student['class_section'] ?? 'A'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Big Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeColor),
            ),
            child: Row(
              children: [
                Icon(badgeIcon, color: badgeColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Parent details
          if (parentEmail.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.email_outlined, color: Colors.white54, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Alerts recipient email: $parentEmail',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ],
            ),
          if (lastSeen != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last activity registered: $lastSeen',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    final type = alert['alert_type'] ?? '';
    final isEarlyQuit = type == 'EARLY_QUIT';
    final isIn = type == 'STUDENT_IN';

    final color = isEarlyQuit
        ? Colors.redAccent
        : (isIn ? const Color(0xFF10B981) : const Color(0xFF64748B));

    final icon = isEarlyQuit
        ? Icons.warning_rounded
        : (isIn ? Icons.login_rounded : Icons.logout_rounded);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      alert['title'] ?? 'Attendance Alert',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (alert['email_sent'] == 1 || alert['email_sent'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mark_email_read_rounded, color: Color(0xFF10B981), size: 12),
                            SizedBox(width: 4),
                            Text('Email Sent', style: TextStyle(color: Color(0xFF10B981), fontSize: 10)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert['message'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  alert['created_at'] != null ? alert['created_at'].toString() : '',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
