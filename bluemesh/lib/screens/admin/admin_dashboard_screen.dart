import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../services/mysql_api_service.dart';
import '../../services/student_service.dart';
import '../../widgets/server_config_dialog.dart';
import '../auth/login_screen.dart';
import '../parent/parent_portal_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MySqlApiService _apiService = MySqlApiService.instance;
  final StudentService _studentService = StudentService();

  List<Map<String, dynamic>> _staffList = [];
  List<Map<String, dynamic>> _guardList = [];
  List<Student> _students = [];
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _zones = [];

  bool _isLoadingStaff = false;
  bool _isLoadingGuards = false;
  bool _isLoadingStudents = false;
  bool _isLoadingAlerts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    _loadStaff();
    _loadGuards();
    _loadStudents();
    _loadAlerts();
    _loadZones();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoadingStaff = true);
    try {
      final list = await _apiService.fetchStaffList();
      if (mounted) setState(() => _staffList = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingStaff = false);
  }

  Future<void> _loadGuards() async {
    setState(() => _isLoadingGuards = true);
    try {
      final list = await _apiService.fetchGuards();
      if (mounted) setState(() => _guardList = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingGuards = false);
  }

  Future<void> _loadZones() async {
    try {
      final list = await _apiService.fetchZones();
      if (mounted) setState(() => _zones = list);
    } catch (_) {}
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoadingStudents = true);
    try {
      final remote = await _apiService.fetchStudents();
      final local = await _studentService.getAllStudents();
      final Map<String, Student> map = {};
      for (final s in local) {
        map[s.rollNumber.toUpperCase()] = s;
      }
      for (final s in remote) {
        map[s.rollNumber.toUpperCase()] = s;
      }
      if (mounted) setState(() => _students = map.values.toList());
    } catch (_) {}
    if (mounted) setState(() => _isLoadingStudents = false);
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoadingAlerts = true);
    try {
      final list = await _apiService.fetchAlerts();
      if (mounted) setState(() => _alerts = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingAlerts = false);
  }

  // ==========================================
  // CREATE STAFF DIALOG (Admin capability)
  // ==========================================
  void _showCreateStaffDialog() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final deptCtrl = TextEditingController(text: 'Computer Science');
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: Color(0xFF38BDF8)),
            SizedBox(width: 10),
            Text('Create Staff Account', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create credentials for staff/faculty. Staff will log in with this username and password.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: userCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Staff Username *', Icons.account_circle_outlined),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter username' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Staff Password *', Icons.lock_outline),
                  validator: (v) => v == null || v.trim().length < 3 ? 'Min 3 chars' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Full Name * (e.g. Dr. Turing)', Icons.badge_outlined),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: deptCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Department', Icons.business_outlined),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Email (Optional)', Icons.email_outlined),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Phone (Optional)', Icons.phone_outlined),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await _apiService.createStaff(
                  username: userCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  name: nameCtrl.text.trim(),
                  department: deptCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadStaff();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Staff created in MySQL successfully!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('Create Staff', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CREATE GUARD DIALOG (Admin/Staff capability)
  // ==========================================
  void _showCreateGuardDialog() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedZone = 'ZONE-A';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.security_rounded, color: Colors.orangeAccent),
              SizedBox(width: 10),
              Text('Create Campus Guard', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Guard will log into the Band Application in Patrol Mode to track designated Explore Zones.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: userCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Guard Username * (e.g. guard1)', Icons.person_outline),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter username' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Guard Password *', Icons.lock_outline),
                    validator: (v) => v == null || v.trim().length < 3 ? 'Min 3 chars' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Officer Full Name *', Icons.badge_outlined),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Emergency Phone', Icons.phone_outlined),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedZone,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Assigned Explore Zone', Icons.explore_outlined),
                    items: const [
                      DropdownMenuItem(value: 'ZONE-A', child: Text('Zone A: Main Gate & Perimeter')),
                      DropdownMenuItem(value: 'ZONE-B', child: Text('Zone B: Academic Block & Labs')),
                      DropdownMenuItem(value: 'ZONE-C', child: Text('Zone C: Sports Complex & Food Court')),
                      DropdownMenuItem(value: 'ZONE-D', child: Text('Zone D: Student Hostels')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedZone = val);
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
                    _loadGuards();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Guard created in MySQL successfully!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              },
              child: const Text('Create Guard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
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
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: Colors.purpleAccent, size: 24),
            SizedBox(width: 8),
            Text('Admin Portal (admin/admin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Server IP / Hotspot Settings',
            icon: const Icon(Icons.wifi_tethering_rounded, color: Color(0xFF38BDF8)),
            onPressed: () => ServerConfigDialog.show(context),
          ),
          IconButton(
            tooltip: 'Parent Live Portal',
            icon: const Icon(Icons.family_restroom_rounded, color: Color(0xFF10B981)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentPortalScreen())),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purpleAccent,
          labelColor: Colors.purpleAccent,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.badge), text: 'Staff Accounts'),
            Tab(icon: Icon(Icons.security), text: 'Guards & Patrol'),
            Tab(icon: Icon(Icons.school), text: 'Students'),
            Tab(icon: Icon(Icons.notifications_active), text: 'Alerts & Early Quits'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStaffTab(),
          _buildGuardsTab(),
          _buildStudentsTab(),
          _buildAlertsTab(),
        ],
      ),
    );
  }

  // ── TAB 1: STAFF MANAGEMENT ──
  Widget _buildStaffTab() {
    return RefreshIndicator(
      onRefresh: _loadStaff,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Staff / Faculty Directory',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Total: ${_staffList.length} accounts in MySQL',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Add Staff', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: _showCreateStaffDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoadingStaff)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_staffList.isEmpty)
              _emptyCard('No staff members registered in MySQL. Click "Add Staff" above.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _staffList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final s = _staffList[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF3B82F6),
                          child: Text(
                            (s['name'] ?? 'S').toString().substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['name'] ?? 'Faculty',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('Username: ${s['username']} • Dept: ${s['department'] ?? 'CS'}',
                                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                              if ((s['email'] ?? '').toString().isNotEmpty)
                                Text(s['email'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          tooltip: 'Delete Staff',
                          onPressed: () async {
                            await _apiService.deleteStaff(s['id']);
                            _loadStaff();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── TAB 2: GUARDS & PATROL TRACKER ──
  Widget _buildGuardsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadGuards();
        await _loadZones();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Campus Guards & Patrol Zones',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${_guardList.length} Active Guards • ${_zones.length} Explore Zones',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                  icon: const Icon(Icons.add, size: 18, color: Colors.black),
                  label: const Text('Add Guard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  onPressed: _showCreateGuardDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Explore Zones overview
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Campus Explore Zones:',
                      style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _zones.map((z) => Chip(
                      backgroundColor: const Color(0xFF0F172A),
                      avatar: const Icon(Icons.place, color: Colors.orangeAccent, size: 16),
                      label: Text('${z['zone_code']}: ${z['name']}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoadingGuards)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_guardList.isEmpty)
              _emptyCard('No security guards registered. Click "Add Guard" above.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _guardList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final g = _guardList[i];
                  final status = (g['status'] ?? 'idle').toString();
                  final isWarning = status.contains('warning');

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isWarning ? Colors.redAccent : Colors.white10,
                        width: isWarning ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isWarning ? Colors.redAccent : Colors.orangeAccent,
                          child: Icon(Icons.shield, color: isWarning ? Colors.white : Colors.black),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g['name'] ?? 'Guard',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('Assigned: ${g['assigned_zone']} • Username: ${g['username']}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (isWarning ? Colors.redAccent : (status == 'patrolling' ? Colors.green : Colors.grey)).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: isWarning ? Colors.redAccent : (status == 'patrolling' ? Colors.greenAccent : Colors.grey),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── TAB 3: STUDENTS DIRECTORY ──
  Widget _buildStudentsTab() {
    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Student Roster (MySQL)',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${_students.length} registered students',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  icon: const Icon(Icons.family_restroom, size: 18, color: Colors.white),
                  label: const Text('Parent View', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentPortalScreen())),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoadingStudents)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_students.isEmpty)
              _emptyCard('No students in database.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _students.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final s = _students[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF3B82F6),
                        child: Text(s.rollNumber.length > 2 ? s.rollNumber.substring(0, 2) : 'ST',
                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      title: Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('Roll: ${s.rollNumber} • Section: ${s.classSection}',
                          style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new, color: Color(0xFF38BDF8), size: 20),
                        tooltip: 'View Parent Portal for this student',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ParentPortalScreen(initialRollNumber: s.rollNumber)),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── TAB 4: ALERTS & EARLY QUITS ──
  Widget _buildAlertsTab() {
    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Alerts & Security Events',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Student In/Out, Early Quits, and Guard Deviations',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadAlerts,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoadingAlerts)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_alerts.isEmpty)
              _emptyCard('No active alerts in MySQL database.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final a = _alerts[i];
                  final type = (a['alert_type'] ?? '').toString();
                  final isWarning = type == 'EARLY_QUIT' || type.contains('GUARD');
                  final color = isWarning ? Colors.redAccent : const Color(0xFF10B981);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(isWarning ? Icons.warning_rounded : Icons.check_circle_rounded, color: color, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a['title'] ?? 'Alert',
                                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(a['message'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(a['created_at'] != null ? a['created_at'].toString() : '',
                                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 13)),
      ),
    );
  }
}
